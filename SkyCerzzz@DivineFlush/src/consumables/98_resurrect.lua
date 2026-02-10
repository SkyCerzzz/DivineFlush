-- src/consumables/??_resurrect.lua
-- Resurrect (PASSIVE):
-- - If you would lose a Blind:
--     - ALWAYS prevent loss (once per blind, if not on cooldown)
--     - If you have Calyrex (Shadow Rider): 30% divine item + start cooldown (3 played blinds)
--     - If you DON'T: still save, then shatter immediately (NO cooldown, NO reward)
-- - Cooldown ticks down ONLY after a played blind (skips do not count)

local DF = DF or {}

----------------------------------------------------------------
-- Divine item picker (your existing weighted list)
----------------------------------------------------------------
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

local function DF_consumables_full()
  if not (G and G.consumeables and G.consumeables.cards and G.consumeables.config) then
    return true
  end
  local lim = tonumber(G.consumeables.config.card_limit or 0) or 0
  return #G.consumeables.cards >= lim
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

-- respects consumable cap and shows message
local function DF_try_give_divine_item(src_card)
  if pseudorandom("df_resurrect_divine_item") >= 0.30 then return end

  if DF_consumables_full() then
    if card_eval_status_text and src_card and G and G.C then
      card_eval_status_text(src_card, 'extra', nil, nil, nil, {
        message = "Consumables full!",
        colour = G.C.RED
      })
    end
    return
  end

  local key = DF_pick_weighted_key("df_resurrect_item_roll")
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

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------
local function DF_has_shadow_rider()
  if not (G and G.jokers and G.jokers.cards) then return false end
  for _, j in ipairs(G.jokers.cards) do
    local k = j and j.config and j.config.center and j.config.center.key
    if k == "j_DF_calyrex_shadow" then
      return true
    end
  end
  return false
end

local function DF_blind_id()
  if not (G and G.GAME and G.GAME.round_resets) then return "0:0" end
  local rr = G.GAME.round_resets
  return tostring(rr.ante or 0) .. ":" .. tostring(rr.blind or 0)
end

local function DF_is_skip_context(context)
  if context and (context.skip_blind or context.skipping) then return true end
  if G and G.GAME and G.GAME.blind and (G.GAME.blind.skipped or G.GAME.blind.skip) then return true end
  if G and G.GAME and G.GAME.current_round and (G.GAME.current_round.skipped or G.GAME.current_round.skip) then return true end
  return false
end

local function DF_shatter_consumable(c)
  if not c then return end
  if card_eval_status_text then
    card_eval_status_text(c, 'extra', nil, nil, nil, { message = "Shattered!", colour = G.C.RED })
  end
  if c.start_dissolve then
    pcall(function() c:start_dissolve(nil, true) end)
    return
  end
  pcall(function()
    if c.remove_from_deck then c:remove_from_deck() end
    if c.area and c.area.remove_card then c.area:remove_card(c) end
    if c.remove then c:remove() end
  end)
end

----------------------------------------------------------------
-- Resurrect definition
----------------------------------------------------------------
local resurrect = {
  name = "resurrect",
  key = "resurrect",
  set = "Divine",
  helditem = true,
  saveable = true,

  atlas = "DF_AtlasConsumablesBasic",
  pos = { x = 0, y = 4 },
  soul_pos = { x = 4, y = 1 },

  cost = 4,
  hidden = true,
  soul_set = "Item",
  unlocked = true,
  discovered = true,

  config = { extra = { cooldown_blinds = 3 } },

  loc_vars = function(self, info_queue, card)
    card.ability = card.ability or {}
    card.ability.extra = card.ability.extra or {}
    local cd = tonumber(card.ability.extra.df_cd or 0) or 0
    local status = (cd <= 0) and "Ready" or "Cooldown"
    return { vars = { status, cd } }
  end,

  can_use = function(self, card) return false end,
  keep_on_use = function(self, card) return true end,

  calculate = function(self, card, context)
    if not context then return end

    card.ability = card.ability or {}
    card.ability.extra = card.ability.extra or {}

    ----------------------------------------------------------------
    -- 1) LOSS PREVENTION
    ----------------------------------------------------------------
    local would_lose = (context.game_over == true) and (context.end_of_round == true)

    if would_lose then
      local bid = DF_blind_id()

      -- once per blind guard
      if card.ability.extra.df_last_save_blind_id == bid then
        return
      end

      -- cooldown gate
      local cd = tonumber(card.ability.extra.df_cd or 0) or 0
      if cd > 0 then
        return -- lose normally
      end

      -- mark consumed for this blind
      card.ability.extra.df_last_save_blind_id = bid

      -- ALWAYS SAVE
      context.game_over = false
      context.cancelled = true
      context.prevented = true

      -- Shadow Rider bonus path
      if DF_has_shadow_rider() then
        card.ability.extra.df_cd = (self.config.extra.cooldown_blinds or 3)
        DF_try_give_divine_item(card)

        return {
          message = localize('k_saved_ex'),
          saved = "Saved by Resurrect",
          colour = G.C.RED
        }
      end

      -- NO Shadow Rider: still save, then shatter (no cooldown, no reward)
      G.E_MANAGER:add_event(Event({
        trigger = 'immediate',
        func = function()
          DF_shatter_consumable(card)
          return true
        end
      }))

      return {
        message = localize('k_saved_ex'),
        saved = "Saved by Resurrect",
        colour = G.C.RED
      }
    end

    ----------------------------------------------------------------
    -- 2) COOLDOWN TICK (only after played blind; skips don't count)
    ----------------------------------------------------------------
    if context.end_of_round and context.main_eval then
      if not DF_is_skip_context(context) then
        local cd = tonumber(card.ability.extra.df_cd or 0) or 0
        if cd > 0 then
          card.ability.extra.df_cd = cd - 1
        end
      end
    end
  end,

  in_pool = function(self) return false end,
}

return { list = { resurrect } }
