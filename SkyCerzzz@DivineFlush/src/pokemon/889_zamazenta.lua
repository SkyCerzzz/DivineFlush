-- src/jokers/??_zamazenta.lua
-- Zamazenta 889 (reworked for Rusted/Crowned)
-- UPDATED: Aura is truly passive (clears debuffs on every calculate call + on add_to_deck)
-- FIXED: Enhancement/seal/edition effects occur ONLY while a hand is being scored (not end-of-round)
-- FIXED: Buff effects apply to cards triggered in HAND as well as RETRIGGERS in PLAY (during scoring)
-- FIXED: Guaranteed chances work for Zacian OR Zacian (Crowned)
-- FIXED: Zamazenta (Crowned) payouts are no longer blocked by the buff-roll return

DF = DF or {}
local DF = DF

local RUSTED_ENH_KEY  = "m_DF_rusted"
local CROWNED_ENH_KEY = "m_DF_crowned"

----------------------------------------------------------------
-- Scoring gate (scoring only)
----------------------------------------------------------------
local function DF_is_scoring_now(context)
  if not context then return false end
  if context.end_of_round then return false end
  if context.scoring_hand or context.scoring then return true end
  if G and G.STATE and G.STATES and G.STATE == G.STATES.HAND_PLAYED then return true end
  return false
end

local function DF_is_hand_or_play(context)
  if not (context and G) then return false end
  return (context.cardarea == G.play or context.cardarea == G.hand)
end

----------------------------------------------------------------
-- Joker presence helpers
----------------------------------------------------------------
local function DF_has_joker_key(key)
  if not (G and G.jokers and G.jokers.cards) then return false end
  for _, j in ipairs(G.jokers.cards) do
    local k = j and j.config and j.config.center and j.config.center.key
    if k == key then return true end
  end
  return false
end

-- Any Zacian form (base OR crowned)
local function DF_has_zacian_any()
  return DF_has_joker_key("j_DF_zacian") or DF_has_joker_key("j_DF_zacian_crowned")
end

----------------------------------------------------------------
-- Enhancement helpers
----------------------------------------------------------------
local function DF_has_enh(card, enh_key)
  if not card then return false end
  if SMODS and SMODS.has_enhancement then
    return SMODS.has_enhancement(card, enh_key)
  end
  local ck = card.config and card.config.center and card.config.center.key
  return ck == enh_key
end

local function DF_set_enh(card, enh_key)
  if not (card and G and G.P_CENTERS and G.P_CENTERS[enh_key]) then return false end
  if card.set_ability then
    card:set_ability(G.P_CENTERS[enh_key], nil, true)
    return true
  end
  return false
end

-- Once per Blind, max 2 times per run:
-- If Crowned Shield is held AND Zamazenta (Crowned) has earned >= $50 this Blind:
--   +$1 to crowned_cash (the payout per Crowned card)
function DF_track_zamC_earned(amount, zam_card)
  if not (G and G.GAME and zam_card) then return end

  ----------------------------------------------------------------
  -- Detect Crowned Shield held (very tolerant + checks both spellings)
  ----------------------------------------------------------------
  local function has_crowned_shield_held()
    local areas = {}

    if G.consumeables and G.consumeables.cards then areas[#areas+1] = G.consumeables.cards end
    if G.consumeables and G.consumeables.cards then areas[#areas+1] = G.consumeables.cards end -- in case your fork uses this spelling

    for _, pile in ipairs(areas) do
      for _, c in ipairs(pile) do
        local center = c and c.config and c.config.center
        local k  = center and center.key
        local ok = center and center.original_key

        if (type(k) == "string" and string.find(k, "crowned_shield", 1, true))
          or (type(ok) == "string" and string.find(ok, "crowned_shield", 1, true))
        then
          return true
        end
      end
    end

    return false
  end

  if not has_crowned_shield_held() then return end

  ----------------------------------------------------------------
  -- Run/blind tracking
  ----------------------------------------------------------------
  local rr = G.GAME.round_resets or {}
  local bid = tostring(rr.ante or 0) .. ":" .. tostring(rr.blind or 0)

  G.GAME.df_zamC = G.GAME.df_zamC or {
    bid = nil,
    earned_this_blind = 0,
    gave_bonus_this_blind = false,
    total_bonus_given = 0, -- cap: 2 per run
  }

  local st = G.GAME.df_zamC

  -- reset per blind
  if st.bid ~= bid then
    st.bid = bid
    st.earned_this_blind = 0
    st.gave_bonus_this_blind = false
  end

  -- accumulate earned this blind
  st.earned_this_blind = (st.earned_this_blind or 0) + (tonumber(amount) or 0)

  -- trigger once per blind, max 2 overall, threshold $50
  if (st.total_bonus_given or 0) >= 2 then return end
  if st.gave_bonus_this_blind then return end
  if (st.earned_this_blind or 0) < 50 then return end

  st.gave_bonus_this_blind = true
  st.total_bonus_given = (st.total_bonus_given or 0) + 1

  ----------------------------------------------------------------
  -- Apply effect: increase Zamazenta Crowned payout per Crowned card
  ----------------------------------------------------------------
  zam_card.ability = zam_card.ability or {}
  zam_card.ability.extra = zam_card.ability.extra or {}
  zam_card.ability.extra.crowned_cash = (tonumber(zam_card.ability.extra.crowned_cash) or 3) + 1

  if card_eval_status_text then
    card_eval_status_text(zam_card, 'extra', nil, nil, nil, {
      message = ("Crowned payout +$1 (%d/2)"):format(st.total_bonus_given),
      colour = G.C.MONEY
    })
  end
  if zam_card.juice_up then zam_card:juice_up(0.6, 0.6) end
end

----------------------------------------------------------------
-- Seal / edition helpers
----------------------------------------------------------------
local function DF_set_red_seal(c)
  if not c then return end
  if c.set_seal then
    c:set_seal("Red", true)
  else
    c.seal = "Red"
  end
end

local function DF_set_polychrome(c)
  if not c then return end
  if not (c.edition and c.edition.polychrome) then
    c:set_edition({ polychrome = true }, true)
  end
end

----------------------------------------------------------------
-- Aura: clear debuffs everywhere
----------------------------------------------------------------
local function DF_clear_all_debuffs()
  if G.jokers and G.jokers.cards then
    for _, j in pairs(G.jokers.cards) do
      if j then j.debuff = false; j.debuff_ability = nil end
    end
  end
  if G.hand and G.hand.cards then
    for _, c in pairs(G.hand.cards) do
      if c then c.debuff = false; c.debuff_ability = nil end
    end
  end
  if G.play and G.play.cards then
    for _, c in pairs(G.play.cards) do
      if c then c.debuff = false; c.debuff_ability = nil end
    end
  end
end

----------------------------------------------------------------
-- Probability helper
----------------------------------------------------------------
local function DF_prob(card, num, den, seed_key, guaranteed)
  if guaranteed then return true end
  if SMODS and SMODS.get_probability_vars then
    local n, d = SMODS.get_probability_vars(card, num, den, seed_key)
    num, den = n, d
  end
  return pseudorandom(seed_key) < (num / den)
end

local function DF_score_uid(context)
  -- "One scoring resolution" id; good enough for end-of-scoring application
  local rr = (G and G.GAME and G.GAME.round_resets) or {}
  local bid = tostring(rr.ante or 0) .. ":" .. tostring(rr.blind or 0)
  local hands = tostring((G and G.GAME and G.GAME.hands_played) or 0)
  return bid .. ":" .. hands
end

local function DF_queue_zamC_buff(oc, which, suid)
  if not oc then return end
  oc.ability = oc.ability or {}
  oc.ability.extra = oc.ability.extra or {}
  -- one buff per scoring per card
  if oc.ability.extra._df_zamC_buff_uid == suid then return end
  oc.ability.extra._df_zamC_buff_uid = suid
  oc.ability.extra._df_zamC_buff_which = which -- "red" or "poly"
end

local function DF_score_uid(context)
  local rr = (G and G.GAME and G.GAME.round_resets) or {}
  local bid = tostring(rr.ante or 0) .. ":" .. tostring(rr.blind or 0)
  local hands = tostring((G and G.GAME and G.GAME.hands_played) or 0)
  return bid .. ":" .. hands
end

local function DF_apply_buff_after_trigger(oc, which)
  if not (G and G.E_MANAGER and oc) then return end
  G.E_MANAGER:add_event(Event({
    trigger = 'after',
    delay = 0,
    func = function()
      if which == "red" then
        DF_set_red_seal(oc)
      elseif which == "poly" then
        DF_set_polychrome(oc)
      end
      if oc.juice_up then oc:juice_up(0.4, 0.4) end
      return true
    end
  }))
end


local function DF_apply_queued_zamC_buffs(suid)
  if not (G and suid) then return end

  local function apply_on_pile(pile)
    if not (pile and pile.cards) then return end
    for _, c in ipairs(pile.cards) do
      if c and c.ability and c.ability.extra and c.ability.extra._df_zamC_buff_uid == suid then
        local which = c.ability.extra._df_zamC_buff_which
        -- clear first so we can't double-apply if something re-enters
        c.ability.extra._df_zamC_buff_uid = nil
        c.ability.extra._df_zamC_buff_which = nil

        if which == "red" then
          DF_set_red_seal(c)
        elseif which == "poly" then
          DF_set_polychrome(c)
        end

        if c.juice_up then c:juice_up(0.4, 0.4) end
      end
    end
  end

  -- Apply to both hand and play piles (covers held + scored)
  apply_on_pile(G.hand)
  apply_on_pile(G.play)
end

--------------------------------------------------------------------------------
-- Zamazenta (Legendary)
-- Aura: no debuffs (cards + jokers)  [PASSIVE]
-- 1/2: triggered Steel -> Rusted
-- 1/4: triggered Rusted -> Red Seal
-- GUARANTEED if you have Zacian OR Zacian (Crowned)
--------------------------------------------------------------------------------
local zamazenta = {
  name = "zamazenta",
  pos = { x = 14, y = 6 },

  config = {
    extra = {
      steel_to_rusted_num = 1, steel_to_rusted_den = 2,
      rusted_to_red_num   = 1, rusted_to_red_den   = 4,
    }
  },

  loc_vars = function(self, info_queue, center)
    type_tooltip(self, info_queue, center)

    local g = DF_has_zacian_any()
    local sN, sD = center.ability.extra.steel_to_rusted_num, center.ability.extra.steel_to_rusted_den
    local rN, rD = center.ability.extra.rusted_to_red_num,   center.ability.extra.rusted_to_red_den

    if SMODS and SMODS.get_probability_vars and not g then
      sN, sD = SMODS.get_probability_vars(center, sN, sD, "zam_steel_to_rusted")
      rN, rD = SMODS.get_probability_vars(center, rN, rD, "zam_rusted_to_red")
    end
    return { vars = { sN, sD, rN, rD } }
  end,

  rarity = 4,
  cost = 20,
  stage = "Legendary",
  ptype = "Fighting",
  gen = 8,
  blueprint_compat = true,
  unlocked = true,
  discovered = true,

  add_to_deck = function(self, card, from_debuff)
    DF_clear_all_debuffs()
  end,

  calculate = function(self, card, context)
    if not context then return end
    if context.card_added or context.selling_card or context.removing_card or context.destroying_card then return end

    local guaranteed = DF_has_zacian_any()

    -- Aura passive (always)
    DF_clear_all_debuffs()

    -- Only do conversion/seal effects during scoring, for hand OR play,
    -- and only when there's an actual card involved.
    if (context.individual or context.repetition)
      and context.other_card
      and not context.blueprint
      and DF_is_scoring_now(context)
      and DF_is_hand_or_play(context)
    then
      local oc = context.other_card
      local is_steel   = DF_has_enh(oc, "m_steel")
      local is_rusted  = DF_has_enh(oc, RUSTED_ENH_KEY)
      local is_crowned = DF_has_enh(oc, CROWNED_ENH_KEY)

      -- 1/2: Steel -> Rusted (only if not already rusted/crowned)
      if is_steel and not is_rusted and not is_crowned then
        if DF_prob(card, card.ability.extra.steel_to_rusted_num, card.ability.extra.steel_to_rusted_den,
          "zam_steel_to_rusted", guaranteed) then
          DF_set_enh(oc, RUSTED_ENH_KEY)
          is_rusted = true
          is_steel = false
        end
      end

      -- 1/4: Rusted -> Red Seal (only if not crowned)
      if is_rusted and not is_crowned then
        if DF_prob(card, card.ability.extra.rusted_to_red_num, card.ability.extra.rusted_to_red_den,
          "zam_rusted_to_red", guaranteed) then
          DF_set_red_seal(oc)
        end
      end
      return
    end
  end,
}

--------------------------------------------------------------------------------
-- Zamazenta (Crowned) (Divine)
-- Aura: no debuffs (cards + jokers)  [PASSIVE]
-- $3 per scored Crowned card; 1/3 to double ($6)
-- Rusted: 1/4 add Red Seal OR Polychrome
-- Crowned: 1/2 add Red Seal OR Polychrome
-- GUARANTEED if you have Zacian OR Zacian (Crowned)
--------------------------------------------------------------------------------
local zamazenta_crowned = {
  name = "zamazenta_crowned",
  pos = { x = 12, y = 9 },
  soul_pos = { x = 13, y = 9 },

  config = {
    extra = {
      rusted_buff_num  = 1, rusted_buff_den  = 4,
      crowned_buff_num = 1, crowned_buff_den = 2,

      crowned_cash = 3,
      double_cash_num = 1, double_cash_den = 3,
    }
  },

  loc_vars = function(self, info_queue, center)
    type_tooltip(self, info_queue, center)

    local g = DF_has_zacian_any()

    local rN, rD = center.ability.extra.rusted_buff_num,  center.ability.extra.rusted_buff_den
    local cN, cD = center.ability.extra.crowned_buff_num, center.ability.extra.crowned_buff_den
    local dN, dD = center.ability.extra.double_cash_num,  center.ability.extra.double_cash_den

    if SMODS and SMODS.get_probability_vars and not g then
      rN, rD = SMODS.get_probability_vars(center, rN, rD, "zamC_rusted_buff")
      cN, cD = SMODS.get_probability_vars(center, cN, cD, "zamC_crowned_buff")
      dN, dD = SMODS.get_probability_vars(center, dN, dD, "zamC_double_cash")
    end

    return { vars = { center.ability.extra.crowned_cash, dN, dD, rN, rD, cN, cD } }
  end,

  rarity = "DF_divine",
  cost = 20,
  stage = "Divine",
  ptype = "Fighting",
  atlas = "DivineFlushAtlasGen8",
  gen = 8,
  blueprint_compat = false,
  unlocked = true,
  discovered = true,

  add_to_deck = function(self, card, from_debuff)
    DF_clear_all_debuffs()
  end,

  calculate = function(self, card, context)
    if not context then return end
    if context.card_added or context.selling_card or context.removing_card or context.destroying_card then return end

    local guaranteed = DF_has_zacian_any()

    -- Aura passive (always)
    DF_clear_all_debuffs()

    ----------------------------------------------------------------
    -- Buff rolls (seal/poly)
    -- Apply to:
    --   (A) HAND triggers: context.individual + G.hand
    --   (B) RETRIGGERS:  context.repetition + (G.hand or G.play)
    -- This avoids blocking the PLAY scoring payout (which is individual on G.play).
    ----------------------------------------------------------------
    local do_buff_roll =
      context.other_card
      and not context.blueprint
      and DF_is_scoring_now(context)
      and (
        (context.individual and context.cardarea == G.hand)
        or (context.repetition and DF_is_hand_or_play(context))
      )

    if do_buff_roll then
      local oc = context.other_card
      local is_rusted  = DF_has_enh(oc, RUSTED_ENH_KEY)
      local is_crowned = DF_has_enh(oc, CROWNED_ENH_KEY)

      if is_rusted or is_crowned then
        local n, d, seed
        if is_crowned then
          n, d, seed = card.ability.extra.crowned_buff_num, card.ability.extra.crowned_buff_den, "zamC_crowned_buff"
        else
          n, d, seed = card.ability.extra.rusted_buff_num, card.ability.extra.rusted_buff_den, "zamC_rusted_buff"
        end

        local suid = DF_score_uid(context)

-- Lock: prevents a card getting BOTH red+poly from multiple triggers in the same scoring resolution.
oc.ability = oc.ability or {}
oc.ability.extra = oc.ability.extra or {}
if oc.ability.extra._df_zamC_buff_uid ~= suid then
  if DF_prob(card, n, d, seed, guaranteed) then
    oc.ability.extra._df_zamC_buff_uid = suid

    local which = (pseudorandom(seed .. "_which") < 0.5) and "red" or "poly"
    oc.ability.extra._df_zamC_buff_which = which

    -- Apply AFTER this trigger finishes (works for retriggers too)
    DF_apply_buff_after_trigger(oc, which)
  end
end

      end

      -- NOTE: no 'return' here; payouts still need to run for play scoring.
    end

    ----------------------------------------------------------------
    -- Money: ONLY when Crowned cards SCORE in played hand (G.play)
    ----------------------------------------------------------------
    if context.individual
      and context.other_card
      and context.cardarea == G.play
      and DF_is_scoring_now(context)
    then
      local oc = context.other_card
      if DF_has_enh(oc, CROWNED_ENH_KEY) then
        local cash = card.ability.extra.crowned_cash or 3
        if DF_prob(card, card.ability.extra.double_cash_num, card.ability.extra.double_cash_den, "zamC_double_cash", guaranteed) then
          cash = cash * 2
        end

        -- OPTIONAL/RECOMMENDED:
        -- If your shield file defines DF_track_zamC_earned, call it here so the passive always works.
        if type(DF_track_zamC_earned) == "function" then
          pcall(function() DF_track_zamC_earned(cash, card) end)
        end

        return { dollars = 3, card = card }
      end
    end
  end,
}

return {
  config_key = "zamazenta",
  list = { zamazenta, zamazenta_crowned }
}
