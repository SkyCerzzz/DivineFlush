-- src/consumables/97_blizzard.lua
local DF = DF or {}

-- ============================================================
-- Keys (YOUR mod)
-- ============================================================
local CALYREX_ICE_KEYS = { "j_DF_calyrex_ice" }

local function DF_consumables_full()
  if not (G and G.consumeables and G.consumeables.cards and G.consumeables.config) then
    return true
  end
  local lim = tonumber(G.consumeables.config.card_limit or 0) or 0
  return #G.consumeables.cards >= lim
end

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

  if c.area and c.area.remove_card then
    pcall(function() c.area:remove_card(c) end)
  end

  if c.start_dissolve then
    pcall(function() c:start_dissolve(nil, true) end)
  elseif c.remove then
    pcall(function() c:remove() end)
  end
end

-- ============================================================
-- Leaf-Stone style gate: only usable when a real hand is visible
-- ============================================================
local function DF_hand_visible()
  if not (G and G.hand and G.hand.cards) then return false end
  if not (G.STATE and G.STATES) then
    return #G.hand.cards > 0
  end

  local ok_states = {
    G.STATES.SELECTING_HAND,
    G.STATES.HAND_PLAY,
    G.STATES.DRAW_TO_HAND,
    G.STATES.ROUND,
  }

  for _, st in ipairs(ok_states) do
    if G.STATE == st then return true end
  end

  if G.GAME and G.GAME.blind and G.GAME.blind.chips then
    return (#G.hand.cards > 0)
  end

  return false
end

-- ============================================================
-- Skip detection (match Resurrect behavior)
-- ============================================================
local function DF_is_skip_context(context)
  if context and (context.skip_blind or context.skipping) then return true end
  if G and G.GAME and G.GAME.blind and (G.GAME.blind.skipped or G.GAME.blind.skip) then return true end
  if G and G.GAME and G.GAME.current_round and (G.GAME.current_round.skipped or G.GAME.current_round.skip) then return true end
  return false
end

-- ============================================================
-- Divine item roll helpers
-- ============================================================
local DIVINE_ITEM_WEIGHTS = {
  c_DF_rusted_sword      = 10,
  c_DF_rusted_shield     = 10,
  c_DF_prison_bottle     = 10,
  c_DF_reins_of_unity    = 10,

  c_DF_shaker_pokeball   = 10,
  c_DF_shaker_greatball  = 5,
  c_DF_shaker_ultraball  = 1,
  c_DF_shaker_masterball = 0.5,

  c_DF_divine_ball       = 0.1,
}

local DIVINE_ITEM_KEYS = {}
for k, _ in pairs(DIVINE_ITEM_WEIGHTS) do
  DIVINE_ITEM_KEYS[#DIVINE_ITEM_KEYS + 1] = k
end

local function DF_pick_weighted_key(seed)
  local candidates, weights = {}, {}
  for _, key in ipairs(DIVINE_ITEM_KEYS) do
    local w = DIVINE_ITEM_WEIGHTS[key] or 0
    if w > 0 and G.P_CENTERS and G.P_CENTERS[key] then
      candidates[#candidates + 1] = key
      weights[#weights + 1] = w
    end
  end
  if #candidates == 0 then return nil end

  local total = 0
  for i = 1, #weights do total = total + weights[i] end
  if total <= 0 then return nil end

  local r = pseudorandom(seed) * total
  local acc = 0
  for i = 1, #candidates do
    acc = acc + weights[i]
    if r <= acc then return candidates[i] end
  end
  return candidates[#candidates]
end

-- ✅ slot-capped divine item with message
local function DF_try_give_divine_item(src_card)
  if pseudorandom("df_blizzard_divine_item") >= 0.30 then return end

  if DF_consumables_full() then
    if card_eval_status_text and src_card and G and G.C then
      card_eval_status_text(src_card, 'extra', nil, nil, nil, {
        message = "Consumables full!",
        colour = G.C.RED
      })
    end
    return
  end

  local key = DF_pick_weighted_key("df_blizzard_item_roll")
  if not key then return end

  if DF_consumables_full() then
    if card_eval_status_text and src_card and G and G.C then
      card_eval_status_text(src_card, 'extra', nil, nil, nil, {
        message = "Consumables full!",
        colour = G.C.RED
      })
    end
    return
  end

  if SMODS and SMODS.add_card then
    SMODS.add_card({ key = key })
  end
end

local function DF_make_hand_cards_glass()
  if not (G and G.hand and G.hand.cards) then return end
  if not (G.P_CENTERS and G.P_CENTERS.m_glass) then return end

  for i, c in ipairs(G.hand.cards) do
    if pseudorandom("df_blizzard_glass_" .. tostring(i)) < 0.5 then
      if c.set_ability then
        c:set_ability(G.P_CENTERS.m_glass, nil, true)
      else
        c.ability = c.ability or {}
        c.ability.name = "Glass Card"
      end
      if c.juice_up then c:juice_up(0.3, 0.3) end
    end
  end
end

-- ============================================================
-- Blizzard
-- ============================================================
local blizzard = {
  name = "blizzard",
  key = "blizzard",
  set = "Divine",
  helditem = true,
  saveable = true,

  atlas = "DF_AtlasConsumablesBasic",
  pos = { x = 5, y = 3 },
  soul_pos = { x = 5, y = 1 },

  cost = 4,
  hidden = true,
  soul_set = "Item",
  unlocked = true,
  discovered = true,

  config = { extra = { cooldown = 3 } },

  loc_vars = function(self, info_queue, card)
    card.ability = card.ability or {}
    card.ability.extra = card.ability.extra or {}
    local ex = card.ability.extra

    local cd = tonumber(ex.df_cd or 0) or 0
    local status = (cd > 0) and "Cooldown" or "Ready"
    return { vars = { status, math.max(cd, 0) } }
  end,

  can_use = function(self, card)
    card.ability = card.ability or {}
    card.ability.extra = card.ability.extra or {}
    local cd_ok = (tonumber(card.ability.extra.df_cd or 0) or 0) <= 0
    return cd_ok and DF_hand_visible()
  end,

  keep_on_use = function(self, card) return true end,

  use = function(self, card)
    card.ability = card.ability or {}
    card.ability.extra = card.ability.extra or {}
    local ex = card.ability.extra

    -- ✅ Always apply glass effect first (even if this shatters)
    DF_make_hand_cards_glass()

    -- Check Calyrex Ice
    local ice = DF_find_first_joker_by_keys(CALYREX_ICE_KEYS)
    if not ice then
      -- ❌ No Ice: shatter, and DO NOT roll divine item, DO NOT set cooldown
      if card_eval_status_text then
        card_eval_status_text(card, 'extra', nil, nil, nil, { message = "No Calyrex (Ice)!", colour = G.C.RED })
      end
      DF_destroy_card_anywhere(card)
      return
    end

    -- ✅ Ice present: divine item + cooldown
    DF_try_give_divine_item(card)

    -- ✅ Start cooldown (3 played rounds)
    ex.df_cd = (self.config and self.config.extra and self.config.extra.cooldown) or 3
    -- ✅ Do not tick down on the same blind it was used in
    ex.df_cd_just_set = true

    if card_eval_status_text then
      card_eval_status_text(card, 'extra', nil, nil, nil, { message = "Blizzard!", colour = G.C.FILTER })
    end
  end,

  -- ✅ Cooldown tick: match Resurrect (only after played blind; skips don't count)
  calculate = function(self, card, context)
    if not context then return end
    if not (context.end_of_round and context.main_eval) then return end
    if DF_is_skip_context(context) then return end

    card.ability = card.ability or {}
    card.ability.extra = card.ability.extra or {}
    local ex = card.ability.extra

    local cd = tonumber(ex.df_cd or 0) or 0
    if cd > 0 then
      if ex.df_cd_just_set then
        -- first eligible tick after use: consume the flag, keep cd the same
        ex.df_cd_just_set = false
      else
        ex.df_cd = cd - 1
      end
    end
  end,

  in_pool = function(self) return false end,
}

return { list = { blizzard } }
