local legendaryshopdeck = {
  name = "legendaryshopdeck",
  key = "legendaryshopdeck",
  atlas = "DFBacks",
  pos = { x = 2, y = 0 },

  -- purely for display
  config = { extra = { chance_percent = 0.5 } },

  loc_vars = function(self)
    return { vars = { self.config.extra.chance_percent } } -- #1#
  end,

  apply = function(self)
    -- enable feature
    G.GAME.modifiers.DF_legendary_shop = true

    -- declare presence (rate is computed in main.lua)
    G.GAME.modifiers.DF_has_leg_deck = true
  end,
}

local legendaryshopsleeve = {
  name = "legendaryshopsleeve",
  key = "legendaryshopsleeve",
  atlas = "DFSleeves",
  pos = { x = 2, y = 0 },

  -- purely for display
  config = { extra = { chance_percent = 0.5 } },

  loc_vars = function(self)
    local key = self.key
    local percent = self.config.extra.chance_percent

    -- if paired with the deck, show 12% and use _alt loc key
    if self.get_current_deck_key() == "b_DF_legendaryshopdeck" then
      key = key .. "_alt"
      percent = 2.5
    end

    return { key = key, vars = { percent } }
  end,

  apply = function(self)
    CardSleeves.Sleeve.apply(self)

    -- enable feature
    G.GAME.modifiers.DF_legendary_shop = true

    -- declare presence (rate is computed in main.lua)
    G.GAME.modifiers.DF_has_leg_sleeve = true
    
  end,
}

return {
  list = { legendaryshopdeck },
  sleeves = { legendaryshopsleeve },
}
