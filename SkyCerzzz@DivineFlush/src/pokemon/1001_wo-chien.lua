-- Wo-Chien 1001
local wo_chien = {
  name = "wo_chien",
  pos = { x = 20, y = 66 },
  soul_pos = { x = 21, y = 66 },

  -- Only what we actually use
  config = { extra = { used = false } },

  loc_vars = function(self, info_queue, center)
    type_tooltip(self, info_queue, center)
    return {}
  end,

  rarity = 4,
  cost = 20,
  stage = "Legendary",
  ptype = "Grass",
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

    -- First Lucky scored each round -> add Red Seal to leftmost played card
    if context.individual
      and context.cardarea == G.play
      and context.other_card
      and not card.ability.extra.used
      and SMODS.has_enhancement(context.other_card, "m_lucky")
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

    -- Retrigger all Spades
    if context.repetition
      and context.cardarea == G.play
      and context.other_card
    then
      local is_spade = false

      if context.other_card.base and context.other_card.base.suit then
        is_spade = (context.other_card.base.suit == "Spades")
      elseif context.other_card.is_suit then
        is_spade = (context.other_card:is_suit("Spades") == true)
      end

      if is_spade then
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
  config_key = "wo_chien",
  list = { wo_chien }
}