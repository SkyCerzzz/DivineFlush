-- Spectrier 897
local spectrier = {
  name = "spectrier",
  pos = {x = 13, y = 6},
  config = { extra = { Xmult_multi = 1.5 } },

  loc_vars = function(self, info_queue, card)
    type_tooltip(self, info_queue, card)
    return { vars = { card.ability.extra.Xmult_multi } }
  end,

  rarity = 4,
  cost = 20,
  stage = "Legendary",
  ptype = "Psychic",
  gen = 8,
  blueprint_compat = false,
  unlocked = true,
  discovered = true,

  calculate = function(self, card, context)
    if not context then return end

    ------------------------------------------------------------
    -- Buff OTHER Psychic jokers
    ------------------------------------------------------------
    if context.other_joker
      and is_type(context.other_joker, "Psychic")
      and not context.blueprint
      and not card.debuff
    then
      G.E_MANAGER:add_event(Event({
        func = function()
          if context.other_joker and context.other_joker.juice_up then
            context.other_joker:juice_up(0.5, 0.5)
          end
          return true
        end
      }))

      return {
        message = localize{ type = 'variable', key = 'a_xmult', vars = { card.ability.extra.Xmult_multi } },
        colour = G.C.XMULT,
        Xmult_mod = card.ability.extra.Xmult_multi
      }
    end

    ------------------------------------------------------------
    -- Buff SELF (when Spectrier is being evaluated)
    ------------------------------------------------------------
    if context.joker_main
      and context.card == card
      and is_type(card, "Psychic")
      and not context.blueprint
      and not card.debuff
    then
      return {
        message = localize{ type = 'variable', key = 'a_xmult', vars = { card.ability.extra.Xmult_multi } },
        colour = G.C.XMULT,
        Xmult_mod = card.ability.extra.Xmult_multi
      }
    end

    ------------------------------------------------------------
    -- Boss blind reward
    ------------------------------------------------------------
    if context.end_of_round
      and context.game_over == false
      and context.main_eval
      and context.beat_boss
      and not context.blueprint
      and not card.debuff
    then
      G.E_MANAGER:add_event(Event({
        func = function()
          add_tag(Tag('tag_ethereal'))
          play_sound('generic1', 0.9 + math.random()*0.1, 0.8)
          play_sound('holo1', 1.2 + math.random()*0.1, 0.4)
          return true
        end
      }))
    end
  end,
}

return {
  config_key = "spectrier",
  list = { spectrier }
}
