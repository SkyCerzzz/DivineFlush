-- Giratina 487
local giratina={
  name = "giratina",
  pos = { x = 8, y = 3 },
  soul_pos = { x = 9, y = 3 },
  config = { extra = { joker_slot_mod = 1, bosses_defeated = 0, upgrade_rqmt = 1, upgrade_rqmt_increase = 1 } },
  loc_vars = function(self, info_queue, card)
    type_tooltip(self, info_queue, card)
    return {
      vars = {
        card.ability.extra.joker_slot_mod,
        card.ability.extra.upgrade_rqmt,
        card.ability.extra.upgrade_rqmt - card.ability.extra.bosses_defeated,
        card.ability.extra.upgrade_rqmt == 1 and localize("boss_blind_singular") or localize("boss_blind_plural"),
        card.ability.extra.upgrade_rqmt_increase,
      }
    }
  end,
  rarity = "DF_divine",
  cost = 20,
  stage = "Divine",
  ptype = "Psychic",
  atlas = "DivineFlushAtlasGen4",
  gen = 4,
  blueprint_compat = false,
  unlocked = true,
  discovered = true,
  
  calculate = function(self, card, context)
    if context.end_of_round
        and context.game_over == false and context.main_eval and context.beat_boss
        and not context.blueprint and not card.debuff then
      card.ability.extra.bosses_defeated = card.ability.extra.bosses_defeated + 1
      if card.ability.extra.bosses_defeated == card.ability.extra.upgrade_rqmt then
        card.ability.extra.bosses_defeated = 0
        card.ability.extra.upgrade_rqmt = card.ability.extra.upgrade_rqmt + card.ability.extra.upgrade_rqmt_increase
        --G.jokers.config.card_limit = G.jokers.config.card_limit + 1
        local eligible_card = nil
        if #G.jokers.cards > 0 then
          for i = #G.jokers.cards, 1, -1 do
            local v = G.jokers.cards[i]
            if v.ability.set == 'Joker' and v.ability.name ~= "giratina" and not v.gone then
              eligible_card = v
              break
          end
        end

        if eligible_card then
          local edition = {negative = true}
          eligible_card:set_edition(edition, true)
          card_eval_status_text(
            eligible_card, 'extra', nil, nil, nil, {message = localize("poke_lick_ex"), colour = G.C.PURPLE})
        end
      end

        return {
          message = localize { type = 'variable', key = 'a_joker_slot', vars = { card.ability.extra.joker_slot_mod } },
          colour = G.C.DARK_EDITION
        }
      end
    end
  end,
}

return {
  config_key = "giratina",
  list = { giratina }
}
