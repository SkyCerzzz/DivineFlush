local divine_pack_tag = {
  object_type = "Tag",
  atlas = "DF_tags",
  name = "divine_pack_tag",
  order = 25,
  pos = { x = 0, y = 0 },
  config = { type = "new_blind_choice" },
  key = "divine_pack_tag",
  min_ante = 5,
  discovered = true,

  loc_vars = function(self, info_queue)
    -- Shows the pack in tooltip (set/key matches how packs are displayed in other mods)
    info_queue[#info_queue + 1] = { set = "Other", key = "p_DF_divinepack_normal_1" }
    return { vars = {} }
  end,

  apply = function(self, tag, context)
    if context and context.type == "new_blind_choice" then
      tag:yep("+", G.ARGS.LOC_COLOURS.item, function()
        -- This should be the pack CENTER key
        local key = "p_DF_divinepack_normal_1"

        local center = G.P_CENTERS and G.P_CENTERS[key]
        if not center then
          -- Fail safely if the pack isn't registered yet / wrong key
          return true
        end

        local card = Card(
          G.play.T.x + G.play.T.w / 2 - G.CARD_W * 1.27 / 2,
          G.play.T.y + G.play.T.h / 2 - G.CARD_H * 1.27 / 2,
          G.CARD_W * 1.27,
          G.CARD_H * 1.27,
          G.P_CARDS.empty,
          center,
          { bypass_discovery_center = true, bypass_discovery_ui = true }
        )
        card.cost = 0
        card.from_tag = true
        G.FUNCS.use_card({ config = { ref_table = card } })
        card:start_materialize()
        return true
      end)

      tag.triggered = true
      return true
    end
  end,
}

return {
  name = "DFTags",
  list = { divine_pack_tag }
}