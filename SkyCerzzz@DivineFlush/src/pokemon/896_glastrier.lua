-- Glastrier 896
local glastrier = {
  name = "glastrier",
  pos = {x = 13, y = 6},
  config = {extra = {limit = 2, triggers = 0}},
  loc_vars = function(self, info_queue, center)
    type_tooltip(self, info_queue, center)
    if pokermon_config.detailed_tooltips then
      info_queue[#info_queue+1] = G.P_CENTERS.m_glass
      if not center.edition or (center.edition and not center.edition.polychrome) then
        info_queue[#info_queue+1] = G.P_CENTERS.e_polychrome
      end
    end
    return {vars = {center.ability.extra.limit, center.ability.extra.triggers}}
  end,
  rarity = 4,
  cost = 20,
  stage = "Legendary",
  ptype = "Water",
  gen = 8,
  blueprint_compat = false,
  unlocked = true,
  discovered = true,

  calculate = function(self, card, context)
    -- Copy first 2 scoring Glass cards as Polychrome
    if context.individual
      and context.cardarea == G.play
      and context.other_card
      and SMODS.has_enhancement(context.other_card, 'm_glass')
      and not context.other_card.debuff
      and not context.end_of_round
      and card.ability.extra.triggers < card.ability.extra.limit then

      G.playing_card = (G.playing_card and G.playing_card + 1) or 1
      local card_to_copy = context.other_card

      G.E_MANAGER:add_event(Event({
        func = function()
          local copy = copy_card(card_to_copy, nil, nil, G.playing_card)
          copy:add_to_deck()
          G.deck.config.card_limit = G.deck.config.card_limit + 1
          table.insert(G.playing_cards, copy)
          G.hand:emplace(copy)
          copy.states.visible = nil
          copy:start_materialize()
          local edition = {polychrome = true}
          copy:set_edition(edition, true)
          playing_card_joker_effects({copy})
          return true
        end
      }))

      if not context.blueprint then
        card.ability.extra.triggers = card.ability.extra.triggers + 1
      end

      return {
        message = localize('k_copied_ex'),
        colour = G.C.CHIPS,
        card = card,
        playing_cards_created = {true}
      }
    end

    -- Reset trigger count at end of round
    if not context.repetition and not context.individual and context.end_of_round then
      card.ability.extra.triggers = 0
    end

    -- Make Glass cards unbreakable (if you’re using the per-card probability hook)
    if context.fix_probability and not context.blueprint then
      return {
        numerator = 0,
      }
    end
  end,
}

return {
  config_key = "glastrier",
  list = { glastrier }
}
