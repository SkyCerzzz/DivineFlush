-- Ting-Lu 1003
local ting_lu = {
  name = "ting_lu",
  pos = { x = 24, y = 66 },
  soul_pos = { x = 25, y = 66 },

  -- Only keep what we actually need
  config = { extra = { used = false } },

  loc_vars = function(self, info_queue, center)
    type_tooltip(self, info_queue, center)
    return {}
  end,

  rarity = 4,
  cost = 20,
  stage = "Legendary",
  ptype = "Earth",
  gen = 9,
  atlas = "AtlasJokersBasicNatdex",
  blueprint_compat = true,
  unlocked = true,
  discovered = true,

  calculate = function(self, card, context)
    card.ability.extra = card.ability.extra or {}
    if card.ability.extra.used == nil then card.ability.extra.used = false end

    -- Reset once-per-round gate
    if context.end_of_round or context.setting_blind then
      card.ability.extra.used = false
    end

    -- First Stone scored each round -> add Red Seal to leftmost card in played hand
    if context.individual
      and context.cardarea == G.play
      and context.other_card
      and not card.ability.extra.used
      and SMODS.has_enhancement(context.other_card, "m_stone")
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

    -- Retrigger all Clubs
    if context.repetition
      and context.cardarea == G.play
      and context.other_card
    then
      local is_club = false

      if context.other_card.base and context.other_card.base.suit then
        is_club = (context.other_card.base.suit == "Clubs")
      elseif context.other_card.is_suit then
        is_club = (context.other_card:is_suit("Clubs") == true)
      end

      if is_club then
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
  config_key = "ting_lu",
  list = { ting_lu }
}