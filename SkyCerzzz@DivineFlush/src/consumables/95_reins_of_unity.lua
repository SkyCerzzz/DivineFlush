-- src/consumables/??_reins_of_unity.lua
-- Reins of Unity: Combine Calyrex + (Glastrier or Spectrier) into Calyrex Ice / Calyrex Shadow
-- On use: item disappears
-- Ice: gives 2 Negative Ice Stones
-- Shadow: gives 2 Negative random Spectral consumables
-- IMPORTANT: does NOT pre-check consumable space (Negative should ignore limit)
-- IMPORTANT: destroys the mount joker (Glastrier/Spectrier) on fusion

local DF = DF or {}

----------------------------------------------------------------
-- Helpers (self-contained)
----------------------------------------------------------------
local function DF_find_first_joker_by_keys(keys)
  if not (G and G.jokers and G.jokers.cards) then return nil end
  for _, j in ipairs(G.jokers.cards) do
    local k = j and j.config and j.config.center and j.config.center.key
    if k then
      for _, want in ipairs(keys) do
        if k == want then return j end
      end
    end
  end
  return nil
end

local function DF_destroy_card_anywhere(c)
  if not c then return end
  c.ability = c.ability or {}
  c.ability.extra = c.ability.extra or {}
  if c.ability.extra._df_destroying then return end
  c.ability.extra._df_destroying = true

  -- Remove from area first if possible (jokers/hand/etc)
  if c.area and c.area.remove_card then
    pcall(function() c.area:remove_card(c) end)
  end

  -- Then dissolve/remove
  if c.start_dissolve then
    pcall(function() c:start_dissolve() end)
  elseif c.remove then
    pcall(function() c:remove() end)
  end
end

local function DF_evolve_joker(joker_card, to_center_key)
  if not joker_card then return end
  if type(poke_backend_evolve) == "function" then
    poke_backend_evolve(joker_card, to_center_key)
  else
    if G and G.P_CENTERS and G.P_CENTERS[to_center_key] and joker_card.set_ability then
      joker_card:set_ability(G.P_CENTERS[to_center_key], true)
    end
  end
end

-- Add a negative consumable WITHOUT pre-checking limit
local function DF_add_negative_item(center_key)
  if not (G and G.consumeables) then return nil end
  local c = create_card('Item', G.consumeables, nil, nil, nil, nil, center_key)
  if not c then return nil end
  c:set_edition({ negative = true }, true)
  c:add_to_deck()
  -- emplace can still fail in some environments; we attempt and ignore errors
  pcall(function() G.consumeables:emplace(c) end)
  return c
end

-- Best-effort: create a negative random Spectral consumable (no limit checks)
local function DF_add_negative_random_spectral()
  if not (G and G.consumeables) then return nil end

  -- Prefer a backend helper if your environment provides one
  if type(poke_backend_create_random_spectral) == "function" then
    local c = poke_backend_create_random_spectral()
    if c and c.set_edition then c:set_edition({ negative = true }, true) end
    return c
  end

  -- Try create_card('Spectral'...) if supported
  local ok, created = pcall(function()
    local c = create_card('Spectral', G.consumeables, nil, nil, nil, nil, nil)
    if c then
      c:set_edition({ negative = true }, true)
      c:add_to_deck()
      pcall(function() G.consumeables:emplace(c) end)
    end
    return c
  end)
  if ok and created then return created end

  -- Final fallback list (edit if your spectral keys differ)
  local spectral_keys = { "c_soul", "c_cryptid", "c_ectoplasm", "c_immolate", "c_ouija", "c_wraith" }
  local key = spectral_keys[math.floor(pseudorandom('reins_spectral') * #spectral_keys) + 1]
  local c = create_card('Spectral', G.consumeables, nil, nil, nil, nil, key)
  if c then
    c:set_edition({ negative = true }, true)
    c:add_to_deck()
    pcall(function() G.consumeables:emplace(c) end)
  end
  return c
end

----------------------------------------------------------------
-- Key lists (expand if your pack uses different names)
----------------------------------------------------------------
local CALYREX_KEYS   = { "j_DF_calyrex", "j_poke_calyrex", "j_calyrex" }
local GLASTRIER_KEYS = { "j_DF_glastrier", "j_poke_glastrier", "j_glastrier" }
local SPECTRIER_KEYS = { "j_DF_spectrier", "j_poke_spectrier", "j_spectrier" }

-- Your fused forms
local CALYREX_ICE_KEY    = "j_DF_calyrex_ice"
local CALYREX_SHADOW_KEY = "j_DF_calyrex_shadow"

----------------------------------------------------------------
-- Reins of Unity
----------------------------------------------------------------
local reins_of_unity = {
  name = "reins_of_unity",
  key = "reins_of_unity",
  set = "Divine",
  helditem = true,
  saveable = true,

  atlas = "DFConsumables",
  pos = { x = 0, y = 2 },
  soul_pos = { x = 1, y = 2 },

  cost = 4,
  hidden = true,
  soul_set = "Item",
  unlocked = true,
  discovered = true,

  config = { extra = {} },

  loc_vars = function(self, info_queue, card)
    return { vars = {} }
  end,

  can_use = function(self, card)
    local cal = DF_find_first_joker_by_keys(CALYREX_KEYS)
    if not cal then return false end
    local gla = DF_find_first_joker_by_keys(GLASTRIER_KEYS)
    local spe = DF_find_first_joker_by_keys(SPECTRIER_KEYS)
    return (gla ~= nil) or (spe ~= nil)
  end,

  keep_on_use = function(self, card)
    -- item disappears on use
    return false
  end,

  use = function(self, card)
    local cal = DF_find_first_joker_by_keys(CALYREX_KEYS)
    local gla = DF_find_first_joker_by_keys(GLASTRIER_KEYS)
    local spe = DF_find_first_joker_by_keys(SPECTRIER_KEYS)

    if not cal then
      if card_eval_status_text then
        card_eval_status_text(card, 'extra', nil, nil, nil, { message = "No Calyrex", colour = G.C.RED })
      end
      return
    end

    if not (gla or spe) then
      if card_eval_status_text then
        card_eval_status_text(card, 'extra', nil, nil, nil, { message = "No mount", colour = G.C.RED })
      end
      return
    end

    -- If both exist, default to Ice (Glastrier). Change priority if you want.
    local mode = gla and "ice" or "shadow"

    G.E_MANAGER:add_event(Event({
      trigger = 'immediate',
      func = function()
        if mode == "ice" then
          -- Fuse: Calyrex becomes Calyrex Ice, mount is consumed
          DF_evolve_joker(cal, CALYREX_ICE_KEY)
          DF_destroy_card_anywhere(gla)

          if cal.juice_up then cal:juice_up(0.6, 0.6) end

          -- Reward: 2 Negative Ice Stones (no space checks)
          DF_add_negative_item("c_poke_icestone")
          DF_add_negative_item("c_poke_icestone")

          if card_eval_status_text then
            card_eval_status_text(card, 'extra', nil, nil, nil, { message = "United (Ice)!", colour = G.C.GREEN })
          end
        else
          -- Fuse: Calyrex becomes Calyrex Shadow, mount is consumed
          DF_evolve_joker(cal, CALYREX_SHADOW_KEY)
          DF_destroy_card_anywhere(spe)

          if cal.juice_up then cal:juice_up(0.6, 0.6) end

          -- Reward: 2 Negative Spectral (no space checks)
          DF_add_negative_random_spectral()
          DF_add_negative_random_spectral()

          if card_eval_status_text then
            card_eval_status_text(card, 'extra', nil, nil, nil, { message = "United (Shadow)!", colour = G.C.GREEN })
          end
        end

        -- Consume the item itself
        DF_destroy_card_anywhere(card)
        return true
      end
    }))
  end,

  calculate = function(self, card, context)
    return
  end,

  in_pool = function(self)
    return false
  end,
}

return {
  list = { reins_of_unity }
}