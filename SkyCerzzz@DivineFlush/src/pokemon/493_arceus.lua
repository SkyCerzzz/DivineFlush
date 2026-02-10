-- Arceus 493
local arceus = {
  name = "arceus",
  pos = { x = 4, y = 4 },
  soul_pos = { x = 5, y = 4 },

  config = { extra = {} },

  loc_vars = function(self, info_queue, card)
    type_tooltip(self, info_queue, card)
    return { vars = {} }
  end,

  rarity = "DF_divine",
  cost = 20,
  stage = "Divine",
  ptype = "Colorless",
  atlas = "DivineFlushAtlasGen4",
  gen = 4,
  blueprint_compat = false,
  unlocked = true,
  discovered = true,

  calculate = function(self, card, context)
    if not (context and context.end_of_round and context.main_eval) then return end
    if context.game_over then return end
    if context.blueprint then return end
    if card.debuff then return end

    -- ===== Boss Blind -> Shaker Master Ball (respect consumable limit) =====
    if context.beat_boss then
      G.E_MANAGER:add_event(Event({
        func = function()
          if not (G and G.consumeables and G.consumeables.cards and G.consumeables.config) then
            return true
          end

          local limit = G.consumeables.config.card_limit or 0
          if #G.consumeables.cards >= limit then
            -- optional feedback; remove if you don't want popups
            if card_eval_status_text then
              card_eval_status_text(card, 'extra', nil, nil, nil, { message = "Consumables full!", colour = G.C.RED })
            end
            return true
          end

          local _card = create_card('Item', G.consumeables, nil, nil, nil, nil, 'c_DF_shaker_masterball')
          if _card then
            _card:add_to_deck()
            G.consumeables:emplace(_card)
          end
          return true
        end
      }))
      return
    end

    -- ===== Small / Big Blind -> Divine Tag =====
    G.E_MANAGER:add_event(Event({
      func = function()
        add_tag(Tag('tag_DF_divine_pack_tag'))
        return true
      end
    }))
  end,
}

return {
  config_key = "arceus",
  list = { arceus }
}