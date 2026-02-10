-- Chien-Pao 1002
local chien_pao = {
  name = "chien_pao",
  pos = { x = 22, y = 66 },
  soul_pos = { x = 23, y = 66 },

  -- Only what we actually use
  config = { extra = { used = false } },

  loc_vars = function(self, info_queue, center)
    type_tooltip(self, info_queue, center)
    return {}
  end,

  rarity = 4,
  cost = 20,
  stage = "Legendary",
  ptype = "Water",
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

    -- First Glass scored each round -> add Red Seal to leftmost played card
    if context.individual
      and context.cardarea == G.play
      and context.other_card
      and not card.ability.extra.used
      and SMODS.has_enhancement(context.other_card, "m_glass")
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

    -- Retrigger all Diamonds
    if context.repetition
      and context.cardarea == G.play
      and context.other_card
    then
      local is_diamond = false

      if context.other_card.base and context.other_card.base.suit then
        is_diamond = (context.other_card.base.suit == "Diamonds")
      elseif context.other_card.is_suit then
        is_diamond = (context.other_card:is_suit("Diamonds") == true)
      end

      if is_diamond then
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
  config_key = "chien_pao",
  list = { chien_pao }
}