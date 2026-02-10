-- Calyrex 898
local calyrex = {
  name = "calyrex",
  pos = { x = 0, y = 0 },

  config = { extra = {} },

  loc_vars = function(self, info_queue, center)
    type_tooltip(self, info_queue, center)
    return { vars = {} }
  end,

  rarity = 4,
  cost = 20,
  stage = "Legendary",
  ptype = "Psychic",
  gen = 8,
  blueprint_compat = true,
  unlocked = true,
  discovered = true,

  add_to_deck = function(self, card, from_debuff)
    if not (G.consumeables and G.consumeables.cards) then return end
    if #G.consumeables.cards >= G.consumeables.config.card_limit then return end

    local _card = create_card('Item', G.consumeables, nil, nil, nil, nil, 'c_DF_reins_of_unity')
    if not _card then return end

    _card:set_edition({ negative = true }, true)
    _card:add_to_deck()
    G.consumeables:emplace(_card)

    if card_eval_status_text then
      card_eval_status_text(_card, 'extra', nil, nil, nil, { message = localize('poke_plus_pokeitem'), colour = G.C.FILTER })
    end
  end,

  calculate = function(self, card, context)
  if not context then return end

  ----------------------------------------------------------------
  -- Helpers (local to calculate)
  ----------------------------------------------------------------
  local function is_king(c)
    return c and c.base and c.base.value == 'K'
  end

  local function is_unenhanced(c)
    -- Most common: enhancement stored here
    if c and c.ability and c.ability.enhancement then return false end
    -- Some mods also treat "Stone"/etc as enhancements; SMODS helper covers most cases
    -- (We can't detect "any enhancement" perfectly, but this works for normal unenhanced cards.)
    return true
  end

  local function is_flush_context()
    -- Most reliable when available
    if context.scoring_name then
      return context.scoring_name == "Flush"
    end

    -- Fallback: compute from scoring_hand (if provided as list of cards)
    local hand = context.scoring_hand
    if type(hand) ~= "table" then return false end
    local suit = nil
    for _, c in ipairs(hand) do
      if c and c.base and c.base.suit then
        suit = suit or c.base.suit
        if c.base.suit ~= suit then return false end
      end
    end
    return suit ~= nil
  end

  local function give_random_seal_and_edition(c)
    if not c then return end

    -- Random seal (only if card supports it)
    local seals = { "Red", "Blue", "Gold", "Purple" }
    local s = seals[math.floor(pseudorandom("calyrex_seal") * #seals) + 1]
    if c.set_seal then
      c:set_seal(s, true)
    else
      c.seal = s
    end

    -- Random edition
    local editions = { "foil", "holo", "polychrome" }
    local e = editions[math.floor(pseudorandom("calyrex_edition") * #editions) + 1]
    if c.set_edition then
      c:set_edition({ [e] = true }, true)
    end

    if c.juice_up then c:juice_up(0.6, 0.6) end
  end

 ----------------------------------------------------------------
-- Kings: add random Seal + Edition if unenhanced
----------------------------------------------------------------
if context.individual and context.cardarea == G.play and (context.other_card or context.card) then
  local c = context.other_card or context.card

  -- King check (support multiple representations)
  local v = c.base and c.base.value
  local id = c.base and c.base.id
  local is_king = (v == 'K' or v == 'King' or id == 13)
  if not is_king then return end

  -- Unenhanced check (robust)
  local function is_unenhanced(card_obj)
    if not card_obj then return false end

    -- If SMODS enhancements exist, treat ANY enhancement as "enhanced"
    if SMODS and SMODS.has_enhancement then
      local enh_keys = {
        "m_bonus","m_mult","m_wild","m_glass","m_steel","m_stone","m_gold","m_lucky"
      }
      for _, k in ipairs(enh_keys) do
        if SMODS.has_enhancement(card_obj, k) then return false end
      end
    end

    -- Some stacks store enhancement as a center key beginning with m_
    local ck = card_obj.config and card_obj.config.center and card_obj.config.center.key
    if type(ck) == "string" and ck:sub(1,2) == "m_" then
      return false
    end

    return true
  end

  if not is_unenhanced(c) then return end

  -- Only apply once per card
  c.ability = c.ability or {}
  c.ability.extra = c.ability.extra or {}
  if c.ability.extra._df_calyrex_blessed then return end

  G.E_MANAGER:add_event(Event({
    trigger = "immediate",
    func = function()
      -- DEBUG POPUP (remove later if you want)
      if card_eval_status_text then
        card_eval_status_text(c, 'extra', nil, nil, nil, { message = "Calyrex hit!", colour = G.C.FILTER })
      end

      -- Random seal
      local seals = { "Red", "Blue", "Gold", "Purple" }
      local s = seals[math.floor(pseudorandom("calyrex_seal") * #seals) + 1]
      if c.set_seal then
        c:set_seal(s, true)
      elseif c.set_seal ~= false then
        c.seal = s
      end

      -- Random edition
      local editions = { "foil", "holo", "polychrome" }
      local e = editions[math.floor(pseudorandom("calyrex_edition") * #editions) + 1]
      if c.set_edition then
        c:set_edition({ [e] = true }, true)
      else
        c.edition = c.edition or {}
        c.edition[e] = true
      end

      -- mark after success
      c.ability = c.ability or {}
      c.ability.extra = c.ability.extra or {}
      c.ability.extra._df_calyrex_blessed = true

      if c.juice_up then c:juice_up(0.6, 0.6) end
      return true
    end
  }))
end

  ----------------------------------------------------------------
  -- 2) Retrigger pass: if Flush, retrigger played cards that have BOTH seal+edition
  ----------------------------------------------------------------
  if context.repetition and context.cardarea == G.play and context.other_card and context.scoring_hand then
    if is_flush_context() then
      local c = context.other_card
      if c and c.seal and c.edition then
        return {
          message = localize('k_again_ex'),
          repetitions = 1,
          card = card
        }
      end
    end
  end
end,
}

-- Calyrex_Ice 898
local calyrex_ice = {
  name = "calyrex_ice",
  pos = {x = 12, y = 10},
  soul_pos = {x = 13, y = 10},
  config = { extra = { saved_glass_chance = nil } },
  rarity = "DF_divine",
  cost = 20,
  stage = "Divine",
  ptype = "Psychic",
  atlas = "DivineFlushAtlasGen8",
  gen = 8,
  blueprint_compat = true,
  unlocked = true,
  discovered = true,

  calculate = function(self, card, context)
  if not context then return end

  ----------------------------------------------------------------
  -- Give Blizzard once when this form is first active (works on transform)
  ----------------------------------------------------------------
  card.ability = card.ability or {}
  card.ability.extra = card.ability.extra or {}

  if not card.ability.extra._df_given_blizzard then
    card.ability.extra._df_given_blizzard = true

    local _card = create_card('Item', G.consumeables, nil, nil, nil, nil, 'c_DF_blizzard')
    if _card then
      _card:set_edition({ negative = true }, true)
      _card:add_to_deck()
      G.consumeables:emplace(_card)

      if card_eval_status_text then
        card_eval_status_text(_card, 'extra', nil, nil, nil, {
          message = localize('poke_plus_pokeitem'),
          colour = G.C.FILTER
        })
      end
    end
  end

  ----------------------------------------------------------------
  -- ORIGINAL RETRIGGER LOGIC (unchanged)
  ----------------------------------------------------------------
  if context.repetition
    and context.cardarea == G.play
    and context.other_card
    and not context.blueprint
  then
    local is_glass = false
    if SMODS and SMODS.has_enhancement then
      is_glass = SMODS.has_enhancement(context.other_card, 'm_glass')
    end
    if not is_glass then
      local oc = context.other_card
      if oc and oc.ability and oc.ability.name == 'Glass Card' then
        is_glass = true
      end
      if oc and oc.config and oc.config.center and oc.config.center.key == 'm_glass' then
        is_glass = true
      end
    end

    if is_glass then
      local count = 0
      if G.consumeables and G.consumeables.cards then
        for _, v in ipairs(G.consumeables.cards) do
          local k = v and v.config and v.config.center and v.config.center.key
          if k == 'c_poke_icestone' or k == 'c_DF_blizzard' then
            count = count + 1
          end
        end
      end

      local reps = math.min(count, 2)
      if reps > 0 then
        return {
          message = localize('k_again_ex'),
          repetitions = reps,
          card = card
        }
      end
    end
  end

  if context.fix_probability and not context.blueprint then
    return { numerator = 0 }
  end
end,
}

-- Calyrex_Shadow 898
local calyrex_shadow = {
  name = "calyrex_shadow",
  pos = {x = 14, y = 10},
  soul_pos = {x = 15, y = 10},
  config = {extra = {Xmult_multi = 2}},
  loc_vars = function(self, info_queue, center)
    type_tooltip(self, info_queue, center)
    return {vars = {center.ability.extra.Xmult_multi, }}
  end,
  rarity = "DF_divine",
  cost = 20,
  stage = "Divine",
  ptype = "Psychic",
  atlas = "DivineFlushAtlasGen8",
  gen = 8,
  blueprint_compat = true,
  unlocked = true,
  discovered = true,

  calculate = function(self, card, context)
  if not context then return end

  ----------------------------------------------------------------
  -- Give Resurrect once when this form is first active (works on transform)
  ----------------------------------------------------------------
  card.ability = card.ability or {}
  card.ability.extra = card.ability.extra or {}

  if not card.ability.extra._df_given_resurrect then
    card.ability.extra._df_given_resurrect = true

    local _card = create_card('Item', G.consumeables, nil, nil, nil, nil, 'c_DF_resurrect')
    if _card then
      _card:set_edition({ negative = true }, true)
      _card:add_to_deck()
      G.consumeables:emplace(_card)

      if card_eval_status_text then
        card_eval_status_text(_card, 'extra', nil, nil, nil, {
          message = localize('poke_plus_pokeitem'),
          colour = G.C.FILTER
        })
      end
    end
  end

  ----------------------------------------------------------------
  -- ORIGINAL XMult + retrigger logic (unchanged)
  ----------------------------------------------------------------
  card.ability.extra = card.ability.extra or {}

  local eval_id = nil
  if context.scoring_hand and G and G.GAME and G.GAME.round_resets then
    eval_id = tostring(G.GAME.round_resets.ante or 0) .. ":" ..
              tostring(G.GAME.round_resets.blind or 0) .. ":" ..
              tostring(G.GAME.hands_played or 0)
  end

  if context.other_joker
    and is_type(context.other_joker, "Psychic")
    and not context.blueprint
    and not card.debuff
  then
    if context.other_joker == card then
      if eval_id then
        if card.ability.extra._df_shadow_last_xmult_eval == eval_id then
          return
        end
        card.ability.extra._df_shadow_last_xmult_eval = eval_id
      else
        if card.ability.extra._df_shadow_xmult_used then return end
        card.ability.extra._df_shadow_xmult_used = true
      end
    end

    return {
      message = localize{type = 'variable', key = 'a_xmult', vars = {card.ability.extra.Xmult_multi}},
      colour = G.C.XMULT,
      Xmult_mod = card.ability.extra.Xmult_multi
    }
  end

  if context.joker_main
    and context.card == card
    and is_type(card, "Psychic")
    and not context.blueprint
    and not card.debuff
  then
    if eval_id then
      if card.ability.extra._df_shadow_last_xmult_eval ~= eval_id then
        card.ability.extra._df_shadow_last_xmult_eval = eval_id
        return {
          message = localize{type = 'variable', key = 'a_xmult', vars = {card.ability.extra.Xmult_multi}},
          colour = G.C.XMULT,
          Xmult_mod = card.ability.extra.Xmult_multi
        }
      end
    else
      if not card.ability.extra._df_shadow_xmult_used then
        card.ability.extra._df_shadow_xmult_used = true
        return {
          message = localize{type = 'variable', key = 'a_xmult', vars = {card.ability.extra.Xmult_multi}},
          colour = G.C.XMULT,
          Xmult_mod = card.ability.extra.Xmult_multi
        }
      end
    end
  end

  if context.end_of_round and context.main_eval then
    card.ability.extra._df_shadow_xmult_used = nil
  end

  local retriggers = 0
  if G.consumeables and G.consumeables.cards then
    for _, v in ipairs(G.consumeables.cards) do
      local is_spectral = (v.ability and v.ability.set == 'Spectral')
      local center_key = v and v.config and v.config.center and v.config.center.key
      local is_resurrect = (center_key == 'c_DF_resurrect')
      if is_spectral or is_resurrect then
        retriggers = retriggers + 1
      end
    end
  end

  retriggers = math.min(retriggers, 2)

  if context.repetition
    and context.cardarea == G.play
    and retriggers > 0
    and not context.blueprint
  then
    return {
      message = localize('k_again_ex'),
      repetitions = retriggers,
      card = card
    }
  end
end,

}

return {
  config_key = "calyrex",
  list = {calyrex, calyrex_shadow, calyrex_ice }
}