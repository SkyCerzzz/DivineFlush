SMODS.Atlas({
    key = "modicon",
    path = "icon.png",
    px = 32,
    py = 32
})

SMODS.Atlas({
    key = "DFBacks",
    path = "backs.png",
    px = 71,
    py = 95
})

SMODS.Atlas({
    key = "DFSleeves",
    path = "sleeves.png",
    px = 71,
    py = 95
})

SMODS.Atlas({
    key = "DFConsumables",
    path = "consumables.png",
    px = 71,
    py = 95
})

SMODS.Atlas({
    key = "AtlasBoosterpacksBasic",
    path = "AtlasBoosterpacksBasic.png",
    px = 71,
    py = 95
})

SMODS.Atlas({
    key = "DF_AtlasConsumablesBasic",
    path = "AtlasConsumablesBasic.png",
    px = 71,
    py = 95
})


SMODS.Atlas({ 
    key = "DivineFlushAtlasGen4", 
    path= "AtlasGen04.png", 
    px=71, 
    py=95 
})

SMODS.Atlas({ 
    key = "shiny_DivineFlushAtlasGen4", 
    path= "AtlasGen04Shiny.png", 
    px=71, 
    py=95 
})

SMODS.Atlas({ 
    key = "DivineFlushAtlasGen6", 
    path= "AtlasGen06.png", 
    px=71, 
    py=95 
})

SMODS.Atlas({ 
    key = "shiny_DivineFlushAtlasGen6", 
    path= "AtlasGen06Shiny.png", 
    px=71, 
    py=95 
})

SMODS.Atlas({ 
    key = "DivineFlushAtlasGen8", 
    path= "Gen08Jokers.png", 
    px=71, 
    py=95 
})

SMODS.Atlas({ 
    key = "shiny_DivineFlushAtlasGen8", 
    path= "Gen08Shiny.png", 
    px=71, 
    py=95 
})

SMODS.Atlas({ 
    key = "DF_tags", 
    path= "AtlasTags.png", 
    px = 34,
    py = 34
})

SMODS.Atlas({
    key = "DF_Enhancements",
    path = "AtlasEnhancementsBasic.png",
    px = 71,
    py = 95,
})

local DFclubs = SMODS.Atlas{
  key = 'DivineFlushClubs',
  path = 'DivineFlushClubs.png',
  px = 71,
  py = 95,
  atlas_table = 'ASSET_ATLAS'
}

local DFspades = SMODS.Atlas{
  key = 'DivineFlushSpades',
  path = 'DivineFlushSpades.png',
  px = 71,
  py = 95,
  atlas_table = 'ASSET_ATLAS'
}

local DFdiamonds = SMODS.Atlas{
  key = 'DivineFlushDiamonds',
  path = 'DivineFlushDiamonds.png',
  px = 71,
  py = 95,
  atlas_table = 'ASSET_ATLAS'
}

local DFhearts = SMODS.Atlas{
  key = 'DivineFlushHearts',
  path = 'DivineFlushHearts.png',
  px = 71,
  py = 95,
  atlas_table = 'ASSET_ATLAS'
}

local DF_LOC = { ['en-us'] = 'DF Sprites: Divine Ball' }

-- FULL names (important for your Steamodded build)
-- If you added Ace art, include it here:
local DF_RANKS   = { 'Jack', 'Queen', 'King', 'Ace' }

--------------------------------------------------------
-- SPADES
--------------------------------------------------------
SMODS.DeckSkin{
  key = "DF_Spades_Skins",
  suit = "Spades",
  loc_txt = DF_LOC,
  palettes = {
    {
      key = 'lc',
      ranks = DF_RANKS,
      display_ranks = DF_RANKS,
      atlas = DFspades.key,
      pos_style = 'ranks',
      lc_default = true,
    },
  },
}

--------------------------------------------------------
-- CLUBS
--------------------------------------------------------
SMODS.DeckSkin{
  key = "DF_Clubs_Skins",
  suit = "Clubs",
  loc_txt = DF_LOC,
  palettes = {
    {
      key = 'lc',
      ranks = DF_RANKS,
      display_ranks = DF_RANKS,
      atlas = DFclubs.key,
      pos_style = 'ranks',
      lc_default = true,
    },
  },
}

--------------------------------------------------------
-- HEARTS
--------------------------------------------------------
SMODS.DeckSkin{
  key = "DF_Hearts_Skins",
  suit = "Hearts",
  loc_txt = DF_LOC,
  palettes = {
    {
      key = 'lc',
      ranks = DF_RANKS,
      display_ranks = DF_RANKS,
      atlas = DFhearts.key,
      pos_style = 'ranks',
      lc_default = true,
    },
  },
}

--------------------------------------------------------
-- DIAMONDS
--------------------------------------------------------
SMODS.DeckSkin{
  key = "DF_Diamonds_Skins",
  suit = "Diamonds",
  loc_txt = DF_LOC,
  palettes = {
    {
      key = 'lc',
      ranks = DF_RANKS,
      display_ranks = DF_RANKS,
      atlas = DFdiamonds.key,
      pos_style = 'ranks',
      lc_default = true,
    },
  },
}
