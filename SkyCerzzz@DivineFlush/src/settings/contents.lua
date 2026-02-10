-- src/jokerdisplay/content/df_legendaries.lua
---@format disable
return {
  pages = {
    {
      title = function() return localize("DF_leg_pokemon1") end,
      tiles = {
        -- Glastrier + Spectrier (group)
        { list = { "j_DF_glastrier" }, label = function() return localize { type = "name_text", set = "Joker", key = "j_DF_glastrier" } end, config_key = "glastrier" },
        { list = { "j_DF_spectrier" }, label = function() return localize { type = "name_text", set = "Joker", key = "j_DF_spectrier" } end, config_key = "spectrier" },
        -- Treasures of Ruin (group)
        { list = { "j_DF_wo_chien", "j_DF_chien_pao", "j_DF_ting_lu", "j_DF_chi_yu" }, label = function() return localize("DF_treasures_of_ruin") end, config_key = "treasures_of_ruin" },
      }
    },
    {
      title = function() return localize("DF_div_pokemon1") end,
      tiles = {
        -- Singles
        { list = { "j_DF_giratina" }, label = function() return localize { type = "name_text", set = "Joker", key = "j_DF_giratina" } end, config_key = "giratina" },
        { list = { "j_DF_arceus" }, label = function() return localize { type = "name_text", set = "Joker", key = "j_DF_arceus" } end, config_key = "arceus" },

        -- Hoopa + Hoopa Unbound (group)
        { list = { "j_DF_hoopa", "j_DF_hoopa_unbound" }, label = function() return localize { type = "name_text", set = "Joker", key = "j_DF_hoopa" } end, config_key = "hoopa" },

        -- Zacian + Zacian Crowned (group)
        { list = { "j_DF_zacian", "j_DF_zacian_crowned" }, label = function() return localize { type = "name_text", set = "Joker", key = "j_DF_zacian" } end, config_key = "zacian" },

        -- Zamazenta + Zamazenta Crowned (group)
        { list = { "j_DF_zamazenta", "j_DF_zamazenta_crowned" }, label = function() return localize { type = "name_text", set = "Joker", key = "j_DF_zamazenta" } end, config_key = "zamazenta" },

        -- Calyrex + Ice + Shadow (group)
        { list = { "j_DF_calyrex", "j_DF_calyrex_ice", "j_DF_calyrex_shadow" }, label = function() return localize { type = "name_text", set = "Joker", key = "j_DF_calyrex" } end, config_key = "calyrex" },
      }
    },
  }
}