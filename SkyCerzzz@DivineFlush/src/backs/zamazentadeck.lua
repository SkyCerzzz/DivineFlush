-- zamazentadeck.lua

local zamazentadeck = {
  name = "zamazentadeck",
  key = "zamazentadeck",
  atlas = "DFBacks",
  pos = { x = 1, y = 0 },

  config = {},

  loc_vars = function(self)
    return { vars = {} }
  end,

  apply = function(self)
    -- Give Zamazenta at run start (needs an event so areas exist)
    G.E_MANAGER:add_event(Event({
      func = function()
        if SMODS and SMODS.add_card then
          SMODS.add_card({ key = "j_DF_zamazenta" })
        end
        return true
      end
    }))
  end,
}

local zamazentasleeve = {
  name = "zamazentasleeve",
  key = "zamazentasleeve",
  atlas = "DFSleeves",
  pos = { x = 1, y = 0 },

  config = {},

  loc_vars = function(self)
    local loc_key = self.key
    if self.get_current_deck_key and self:get_current_deck_key() == "b_DF_zamazentadeck" then
      loc_key = loc_key .. "_alt"
    end
    return { key = loc_key, vars = {} }
  end,

  apply = function(self)
    CardSleeves.Sleeve.apply(self)

    G.E_MANAGER:add_event(Event({
      func = function()
        if SMODS and SMODS.add_card then
          -- Sleeve always gives the item
          SMODS.add_card({ key = "c_DF_rusted_shield" })

          -- Only paired setup (alt sleeve) gives Master Ball too
          if self.get_current_deck_key and self:get_current_deck_key() == "b_DF_zamazentadeck" then
            SMODS.add_card({ key = "c_poke_masterball" })
          end
        end
        return true
      end
    }))
  end,
}

return {
  list = { zamazentadeck },
  sleeves = { zamazentasleeve },
}
