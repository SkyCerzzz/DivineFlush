-- src/jokers/??_zacian.lua
-- FULL COPY/PASTE
--
-- Fixes:
-- 1) Prevents "too many retriggers" by:
--    - Applying Xmult ONLY in context.individual (which is called for initial + repeats)
--    - Using context.repetition ONLY to schedule repeats (no Xmult there)
-- 2) Adds per-scoring-pass guard so the same Joker can't schedule repeats multiple times
--    for the same other_card in the same scoring resolution.
-- 3) DF_has_enh falls back to center key even if SMODS.has_enhancement returns false.
-- 4) Crowned scaling triggers exactly when crowned retrigger counter reaches 10 in a blind
--    (calls DF.try_scale_crowned_sword() if defined by your Crowned Sword file).
-- 5) Removes duplicated Xmult_multi in crowned config.

DF = DF or {}
local DF = DF

local RUSTED_ENH_KEY  = "m_DF_rusted"
local CROWNED_ENH_KEY = "m_DF_crowned"

DF._retrigger_tracker = DF._retrigger_tracker or {}

----------------------------------------------------------------
-- Blind tracker helpers
----------------------------------------------------------------
local function DF_blind_id()
  local rr = (G and G.GAME and G.GAME.round_resets) or {}
  return tostring(rr.ante or 0) .. ":" .. tostring(rr.blind or 0)
end

local function DF_reset_tracker_if_needed()
  local bid = DF_blind_id()
  if DF._retrigger_tracker._bid ~= bid then
    DF._retrigger_tracker._bid = bid
    DF._retrigger_tracker.crowned = 0
    DF._retrigger_tracker.rusted  = 0
  end
end

-- NOTE: we only call this from repetition scheduling (the source of truth)
local function DF_track_retrigger(is_rusted, is_crowned, amount)
  DF_reset_tracker_if_needed()
  amount = amount or 1
  if is_crowned then
    DF._retrigger_tracker.crowned = (DF._retrigger_tracker.crowned or 0) + amount
  end
  if is_rusted then
    DF._retrigger_tracker.rusted = (DF._retrigger_tracker.rusted or 0) + amount
  end
end

----------------------------------------------------------------
-- Scoring gate: prevent end-of-round / cleanup conversions
----------------------------------------------------------------
local function DF_is_scoring_now(context)
  if not context then return false end
  if context.end_of_round then return false end
  if context.scoring_hand or context.scoring then return true end
  if G and G.STATE and G.STATES and G.STATE == G.STATES.HAND_PLAYED then return true end
  return false
end

local function DF_repetition_target_ok(context)
  if not context then return false end
  if not DF_is_scoring_now(context) then return false end
  return (context.cardarea == G.play or context.cardarea == G.hand)
end

----------------------------------------------------------------
-- Per-scoring-pass guard to prevent double scheduling
----------------------------------------------------------------
DF._df_score_uid = DF._df_score_uid or 0
DF._df_last_score_uid = DF._df_last_score_uid or "0"

local function DF_score_uid(context)
  -- If your framework provides a stable uid, use it.
  if context and context.scoring_uid then return tostring(context.scoring_uid) end

  -- Fallback: bump when we see a "main scoring" style context
  if context and (context.before or context.joker_main or context.scoring_hand or context.scoring) then
    DF._df_score_uid = (DF._df_score_uid or 0) + 1
    DF._df_last_score_uid = tostring(DF._df_score_uid)
  end
  return DF._df_last_score_uid or "0"
end

local function DF_mark_repeat_scheduled(other_card, joker_key, suid)
  if not other_card then return false end
  other_card.ability = other_card.ability or {}
  other_card.ability.extra = other_card.ability.extra or {}
  local k = "_df_rep_scheduled_"..tostring(joker_key)
  if other_card.ability.extra[k] == suid then
    return false
  end
  other_card.ability.extra[k] = suid
  return true
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

local function DF_has_crowned_zamazenta()
  return DF_has_joker_key("j_DF_zamazenta_crowned")
end

-- Base Zacian: guaranteed if ANY Zamazenta form exists
local function DF_has_zamazenta_any()
  return DF_has_joker_key("j_DF_zamazenta") or DF_has_joker_key("j_DF_zamazenta_crowned")
end

----------------------------------------------------------------
-- Enhancement helpers (robust)
----------------------------------------------------------------
local function DF_has_enh(card, enh_key)
  if not (card and enh_key) then return false end
  if SMODS and SMODS.has_enhancement then
    local ok = SMODS.has_enhancement(card, enh_key)
    if ok then return true end
    -- fall through to center-key check (important!)
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

local function DF_prob(card, num, den, seed_key, guaranteed)
  if guaranteed then return true end
  if SMODS and SMODS.get_probability_vars then
    local n, d = SMODS.get_probability_vars(card, num, den, seed_key)
    num, den = n, d
  end
  return pseudorandom(seed_key) < (num / den)
end

----------------------------------------------------------------
-- Conversion helpers (shared between individual/repetition)
----------------------------------------------------------------
local function DF_apply_steel_to_rusted(joker_card, oc, num, den, seed, guaranteed)
  if DF_has_enh(oc, "m_steel") and (not DF_has_enh(oc, RUSTED_ENH_KEY)) and (not DF_has_enh(oc, CROWNED_ENH_KEY)) then
    if DF_prob(joker_card, num, den, seed, guaranteed) then
      DF_set_enh(oc, RUSTED_ENH_KEY)
      return true
    end
  end
  return false
end

----------------------------------------------------------------
-- Zacian (Legendary)
----------------------------------------------------------------
local zacian = {
  name = "zacian",
  pos = { x = 6, y = 9 },
  soul_pos = { x = 7, y = 9 },

  config = {
    extra = {
      Xmult_multi = 1.2,
      steel_to_rusted_num = 1,
      steel_to_rusted_den = 2,
      rusted_to_poly_num = 1,
      rusted_to_poly_den = 4,
    }
  },

  loc_vars = function(self, info_queue, center)
    if type_tooltip then type_tooltip(self, info_queue, center) end

    local g = DF_has_zamazenta_any()
    local sN, sD = center.ability.extra.steel_to_rusted_num, center.ability.extra.steel_to_rusted_den
    local pN, pD = center.ability.extra.rusted_to_poly_num, center.ability.extra.rusted_to_poly_den

    if SMODS and SMODS.get_probability_vars and not g then
      sN, sD = SMODS.get_probability_vars(center, sN, sD, "zacian_steel_to_rusted")
      pN, pD = SMODS.get_probability_vars(center, pN, pD, "zacian_rusted_to_poly")
    end

    return { vars = { center.ability.extra.Xmult_multi, sN, sD, pN, pD } }
  end,

  rarity = 4,
  cost = 20,
  stage = "Legendary",
  ptype = "Fairy",
  gen = 8,
  blueprint_compat = true,
  unlocked = true,
  discovered = true,

  calculate = function(self, card, context)
    if not context then return end
    if context.card_added or context.selling_card or context.removing_card or context.destroying_card then return end
    if context.end_of_round then return end

    -- Defensive: if crowned exists, base should not stack behavior
    if DF_has_joker_key("j_DF_zacian_crowned") then
      return
    end

    local guaranteed = false

    ----------------------------------------------------------------
    -- INDIVIDUAL: conversions + Xmult (this is called on initial AND repeats)
    ----------------------------------------------------------------
    if context.individual
      and context.other_card
      and not context.blueprint
      and DF_is_scoring_now(context)
      and (context.cardarea == G.play or context.cardarea == G.hand)
    then
      local oc = context.other_card

      -- Steel -> Rusted
      DF_apply_steel_to_rusted(card, oc,
        card.ability.extra.steel_to_rusted_num, card.ability.extra.steel_to_rusted_den,
        "zacian_steel_to_rusted", guaranteed
      )

      -- Rusted -> Polychrome chance
      if DF_has_enh(oc, RUSTED_ENH_KEY) then
        if not (oc.edition and oc.edition.polychrome) then
          if DF_prob(card, card.ability.extra.rusted_to_poly_num, card.ability.extra.rusted_to_poly_den,
            "zacian_rusted_to_poly", guaranteed) then
            oc:set_edition({ polychrome = true }, true)
          end
        end

        local x = card.ability.extra.Xmult_multi or 1.2
        return {
          message = localize{ type='variable', key='a_xmult', vars={ x } },
          colour = G.C.XMULT,
          Xmult_mod = x,
          card = card
        }
      end
    end
  end,
}

----------------------------------------------------------------
-- Zacian (Crowned) (Divine)
-- - Rusted: retrigger only, NO Xmult
-- - Crowned: Xmult applies via individual (initial + repeats)
-- - Steel -> Rusted
-- - Rusted -> Crowned
----------------------------------------------------------------
local zacian_crowned = {
  name = "zacian_crowned",
  pos = { x = 8, y = 9 },
  soul_pos = { x = 9, y = 9 },

  config = {
    extra = {
      Xmult_multi = 1.3,

      steel_to_rusted_num = 1,
      steel_to_rusted_den = 4,

      rusted_to_crowned_num = 1,
      rusted_to_crowned_den = 2,

      second_retrig_num = 1,
      second_retrig_den = 3,
    }
  },

  loc_vars = function(self, info_queue, center)
  if type_tooltip then type_tooltip(self, info_queue, center) end

  -- Guaranteed flag
  local g = DF_has_crowned_zamazenta()

  -- Probabilities (with SMODS support)
  local sN, sD = center.ability.extra.steel_to_rusted_num, center.ability.extra.steel_to_rusted_den
  local rN, rD = center.ability.extra.rusted_to_crowned_num, center.ability.extra.rusted_to_crowned_den
  local tN, tD = center.ability.extra.second_retrig_num, center.ability.extra.second_retrig_den

  if SMODS and SMODS.get_probability_vars and not g then
    sN, sD = SMODS.get_probability_vars(center, sN, sD, "zacianC_steel_to_rusted")
    rN, rD = SMODS.get_probability_vars(center, rN, rD, "zacianC_rusted_to_crowned")
    tN, tD = SMODS.get_probability_vars(center, tN, tD, "zacianC_second_retrig")
  end

  local ability = center.ability
if type(ability) ~= "table" then
  ability = {}
  center.ability = ability
end

ability.extra = ability.extra or {}

local bonus = tonumber(ability.extra._df_item_scale_bonus or 0) or 0

  -- Display values
  local rusted_display = 1.0
  local crowned_base = center.ability.extra.Xmult_multi or 1.3
  local crowned_display = crowned_base + bonus

  return {
    vars = {
      rusted_display,      -- #1#
      crowned_display,     -- #2#
      sN, sD,              -- #3# #4#
      rN, rD,              -- #5# #6#
      tN, tD               -- #7# #8#
    }
  }
end,

  rarity = "DF_divine",
  cost = 20,
  stage = "Divine",
  ptype = "Fairy",
  atlas = "DivineFlushAtlasGen8",
  gen = 8,
  blueprint_compat = false,
  unlocked = true,
  discovered = true,

  calculate = function(self, card, context)
    if not context then return end
    if context.card_added or context.selling_card or context.removing_card or context.destroying_card then return end
    if context.end_of_round then return end

    local guaranteed = DF_has_crowned_zamazenta()

    if type(card.ability) ~= "table" then
  card.ability = {}
end
card.ability.extra = card.ability.extra or {}
    if type(card.ability.extra._df_item_scale_bonus) ~= "number" then
      card.ability.extra._df_item_scale_bonus = 0
    end

    ----------------------------------------------------------------
    -- INDIVIDUAL: conversions + Crowned Xmult only
    -- (called for initial AND repeats)
    ----------------------------------------------------------------
    if context.individual
      and context.other_card
      and not context.blueprint
      and DF_is_scoring_now(context)
      and (
  context.cardarea == G.play
  or (DF_has_crowned_zamazenta() and context.cardarea == G.hand)
)
    then
      local oc = context.other_card

      -- Steel -> Rusted
      DF_apply_steel_to_rusted(card, oc,
        card.ability.extra.steel_to_rusted_num, card.ability.extra.steel_to_rusted_den,
        "zacianC_steel_to_rusted", guaranteed
      )

      -- Rusted -> Crowned
      if DF_has_enh(oc, RUSTED_ENH_KEY) and (not DF_has_enh(oc, CROWNED_ENH_KEY)) then
        if DF_prob(card, card.ability.extra.rusted_to_crowned_num, card.ability.extra.rusted_to_crowned_den,
          "zacianC_rusted_to_crowned", guaranteed) then
          DF_set_enh(oc, CROWNED_ENH_KEY)
        end
      end

      -- Apply mult ONLY if crowned (rusted gives no mult)
      if DF_has_enh(oc, CROWNED_ENH_KEY) then
        local base_crowned = card.ability.extra.Xmult_multi or 1.3
        local bonus = tonumber(card.ability.extra._df_item_scale_bonus or 0) or 0
        local x = base_crowned + bonus

        return {
          message = localize{ type='variable', key='a_xmult', vars={ x } },
          colour = G.C.XMULT,
          Xmult_mod = x,
          card = card
        }
      end
    end

    ----------------------------------------------------------------
    -- REPETITION: schedule repeats only (NO Xmult here!)
    ----------------------------------------------------------------
    if context.repetition and context.other_card and DF_is_scoring_now(context) then
  local allow_hand = DF_has_crowned_zamazenta()
  if not (context.cardarea == G.play or (allow_hand and context.cardarea == G.hand)) then return end

      local oc = context.other_card
      local suid = DF_score_uid(context)

      local joker_key = (card.config and card.config.center and card.config.center.key) or "j_DF_zacian_crowned"
      if not DF_mark_repeat_scheduled(oc, joker_key, suid) then
        return
      end

      -- Steel -> Rusted
      DF_apply_steel_to_rusted(card, oc,
        card.ability.extra.steel_to_rusted_num, card.ability.extra.steel_to_rusted_den,
        "zacianC_steel_to_rusted", guaranteed
      )

      -- Rusted -> Crowned (can happen before deciding reps)
      if DF_has_enh(oc, RUSTED_ENH_KEY) and (not DF_has_enh(oc, CROWNED_ENH_KEY)) then
        if DF_prob(card, card.ability.extra.rusted_to_crowned_num, card.ability.extra.rusted_to_crowned_den,
          "zacianC_rusted_to_crowned", guaranteed) then
          DF_set_enh(oc, CROWNED_ENH_KEY)
        end
      end

      local is_rusted  = DF_has_enh(oc, RUSTED_ENH_KEY)
      local is_crowned = DF_has_enh(oc, CROWNED_ENH_KEY)

      if not (is_rusted or is_crowned) then return end

      -- Decide repetitions (extra repeats)
      local reps = 1
      if DF_prob(card, card.ability.extra.second_retrig_num, card.ability.extra.second_retrig_den,
        "zacianC_second_retrig", guaranteed) then
        reps = 2
      end

      -- Track repeats we cause (source of truth)
      DF_reset_tracker_if_needed()
      local before_c = DF._retrigger_tracker.crowned or 0

      DF_track_retrigger(is_rusted, is_crowned, reps)

      -- Trigger Crowned Sword scaling exactly when crowned retriggers reaches 10 this blind
      if is_crowned and DF.try_scale_crowned_sword then
        local after_c = DF._retrigger_tracker.crowned or 0
        if before_c < 10 and after_c >= 10 then
  if DF.try_scale_crowned_sword then
    DF.try_scale_crowned_sword()
  end

  -- IMPORTANT: sync bonus onto THIS Zacian (Crowned) instance immediately
  if type(card.ability) ~= "table" then
  card.ability = {}
end
card.ability.extra = card.ability.extra or {}
  card.ability.extra._df_item_scale_bonus = tonumber(DF._crowned_sword_bonus or 0) or 0
  -- ALSO write to the center so tooltip vars update immediately
if G and G.P_CENTERS and G.P_CENTERS["j_DF_zacian_crowned"] then
  local c = G.P_CENTERS["j_DF_zacian_crowned"]
  c.ability = c.ability or {}
  c.ability.extra = c.ability.extra or {}
  c.ability.extra._df_item_scale_bonus = card.ability.extra._df_item_scale_bonus
end

-- (Optional) also mirror onto this instance's center ref if present
if card and card.config and card.config.center then
  card.config.center.ability = card.config.center.ability or {}
  card.config.center.ability.extra = card.config.center.ability.extra or {}
  card.config.center.ability.extra._df_item_scale_bonus = card.ability.extra._df_item_scale_bonus
end
end
      end

      -- Rusted: retrigger only; Crowned: also retrigger (mult is handled in individual on repeats)
      return {
        repetitions = reps,
        message = localize('k_again_ex'),
        colour = G.C.XMULT,
        card = card
      }
    end
  end,
}

return {
  config_key = "zacian",
  list = { zacian, zacian_crowned }
}
