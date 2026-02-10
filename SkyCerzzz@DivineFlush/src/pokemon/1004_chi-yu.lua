-- Chi-Yu 1004
local chi_yu = {
  name = "chi_yu",
  pos = { x = 26, y = 66 },
  soul_pos = { x = 27, y = 66 },

  -- Only what we actually use
  config = { extra = { used = false } },

  loc_vars = function(self, info_queue, center)
    type_tooltip(self, info_queue, center)
    return {}
  end,

  rarity = 4,
  cost = 20,
  stage = "Legendary",
  ptype = "Fire",
  gen = 9,
  atlas = "AtlasJokersBasicNatdex",
  blueprint_compat = true,
  unlocked = true,
  discovered = true,

  calculate = function(self, card, context)
    card.ability.extra = card.ability.extra or {}
    if card.ability.extra.used == nil then
      card.ability.extra.used = false
    end

    -- Reset once-per-round gate
    if context.end_of_round or context.setting_blind then
      card.ability.extra.used = false
    end

    -- First Mult scored each round -> add Red Seal to leftmost played card
    if context.individual
      and context.cardarea == G.play
      and context.other_card
      and not card.ability.extra.used
      and SMODS.has_enhancement(context.other_card, "m_mult")
    then
      card.ability.extra.used = true

      local leftmost = G.play and G.play.cards and G.play.cards[1]
      if leftmost then
        if leftmost.set_seal then
          leftmost:set_seal("Red", true)
        else
          leftmost.seal = "Red"
        end
      end
    end

    -- Retrigger all Hearts
    if context.repetition
      and context.cardarea == G.play
      and context.other_card
    then
      local is_heart = false

      if context.other_card.base and context.other_card.base.suit then
        is_heart = (context.other_card.base.suit == "Hearts")
      elseif context.other_card.is_suit then
        is_heart = (context.other_card:is_suit("Hearts") == true)
      end

      if is_heart then
        return {
          message = localize('k_again_ex'),
          repetitions = 1,
          card = card
        }
      end
    end
  end,
}

return {
  config_key = "chi_yu",
  list = { chi_yu }
}