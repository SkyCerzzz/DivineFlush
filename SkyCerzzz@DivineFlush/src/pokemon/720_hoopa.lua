-- src/pokemon/720_hoopa.lua
-- Hoopa 720 + Hoopa Unbound
-- UPDATED: Hoopa Unbound X2 scaling counts BOTH Legendary + Divine jokers
--         Spawn chances scale with Legendary Deck/Sleeve (for BOTH Hoopa + Unbound)
--         Prints final chances for debugging

local DF = DF or {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------
local function DF_card_key(c)
  return c and c.config and c.config.center and c.config.center.key
end

local function DF_is_legendary_or_divine_joker(j)
  if not (j and j.config and j.config.center) then return false end
  local key = j.config.center.key
  local c = (G and G.P_CENTERS and key and G.P_CENTERS[key]) or j.config.center
  if not c then return false end

  -- Accept either stage OR rarity style tags
  if c.stage == "Legendary" or c.stage == "Divine" then return true end
  if c.rarity == 4 or c.rarity == "Legendary" then return true end
  if c.rarity == "DF_divine" or c.rarity == "Divine" then return true end

  return false
end

-- Legendary-only (used by base Hoopa sell trigger)
local function DF_is_legendary_joker(j)
  if not (j and j.config and j.config.center) then return false end
  local key = j.config.center.key
  local c = (G and G.P_CENTERS and key and G.P_CENTERS[key]) or j.config.center
  if not c then return false end

  if c.stage == "Legendary" then return true end
  if c.rarity == 4 or c.rarity == "Legendary" then return true end
  return false
end

local function DF_count_legendary_jokers()
  local count = 0
  if G and G.jokers and G.jokers.cards then
    for _, v in pairs(G.jokers.cards) do
      if DF_is_legendary_joker(v) then
        count = count + 1
      end
    end
  end
  return count
end

local function DF_count_legendary_or_divine_jokers()
  local count = 0
  if G and G.jokers and G.jokers.cards then
    for _, v in pairs(G.jokers.cards) do
      if DF_is_legendary_or_divine_joker(v) then
        count = count + 1
      end
    end
  end
  return count
end

-- Uses YOUR Legendary Shop deck/sleeve flags (preferred),
-- with fallbacks for other stacks.
local function DF_using_legendary_deck()
  if not (G and G.GAME) then return false end
  if G.GAME.modifiers and (G.GAME.modifiers.DF_has_leg_deck == true) then return true end
  if G.GAME.modifiers and (G.GAME.modifiers.DF_legendary_deck or G.GAME.modifiers.poke_legendary_deck) then return true end
  local sb = G.GAME.selected_back
  local s = tostring((sb and (sb.key or sb.name)) or "")
  return s:lower():find("legendary", 1, true) ~= nil
end

local function DF_using_legendary_sleeve()
  if not (G and G.GAME) then return false end
  if G.GAME.modifiers and (G.GAME.modifiers.DF_has_leg_sleeve == true) then return true end
  if G.GAME.modifiers and (G.GAME.modifiers.DF_legendary_sleeve or G.GAME.modifiers.poke_legendary_sleeve) then return true end
  local sl = G.GAME.selected_sleeve or (G.GAME.sleeve)
  local s = tostring((sl and (sl.key or sl.name)) or "")
  return s:lower():find("legendary", 1, true) ~= nil
end

-- Shared chance scaling (applies to BOTH Hoopa and Hoopa Unbound)
local function DF_chance_scaled(base_prob)
  local p = base_prob
  if DF_using_legendary_deck() then p = p * 1.25 end
  if DF_using_legendary_sleeve() then p = p * 1.25 end
  if p > 1 then p = 1 end
  return p
end

local function DF_jokers_full()
  if not (G and G.jokers and G.jokers.cards and G.jokers.config) then return false end
  return #G.jokers.cards >= (G.jokers.config.card_limit or 999)
end

local function DF_mark_sell_processed(sold_card)
  if not sold_card then return true end
  sold_card.ability = sold_card.ability or {}
  sold_card.ability.extra = sold_card.ability.extra or {}

  if sold_card.ability.extra._df_hoopa_sell_processed then
    return true
  end
  sold_card.ability.extra._df_hoopa_sell_processed = true
  return false
end

local function DF_round_id()
  if not (G and G.GAME and G.GAME.round_resets) then return "0:0" end
  local rr = G.GAME.round_resets
  return tostring(rr.ante or 0) .. ":" .. tostring(rr.blind or 0)
end

local function DF_hoopa_unbound_spawned_this_round()
  if not (G and G.GAME) then return false end
  G.GAME.DF = G.GAME.DF or {}
  return G.GAME.DF._df_hoopa_unbound_spawn_round_id == DF_round_id()
end

local function DF_mark_hoopa_unbound_spawned_this_round()
  if not (G and G.GAME) then return end
  G.GAME.DF = G.GAME.DF or {}
  G.GAME.DF._df_hoopa_unbound_spawn_round_id = DF_round_id()
end

local function DF_is_negative(card)
  return card and card.edition and card.edition.negative == true
end

local function DF_create_legendary_joker(source_card, reason_key)
  if not (G and G.jokers) then return end

  if type(poke_backend_create_random_legendary_joker) == "function" then
    return poke_backend_create_random_legendary_joker()
  end
  if type(poke_create_random_legendary_joker) == "function" then
    return poke_create_random_legendary_joker()
  end

  local ok, created = pcall(function()
    local j = create_card('Joker', G.jokers, nil, "Legendary", nil, nil, nil)
    if j then
      j:add_to_deck()
      G.jokers:emplace(j)
      if card_eval_status_text then
        card_eval_status_text(j, 'extra', nil, nil, nil, { message = "Legendary!", colour = G.C.FILTER })
      end
    end
    return j
  end)

  if not ok then
    if card_eval_status_text and source_card then
      card_eval_status_text(source_card, 'extra', nil, nil, nil, { message = "Couldn't spawn Legendary", colour = G.C.RED })
    end
    return nil
  end
  return created
end

----------------------------------------------------------------
-- Hoopa
-- X1.5 per Legendary Joker
-- Chance to create a Legendary Joker when a Legendary Joker is SOLD
-- Chance increases with Legendary Deck/Sleeve
----------------------------------------------------------------
local hoopa = {
  name = "hoopa",
  pos = { x = 0, y = 0 },

  config = { extra = { Xmult_multi = 1.5 } },

  loc_vars = function(self, info_queue, card)
    type_tooltip(self, info_queue, card)
    card = card or {}
    card.ability = card.ability or {}
    card.ability.extra = card.ability.extra or {}
    local per = tonumber(card.ability.extra.Xmult_multi or (self.config.extra.Xmult_multi)) or 1.5
    return { vars = { per, 50 } }
  end,

  rarity = 4,
  cost = 15,
  stage = "Legendary",
  ptype = "Psychic",
  gen = 6,
  blueprint_compat = false,
  unlocked = true,
  discovered = true,

  calculate = function(self, card, context)
    if not context then return end

    card.ability = card.ability or {}
    card.ability.extra = card.ability.extra or {}
    local per = tonumber(card.ability.extra.Xmult_multi or self.config.extra.Xmult_multi) or 1.5

    -- SELL PROC (SELL ONLY)
    if context.selling_card and context.card and context.card ~= card then
      local sold = context.card
      if DF_is_legendary_joker(sold) then
        if DF_mark_sell_processed(sold) then return end

        local base = DF_chance_scaled(0.5)

        -- PRINT: Hoopa sell chance after deck/sleeve scaling
        print("[HOOPA SELL CHANCE] Deck:", DF_using_legendary_deck(), "Sleeve:", DF_using_legendary_sleeve(), "Final:", base)

        local sold_was_negative = DF_is_negative(sold)

        G.E_MANAGER:add_event(Event({
          trigger = 'immediate',
          func = function()
            if sold_was_negative and (G and G.jokers and G.jokers.config)
              and (#G.jokers.cards >= (G.jokers.config.card_limit or 999))
            then
              if card_eval_status_text then
                card_eval_status_text(card, 'extra', nil, nil, nil, { message = "No space!", colour = G.C.RED })
              end
              return true
            end

            if pseudorandom("hoopa_spawn_legendary_on_sell") <= base then
              DF_create_legendary_joker(card, "hoopa_spawn_legendary_on_sell")
            end
            return true
          end
        }))
      end
      return
    end

    if context.selling_card then return end

    if context.card_added or context.removing_card or context.destroying_card then
      return
    end

    -- Chain: buff OTHER legendary jokers (unchanged)
    if context.other_joker and DF_is_legendary_joker(context.other_joker) then
      G.E_MANAGER:add_event(Event({
        func = function()
          context.other_joker:juice_up(0.5, 0.5)
          return true
        end
      }))

      return {
        message = localize{ type = 'variable', key = 'a_xmult', vars = { per } },
        colour = G.C.XMULT,
        Xmult_mod = per
      }
    end

    -- Apply stacked scaling when Hoopa itself resolves (Legendary count only)
    local count = DF_count_legendary_jokers()
    if context.card == card and count > 0 then
      return {
        message = localize{ type = 'variable', key = 'a_xmult', vars = { per } },
        colour = G.C.XMULT,
        Xmult_mod = (per ^ count)
      }
    end
  end,
}

----------------------------------------------------------------
-- Hoopa Unbound
-- X2 per Legendary+Divine Joker
-- Chance to create a Legendary Joker when Blind is defeated
-- Chance increases with Legendary Deck/Sleeve
-- If using both, Boss Blind spawn is guaranteed
----------------------------------------------------------------
local hoopa_unbound = {
  name = "hoopa_unbound",
  pos = { x = 10, y = 11 },
  soul_pos = { x = 11, y = 11 },

  config = { extra = { Xmult_multi = 2.0 } },

  loc_vars = function(self, info_queue, card)
    type_tooltip(self, info_queue, card)
    card = card or {}
    card.ability = card.ability or {}
    card.ability.extra = card.ability.extra or {}
    local per = tonumber(card.ability.extra.Xmult_multi or (self.config.extra.Xmult_multi)) or 2.0
    return { vars = { per, 25 } }
  end,

  rarity = "DF_divine",
  cost = 20,
  stage = "Divine",
  ptype = "Psychic",
  atlas = "DivineFlushAtlasGen6",
  gen = 6,
  blueprint_compat = false,
  unlocked = true,
  discovered = true,

  calculate = function(self, card, context)
    if not context then return end

    card.ability = card.ability or {}
    card.ability.extra = card.ability.extra or {}
    local per = tonumber(card.ability.extra.Xmult_multi or self.config.extra.Xmult_multi) or 2.0

    if context.card_added or context.selling_card or context.removing_card or context.destroying_card then
      return
    end

    -- Chain: give X to EACH Legendary+Divine joker evaluated
    if context.other_joker and DF_is_legendary_or_divine_joker(context.other_joker) then
      G.E_MANAGER:add_event(Event({
        func = function()
          context.other_joker:juice_up(0.5, 0.5)
          return true
        end
      }))

      return {
        message = localize{ type = 'variable', key = 'a_xmult', vars = { per } },
        colour = G.C.XMULT,
        Xmult_mod = per
      }
    end

    -- Apply stacked scaling when Unbound itself resolves (Legendary+Divine count)
    local count = DF_count_legendary_or_divine_jokers()
    if context.card == card and count > 0 then
      return {
        message = localize{ type = 'variable', key = 'a_xmult', vars = { per } },
        colour = G.C.XMULT,
        Xmult_mod = (per ^ count)
      }
    end

    -- Blind defeated: create EXACTLY ONE legendary (once per round)
    if context.end_of_round and context.main_eval then
      if DF_hoopa_unbound_spawned_this_round() then return end
      DF_mark_hoopa_unbound_spawned_this_round()

      if DF_jokers_full() then
        if card_eval_status_text then
          card_eval_status_text(card, 'extra', nil, nil, nil, { message = "Jokers full!", colour = G.C.RED })
        end
        return
      end

      local base = DF_chance_scaled(0.25)

      local both = DF_using_legendary_deck() and DF_using_legendary_sleeve()
      local is_boss = (G and G.GAME and G.GAME.blind and G.GAME.blind.boss) and true or false
      if both and is_boss then base = 1.0 end

      -- PRINT: Unbound blind-win chance after deck/sleeve scaling (+ boss override)
      print("[HOOPA UNBOUND BLIND CHANCE] Deck:", DF_using_legendary_deck(), "Sleeve:", DF_using_legendary_sleeve(), "Boss:", is_boss, "Final:", base)

      if base >= 1.0 or pseudorandom("hoopa_unbound_spawn_legendary_on_blind_win") <= base then
        G.E_MANAGER:add_event(Event({
          trigger = 'immediate',
          func = function()
            DF_create_legendary_joker(card, "hoopa_unbound_spawn_legendary_on_blind_win")
            return true
          end
        }))
      end
    end
  end,
}

return {
  config_key = "hoopa",
  list = { hoopa, hoopa_unbound }
}
