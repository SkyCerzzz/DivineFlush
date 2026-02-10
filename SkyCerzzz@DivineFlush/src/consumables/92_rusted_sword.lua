-- src/consumables/92_rusted_sword.lua
-- FULL COPY/PASTE
--
-- Rusted Sword:
--   Once per Blind:
--     - You may select 0 or 1 card.
--     - If you select 1 card: make it Rusted; if already Rusted => 50% Polychrome.
--     - Transform ONLY if Zacian Joker is highlighted AND item not used:
--         evolve Zacian -> Zacian Crowned and transform into Crowned Sword (one-time),
--         even if you selected a card.
--   Invalid selection (>1 highlighted) blocks ALL effects.
--
-- Crowned Sword:
--   Once per Blind: select 1-2 cards in hand:
--     - If NOT already Crowned: turn into Crowned (straight)
--     - If already Crowned: add Polychrome
--
-- Scaling:
--   This file now provides DF.try_scale_crowned_sword(), which should be called
--   from Zacian Crowned exactly when its crowned retrigger counter reaches 10 in a blind.
--   (Max 4 times per run, once per blind)

DF = DF or {}
local DF = DF

----------------------------------------------------------------
-- Shared tracker (for Crowned Sword scaling)
----------------------------------------------------------------
DF._retrigger_tracker = DF._retrigger_tracker or {}

local function DF_item_blind_id()
  if not (G and G.GAME and G.GAME.round_resets) then return "0:0" end
  local rr = G.GAME.round_resets
  return tostring(rr.ante or 0) .. ":" .. tostring(rr.blind or 0)
end

local function DF_item_reset_tracker_if_needed()
  local bid = DF_item_blind_id()
  if DF._retrigger_tracker._bid ~= bid then
    DF._retrigger_tracker._bid = bid
    DF._retrigger_tracker.crowned = 0
    DF._retrigger_tracker.rusted  = 0
  end
end

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------
local function DF_find_first_joker_by_key(joker_key)
  if not (G and G.jokers and G.jokers.cards) then return nil end
  for _, j in ipairs(G.jokers.cards) do
    if j and j.config and j.config.center and j.config.center.key == joker_key then
      return j
    end
  end
  return nil
end

local function DF_is_joker_highlighted_by_key(joker_key)
  if not (G and G.jokers and G.jokers.highlighted) then return false end
  for _, j in ipairs(G.jokers.highlighted) do
    if j and j.config and j.config.center and j.config.center.key == joker_key then
      return true
    end
  end
  return false
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

local function DF__blind_id()
  if not (G and G.GAME and G.GAME.round_resets) then return "0:0" end
  local rr = G.GAME.round_resets
  return tostring(rr.ante or 0) .. ":" .. tostring(rr.blind or 0)
end

local function DF_card_key(c)
  return c and c.config and c.config.center and c.config.center.key
end

----------------------------------------------------------------
-- Enhancement helpers (file-local)
----------------------------------------------------------------
local function DF__has_enhancement(c, enh_key)
  if not (c and enh_key) then return false end

  if SMODS and SMODS.has_enhancement then
    local ok = SMODS.has_enhancement(c, enh_key)
    if ok then return true end
    -- fall through
  end

  local k = c.config and c.config.center and c.config.center.key
  return k == enh_key
end

local function DF__set_enhancement(c, enh_key)
  if not (c and enh_key and G and G.P_CENTERS and G.P_CENTERS[enh_key]) then return false end
  if c.set_ability then
    c:set_ability(G.P_CENTERS[enh_key], nil, true)
    return true
  end
  return false
end

local function DF__rusted_center_key()
  if not (G and G.P_CENTERS) then return nil end
  if G.P_CENTERS["m_DF_rusted"] then return "m_DF_rusted" end
  if G.P_CENTERS["m_rusted"] then return "m_rusted" end
  return nil
end

local function DF__crowned_center_key()
  if not (G and G.P_CENTERS) then return nil end
  if G.P_CENTERS["m_DF_crowned"] then return "m_DF_crowned" end
  if G.P_CENTERS["m_crowned"] then return "m_crowned" end
  return nil
end

local function DF_is_rusted_card(c)
  local rk = DF__rusted_center_key()
  return rk and DF__has_enhancement(c, rk) or false
end

local function DF_apply_rusted(c)
  local rk = DF__rusted_center_key()
  return rk and DF__set_enhancement(c, rk) or false
end

local function DF_try_polychrome(c, seed)
  if not c or not c.set_edition then return false end
  if c.edition and c.edition.polychrome then return false end
  if pseudorandom(seed or "df_poly") < 0.5 then
    c:set_edition({ polychrome = true }, true)
    return true
  end
  return false
end

----------------------------------------------------------------
-- Scaling apply function (call this from Zacian Crowned when crowned retriggers reaches 10)
----------------------------------------------------------------
function DF.try_scale_crowned_sword()
  local card = DF._crowned_sword_ref
  if not card then return false end

  card.ability = card.ability or {}
  card.ability.extra = card.ability.extra or {}

  if type(card.ability.extra._df_scale_bonus) ~= "number" then
    card.ability.extra._df_scale_bonus = 0
  end
  if type(card.ability.extra._df_scale_steps_total) ~= "number" then
    card.ability.extra._df_scale_steps_total = 0
  end

  -- max 4 times per run
  if (card.ability.extra._df_scale_steps_total or 0) >= 4 then return false end

  -- once per blind
  local bid = DF_item_blind_id()
  if card.ability.extra._df_last_scale_blind_id ~= bid then
    card.ability.extra._df_last_scale_blind_id = bid
    card.ability.extra._df_scaled_this_blind = false
  end
  if card.ability.extra._df_scaled_this_blind then return false end

  card.ability.extra._df_scaled_this_blind = true
  card.ability.extra._df_scale_steps_total = card.ability.extra._df_scale_steps_total + 1
  card.ability.extra._df_scale_bonus = card.ability.extra._df_scale_bonus + 0.15

  DF._crowned_sword_bonus = card.ability.extra._df_scale_bonus

  local zc = DF_find_first_joker_by_key("j_DF_zacian_crowned")
  if zc then
    zc.ability = zc.ability or {}
    zc.ability.extra = zc.ability.extra or {}
    zc.ability.extra._df_item_scale_bonus = card.ability.extra._df_scale_bonus
  end

  if card_eval_status_text then
    card_eval_status_text(card, 'extra', nil, nil, nil, {
      message = "+0.15 Scaling!",
      colour = G.C.XMULT
    })
  end
  if card.juice_up then card:juice_up(0.6, 0.6) end

  return true
end

----------------------------------------------------------------
-- Crowned Sword (transformed item)
----------------------------------------------------------------
local crowned_sword = {
  name = "crowned_sword",
  key = "crowned_sword",
  set = "Divine",
  helditem = true,
  saveable = true,

  atlas = "DFConsumables",
  pos = { x = 1, y = 1 },
  soul_pos = { x = 2, y = 1 },

  cost = 4,
  hidden = false,
  unlocked = true,
  discovered = true,

  config = { extra = {} },

  loc_vars = function(self, info_queue, card) return {} end,

  can_use = function(self, card)
    if not (G and G.hand) then return false end
    card.ability = card.ability or {}
    card.ability.extra = card.ability.extra or {}

    local bid = DF__blind_id()
    if bid and card.ability.extra._df_last_blind_id == bid then
      return false
    end

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

    local bid = DF__blind_id()
    if bid then card.ability.extra._df_last_blind_id = bid end

    local ck = DF__crowned_center_key()
    if not ck then
      if card_eval_status_text then
        card_eval_status_text(card, 'extra', nil, nil, nil, { message = "Missing Crowned key", colour = G.C.RED })
      end
      return
    end

    G.E_MANAGER:add_event(Event({
      trigger = 'immediate',
      func = function()
        local count = math.min(2, #highlighted)
        for i = 1, count do
          local c = highlighted[i]
          if c then
            local is_c = DF__has_enhancement(c, ck)

            if is_c then
              -- already Crowned -> Polychrome (guaranteed)
              if not (c.edition and c.edition.polychrome) then
                c:set_edition({ polychrome = true }, true)
                if card_eval_status_text then
                  card_eval_status_text(c, 'extra', nil, nil, nil, {
                    message = "Polychrome!",
                    colour = G.C.GREEN
                  })
                end
              end
            else
              -- anything else -> Crowned (straight)
              local ok = DF__set_enhancement(c, ck)
              if card_eval_status_text then
                card_eval_status_text(c, 'extra', nil, nil, nil, {
                  message = ok and "Crowned!" or "No Crowned!",
                  colour = ok and G.C.GREEN or G.C.RED
                })
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

    -- keep reference so DF.try_scale_crowned_sword() knows which item to scale
    DF._crowned_sword_ref = card

    card.ability = card.ability or {}
    card.ability.extra = card.ability.extra or {}

    if type(card.ability.extra._df_scale_bonus) ~= "number" then
      card.ability.extra._df_scale_bonus = 0
    end
    if type(card.ability.extra._df_scale_steps_total) ~= "number" then
      card.ability.extra._df_scale_steps_total = 0
    end

    -- reset once-per-blind scaling flag
    local bid = DF_item_blind_id()
    if card.ability.extra._df_last_scale_blind_id ~= bid then
      card.ability.extra._df_last_scale_blind_id = bid
      card.ability.extra._df_scaled_this_blind = false
    end

    -- NOTE: scaling is NOT triggered here anymore.
    -- Zacian Crowned should call DF.try_scale_crowned_sword() when the crowned retrigger counter reaches 10.

    -- Selling/removing THIS item -> revert Zacian Crowned
    if (context.selling_card or context.removing_card or context.destroying_card) and context.card == card then
      local zc = DF_find_first_joker_by_key("j_DF_zacian_crowned")
      if zc then
        G.E_MANAGER:add_event(Event({
          trigger = 'immediate',
          func = function()
            if type(poke_backend_evolve) == "function" then
              poke_backend_evolve(zc, "j_DF_zacian")
            else
              if G.P_CENTERS and G.P_CENTERS["j_DF_zacian"] then
                zc:set_ability(G.P_CENTERS["j_DF_zacian"], true)
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

    -- If Zacian Crowned is sold/removed/destroyed -> self-destruct
    if context.selling_card or context.removing_card or context.destroying_card then
      local k = DF_card_key(context.card)
      if k == "j_DF_zacian_crowned" then
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
  end,

  in_pool = function(self) return false end,
}

----------------------------------------------------------------
-- Rusted Sword (consumable)
----------------------------------------------------------------
local rusted_sword = {
  name = "rusted_sword",
  key = "rusted_sword",
  set = "Divine",
  helditem = true,
  saveable = true,

  atlas = "DFConsumables",
  pos = { x = 1, y = 0 },
  soul_pos = { x = 2, y = 0 },

  cost = 4,
  hidden = true,
  soul_set = "Item",
  unlocked = true,
  discovered = true,

  config = { extra = { used = false, _df_last_blind_id = nil } },

  loc_vars = function(self, info_queue, card) return {} end,

  can_use = function(self, card)
    if not (G and G.GAME and G.hand) then return false end
    card.ability = card.ability or {}
    card.ability.extra = card.ability.extra or {}

    local bid = DF__blind_id()
    if bid and card.ability.extra._df_last_blind_id == bid then
      return false
    end

    local highlighted = (G.hand.highlighted or {})
    local n = #highlighted

    -- INVALID: too many highlighted => block ALL usage (including evolution)
    if n > 1 then return false end

    local target_zacian = DF_find_first_joker_by_key("j_DF_zacian")
    local joker_selected = DF_is_joker_highlighted_by_key("j_DF_zacian")
    local can_transform = target_zacian and joker_selected and (not card.ability.extra.used)

    -- 1 card => always allowed (card effect); transform only if joker highlighted
    if n == 1 then return true end

    -- 0 cards => ONLY allow if we can transform (and joker highlighted)
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

    local bid = DF__blind_id()
    if bid then card.ability.extra._df_last_blind_id = bid end

    local target_hand_card = (n == 1) and highlighted[1] or nil

    local target_zacian = DF_find_first_joker_by_key("j_DF_zacian")
    local joker_selected = DF_is_joker_highlighted_by_key("j_DF_zacian")
    local do_transform = target_zacian and joker_selected and (not card.ability.extra.used)

    -- If nothing selected and can't transform => nothing
    if (not target_hand_card) and (not do_transform) then
      if card_eval_status_text then
        card_eval_status_text(card, 'extra', nil, nil, nil, { message = "Nothing happens", colour = G.C.RED })
      end
      return
    end

    G.E_MANAGER:add_event(Event({
      trigger = 'immediate',
      func = function()
        -- (A) Card effect (ONLY if a playing card is selected)
        if target_hand_card then
          if DF_is_rusted_card(target_hand_card) then
            local ok = DF_try_polychrome(target_hand_card, "df_rusted_poly")
            if card_eval_status_text then
              card_eval_status_text(target_hand_card, 'extra', nil, nil, nil, { message = ok and "Polychrome!" or "Nope!", colour = ok and G.C.GREEN or G.C.RED })
            end
          else
            local ok = DF_apply_rusted(target_hand_card)
            if card_eval_status_text then
              card_eval_status_text(target_hand_card, 'extra', nil, nil, nil, { message = ok and "Rusted!" or "No Rusted!", colour = ok and G.C.GREEN or G.C.RED })
            end
          end
          if target_hand_card.juice_up then target_hand_card:juice_up(0.6, 0.6) end
        end

        -- (B) Evolve + transform (one-time) — ONLY if Zacian joker is highlighted
        if do_transform then
          card.ability.extra.used = true

          if type(poke_backend_evolve) == "function" then
            poke_backend_evolve(target_zacian, "j_DF_zacian_crowned")
          else
            if G.P_CENTERS and G.P_CENTERS["j_DF_zacian_crowned"] then
              target_zacian:set_ability(G.P_CENTERS["j_DF_zacian_crowned"], true)
            end
          end

          local ok = DF_set_consumable_center(card, "c_DF_crowned_sword")
          if card_eval_status_text then
            card_eval_status_text(card, 'extra', nil, nil, nil, { message = ok and "Crowned!" or "No crowned_sword!", colour = ok and G.C.GREEN or G.C.RED })
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
  list = { rusted_sword, crowned_sword }
}
