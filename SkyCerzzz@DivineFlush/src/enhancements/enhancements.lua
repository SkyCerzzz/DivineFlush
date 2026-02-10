-- Enhancements (Divine Flush)
-- Only: Rusted, Crowned

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------
local function DF_has_joker_key_exact(key)
  if not (G and G.jokers and G.jokers.cards) then return false end
  for _, j in ipairs(G.jokers.cards) do
    if j and not j.debuff then
      local k = j.config and j.config.center and j.config.center.key
      if k == key then return true end
    end
  end
  return false
end

local function DF_count_joker_key_exact(key)
  local n = 0
  if not (G and G.jokers and G.jokers.cards) then return 0 end
  for _, j in ipairs(G.jokers.cards) do
    if j and not j.debuff then
      local k = j.config and j.config.center and j.config.center.key
      if k == key then n = n + 1 end
    end
  end
  return n
end

local function DF_count_metal_jokers()
  local n = 0
  if not (G and G.jokers and G.jokers.cards) then return 0 end
  for _, j in ipairs(G.jokers.cards) do
    if j and not j.debuff then
      if is_type then
        local ok, res = pcall(is_type, j, "Metal")
        if ok and res then n = n + 1 end
      end
    end
  end
  return n
end

local function DF_count_legends_zac_zama()
  -- ✅ counts BOTH base + crowned forms
  local zac =
    DF_count_joker_key_exact("j_DF_zacian") +
    DF_count_joker_key_exact("j_DF_zacian_crowned")

  local zama =
    DF_count_joker_key_exact("j_DF_zamazenta") +
    DF_count_joker_key_exact("j_DF_zamazenta_crowned")

  return zac + zama
end

-- =========================
-- Crowned enhancement
-- =========================
local crowned = {
  key = "crowned",
  atlas = "DF_Enhancements",
  pos = { x = 1, y = 0 },

  config = {
    dollars_on_create = 3,
    xmult = 1.5
  },

  loc_vars = function(self, info_queue, center)
    return { vars = { self.config.dollars_on_create, self.config.xmult } }
  end,

  weight = 0,
  in_pool = function(self, args) return false end,

  on_create = function(self, card)
    local d = tonumber(self.config.dollars_on_create) or 0
    if d > 0 then
      ease_dollars(d)
      if card_eval_status_text then
        card_eval_status_text(card, 'extra', nil, nil, nil,
          { message = "+" .. tostring(d) .. "$", colour = G.C.MONEY })
      end
    end
  end,

  calculate = function(self, card, context)
    if not context then return end
    if context.repetition then return end

    local x = tonumber(self.config.xmult) or 1.5

    ----------------------------------------------------------------
    -- Held in hand during scoring (Steel-style)
    -- If Zamazenta (Crowned) exists, this card gives x1.5 while held
    ----------------------------------------------------------------
    if context.before and context.cardarea == G.hand and not context.blueprint then
      card.ability = card.ability or {}

      if DF_has_joker_key_exact("j_DF_zamazenta_crowned") then
        card.ability.h_x_mult = x
      else
        card.ability.h_x_mult = 1.0
      end
    end

    ----------------------------------------------------------------
    -- Scored in played hand
    -- If Zacian (Crowned) exists, this card gives x1.5 when scored
    ----------------------------------------------------------------
    if context.main_scoring and context.cardarea == G.play then
      if DF_has_joker_key_exact("j_DF_zacian_crowned") then
        return { x_mult = x }
      end
    end
  end,
}

-- =========================
-- Rusted enhancement (Steel-style: only while held in hand during scoring)
-- =========================
local rusted = {
  key = "rusted",
  atlas = "DF_Enhancements",
  pos = { x = 0, y = 0 },

  config = {
    h_x_mult = 1.0,     -- keep the "steel card property"
    per_metal = 0.10,   -- +0.1 per Metal Joker (=> x1.1 each)
    per_legend = 0.20,  -- +0.2 per Zacian/Zamazenta (=> x1.2 each)
  },

  calculate = function(self, card, context)
    if not context then return end
    if context.repetition then return end

    -- Default safety reset (prevents sticking if contexts stop firing)
    card.ability = card.ability or {}
    if card.ability.h_x_mult == nil then card.ability.h_x_mult = 1.0 end

    if context.before and context.cardarea == G.hand and not context.blueprint then
      local metal_count = DF_count_metal_jokers()

      -- ✅ THIS is the real fix: includes crowned forms too
      local legend_count = DF_count_legends_zac_zama()

      -- cumulative, not exponential
      local hx = 1.0
        + metal_count  * (tonumber(self.config.per_metal) or 0)
        + legend_count * (tonumber(self.config.per_legend) or 0)

      if hx < 1.0 then hx = 1.0 end
      card.ability.h_x_mult = hx
    end
  end,
}

return {
  name = "Enhancements",
  list = { rusted, crowned }
}
