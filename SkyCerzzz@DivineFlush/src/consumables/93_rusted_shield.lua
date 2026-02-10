-- src/consumables/93_rusted_shield.lua
-- FULL COPY/PASTE
--
-- Rusted Shield:
--   Once per Blind:
--     - You may select 0 or 1 card.
--     - If you select 1 card: make it Rusted; if already Rusted => 50% Red Seal.
--     - If Zamazenta is present AND item not used: ALSO evolve -> Zamazenta Crowned
--       and transform into Crowned Shield (one-time), even if you selected a card.
--   Invalid selection (>1 highlighted) blocks ALL effects.
--
-- Crowned Shield:
--   Once per Blind: select up to 2 cards in hand:
--     - If NOT already Crowned: turn into Crowned
--     - If already Crowned: add Red Seal
--
-- Passive payout synergy is handled by DF_track_zamC_earned (called from Zamazenta Crowned).

DF = DF or {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------
local function DF_is_joker_highlighted_by_key(joker_key)
  if not (G and G.jokers and G.jokers.highlighted) then return false end
  for _, j in ipairs(G.jokers.highlighted) do
    if j and j.config and j.config.center and j.config.center.key == joker_key then
      return true
    end
  end
  return false
end

local function DF_find_first_joker_by_key(joker_key)
  if not (G and G.jokers and G.jokers.cards) then return nil end
  for _, j in ipairs(G.jokers.cards) do
    if j and j.config and j.config.center and j.config.center.key == joker_key then
      return j
    end
  end
  return nil
end

local function DF_set_consumable_center(consumable_card, new_center_key)
  if not (consumable_card and new_center_key) then return false end
  if not (G and G.P_CENTERS and G.P_CENTERS[new_center_key]) then return false end
  local new_center = G.P_CENTERS[new_center_key]
  consumable_card:set_ability(new_center, true)
  if consumable_card.set_cost then consumable_card:set_cost() end
  if consumable_card.juice_up then consumable_card:juice_up(0.4, 0.4) end
  return true
end

local function DF_destroy_consumable(card)
  if not card then return end
  card.ability = card.ability or {}
  card.ability.extra = card.ability.extra or {}
  if card.ability.extra._df_destroying then return end
  card.ability.extra._df_destroying = true

  if card.area and card.area.remove_card then
    pcall(function() card.area:remove_card(card) end)
  end
  if card.start_dissolve then
    pcall(function() card:start_dissolve() end)
  elseif card.remove then
    pcall(function() card:remove() end)
  end
end

local function DF_blind_id()
  if not (G and G.GAME and G.GAME.round_resets) then return nil end
  local rr = G.GAME.round_resets
  return tostring(rr.ante or 0) .. ":" .. tostring(rr.blind or 0)
end

local function DF_card_key(c)
  return c and c.config and c.config.center and c.config.center.key
end

----------------------------------------------------------------
-- Enhancement helpers (self-contained)
----------------------------------------------------------------
local function DF_has_enh(card, enh_key)
  if not (card and enh_key) then return false end
  if SMODS and SMODS.has_enhancement then
    return SMODS.has_enhancement(card, enh_key)
  end
  local ck = card.config and card.config.center and card.config.center.key
  return ck == enh_key
end

local function DF_set_enh(card, enh_key)
  if not (card and enh_key and G and G.P_CENTERS and G.P_CENTERS[enh_key]) then return false end
  if card.set_ability then
    card:set_ability(G.P_CENTERS[enh_key], nil, true)
    return true
  end
  return false
end

local function DF_set_red_seal(c)
  if not c then return end
  if c.set_seal then
    c:set_seal("Red", true)
  else
    c.seal = "Red"
  end
end

----------------------------------------------------------------
-- Rusted/Crowned enhancement keys
----------------------------------------------------------------
local RUSTED_CENTER_KEY  = "m_DF_rusted"
local CROWNED_CENTER_KEY = "m_DF_crowned"

local function DF_get_rusted_center_key()
  if G and G.P_CENTERS then
    if G.P_CENTERS[RUSTED_CENTER_KEY] then return RUSTED_CENTER_KEY end
    if G.P_CENTERS["m_rusted"] then return "m_rusted" end
  end
  return RUSTED_CENTER_KEY
end

local function DF_get_crowned_center_key()
  if G and G.P_CENTERS then
    if G.P_CENTERS[CROWNED_CENTER_KEY] then return CROWNED_CENTER_KEY end
    if G.P_CENTERS["m_crowned"] then return "m_crowned" end
  end
  return CROWNED_CENTER_KEY
end

----------------------------------------------------------------
-- Crowned Shield (held item)
----------------------------------------------------------------
local crowned_shield = {
  name = "crowned_shield",
  key = "crowned_shield",
  set = "Divine",
  helditem = true,
  saveable = true,

  atlas = "DFConsumables",
  pos = { x = 3, y = 1 },

  cost = 4,
  hidden = false,
  unlocked = true,
  discovered = true,

  config = { extra = { _df_last_blind_id = nil } },

  loc_vars = function(self, info_queue, card) return {} end,

  can_use = function(self, card)
    if not (G and G.hand) then return false end

    card.ability = card.ability or {}
    card.ability.extra = card.ability.extra or {}

    -- once per blind
    local bid = DF_blind_id()
    if bid and card.ability.extra._df_last_blind_id == bid then
      return false
    end

    -- select 1-2 cards (ANY cards are valid)
    local highlighted = (G.hand.highlighted or {})
    local n = #highlighted
    return (n >= 1 and n <= 2)
  end,

  keep_on_use = function(self, card) return true end,

  use = function(self, card)
    card.ability = card.ability or {}
    card.ability.extra = card.ability.extra or {}

    local highlighted = (G.hand and G.hand.highlighted) or {}
    if #highlighted < 1 or #highlighted > 2 then
      if card_eval_status_text then
        card_eval_status_text(card, 'extra', nil, nil, nil, { message = "Select 1-2 cards", colour = G.C.RED })
      end
      return
    end

    local bid = DF_blind_id()
    if bid then card.ability.extra._df_last_blind_id = bid end

    local crowned_ck = DF_get_crowned_center_key()
    if not (G and G.P_CENTERS and G.P_CENTERS[crowned_ck]) then
      if card_eval_status_text then
        card_eval_status_text(card, 'extra', nil, nil, nil, { message = "Missing Crowned key", colour = G.C.RED })
      end
      return
    end

    G.E_MANAGER:add_event(Event({
      trigger = 'immediate',
      func = function()
        for i = 1, math.min(2, #highlighted) do
          local c = highlighted[i]
          if c then
            local is_crowned = DF_has_enh(c, crowned_ck)

            if is_crowned then
              -- already Crowned -> Red Seal
              DF_set_red_seal(c)
              if card_eval_status_text then
                card_eval_status_text(c, 'extra', nil, nil, nil, { message = "Red Seal!", colour = G.C.RED })
              end
            else
              -- anything else -> Crowned
              local ok = DF_set_enh(c, crowned_ck)
              if card_eval_status_text then
                card_eval_status_text(c, 'extra', nil, nil, nil, { message = ok and "Crowned!" or "No Crowned!", colour = ok and G.C.GREEN or G.C.RED })
              end
            end

            if c.juice_up then c:juice_up(0.6, 0.6) end
          end
        end

        if card.juice_up then card:juice_up(0.6, 0.6) end
        return true
      end
    }))
  end,

  calculate = function(self, card, context)
    if not context then return end

    -- Selling/removing THIS item -> revert Zamazenta Crowned
    if (context.selling_card or context.removing_card or context.destroying_card) and context.card == card then
      local zc = DF_find_first_joker_by_key("j_DF_zamazenta_crowned")
      if zc then
        G.E_MANAGER:add_event(Event({
          trigger = 'immediate',
          func = function()
            if type(poke_backend_evolve) == "function" then
              poke_backend_evolve(zc, "j_DF_zamazenta")
            else
              if G.P_CENTERS and G.P_CENTERS["j_DF_zamazenta"] then
                zc:set_ability(G.P_CENTERS["j_DF_zamazenta"], true)
              end
            end
            if card_eval_status_text then
              card_eval_status_text(zc, 'extra', nil, nil, nil, { message = "Reverted!", colour = G.C.FILTER })
            end
            return true
          end
        }))
      end
      return
    end

    -- If Zamazenta Crowned is sold/removed/destroyed -> self-destruct
    if context.selling_card or context.removing_card or context.destroying_card then
      local k = DF_card_key(context.card)
      if k == "j_DF_zamazenta_crowned" then
        G.E_MANAGER:add_event(Event({
          trigger = 'immediate',
          func = function()
            if card_eval_status_text then
              card_eval_status_text(card, 'extra', nil, nil, nil, { message = "Bye! Bye!", colour = G.C.RED })
            end
            DF_destroy_consumable(card)
            return true
          end
        }))
      end
      return
    end

    -- Safety: if crowned zamazenta doesn't exist anymore, self-destruct
    if not DF_find_first_joker_by_key("j_DF_zamazenta_crowned") then
      DF_destroy_consumable(card)
    end
  end,

  in_pool = function(self) return false end,
}

----------------------------------------------------------------
-- Rusted Shield (usable): does BOTH effects in one use.
----------------------------------------------------------------
local rusted_shield = {
  name = "rusted_shield",
  key = "rusted_shield",
  set = "Divine",
  helditem = true,
  saveable = true,

  atlas = "DFConsumables",
  pos = { x = 3, y = 0 },
  soul_pos = { x = 4, y = 0 },

  cost = 4,
  hidden = true,
  soul_set = "Item",
  unlocked = true,
  discovered = true,

  config = { extra = { used = false, _df_last_blind_id = nil } },

  loc_vars = function(self, info_queue, card) return {} end,

    can_use = function(self, card)
    if not (G and G.hand and G.GAME) then return false end
    card.ability = card.ability or {}
    card.ability.extra = card.ability.extra or {}

    local bid = DF_blind_id()
    if bid and card.ability.extra._df_last_blind_id == bid then return false end

    local highlighted = (G.hand.highlighted or {})
    local n = #highlighted

    -- INVALID: too many highlighted => block ALL usage (including evolution)
    if n > 1 then return false end

    local target = DF_find_first_joker_by_key("j_DF_zamazenta")
    local joker_selected = DF_is_joker_highlighted_by_key("j_DF_zamazenta")
    local can_transform = target and joker_selected and (not card.ability.extra.used)

    -- 1 hand card => always allowed (card effect), transform only if joker_selected
    if n == 1 then return true end

    -- 0 hand cards => ONLY allow if we can transform (and joker is selected)
    return can_transform
  end,


  keep_on_use = function(self, card) return true end,

  use = function(self, card)
    card.ability = card.ability or {}
    card.ability.extra = card.ability.extra or {}

    local highlighted = (G.hand and G.hand.highlighted) or {}
    local n = #highlighted

    -- INVALID selection => block everything
    if n > 1 then
      if card_eval_status_text then
        card_eval_status_text(card, 'extra', nil, nil, nil, { message = "Select 0-1 card", colour = G.C.RED })
      end
      return
    end

    local bid = DF_blind_id()
    if bid then card.ability.extra._df_last_blind_id = bid end

    local rusted_ck  = DF_get_rusted_center_key()
    local crowned_ck = DF_get_crowned_center_key()

    local target_hand_card = (n == 1) and highlighted[1] or nil

    local target = DF_find_first_joker_by_key("j_DF_zamazenta")
    local joker_selected = DF_is_joker_highlighted_by_key("j_DF_zamazenta")
    local do_transform = target and joker_selected and (not card.ability.extra.used)


    G.E_MANAGER:add_event(Event({
      trigger = 'immediate',
      func = function()
        -- (A) Card effect
        if target_hand_card then
          local is_rusted  = rusted_ck and DF_has_enh(target_hand_card, rusted_ck)
          local is_crowned = crowned_ck and DF_has_enh(target_hand_card, crowned_ck)

          if (not is_rusted) and (not is_crowned) then
            local ok = DF_set_enh(target_hand_card, rusted_ck)
            if card_eval_status_text then
              card_eval_status_text(target_hand_card, 'extra', nil, nil, nil, { message = ok and "Rusted!" or "No Rusted!", colour = ok and G.C.GREEN or G.C.RED })
            end
          elseif is_rusted and (not is_crowned) then
            local success = (pseudorandom("DF_rusted_shield_seal") < 0.5)
            if success then DF_set_red_seal(target_hand_card) end
            if card_eval_status_text then
              card_eval_status_text(target_hand_card, 'extra', nil, nil, nil, { message = success and "Red Seal!" or "Nope!", colour = G.C.RED })
            end
          end

          if target_hand_card.juice_up then target_hand_card:juice_up(0.6, 0.6) end
        end

        -- (B) Zamazenta evolve + transform (one-time) — happens even if a card was selected
        if do_transform then
          card.ability.extra.used = true

          if type(poke_backend_evolve) == "function" then
            poke_backend_evolve(target, "j_DF_zamazenta_crowned")
          else
            if G.P_CENTERS and G.P_CENTERS["j_DF_zamazenta_crowned"] then
              target:set_ability(G.P_CENTERS["j_DF_zamazenta_crowned"], true)
            end
          end

          local ok = DF_set_consumable_center(card, "c_DF_crowned_shield")
          if card_eval_status_text then
            card_eval_status_text(card, 'extra', nil, nil, nil, { message = ok and "Crowned!" or "No crowned_shield!", colour = ok and G.C.GREEN or G.C.RED })
          end
        end

        if card.juice_up then card:juice_up(0.6, 0.6) end
        return true
      end
    }))
  end,

  calculate = function(self, card, context) return end,
  in_pool = function(self) return false end,
}

return {
  list = { rusted_shield, crowned_shield }
}
