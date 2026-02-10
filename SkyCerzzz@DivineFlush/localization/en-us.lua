return {
  descriptions = {
    Joker = {
      j_DF_giratina = {
        name = "Giratina",
        text = {
          "When {C:attention}#2#{} {C:inactive}[#3#]{} {C:attention}#4#{} is defeated,",
          "destroy the rightmost {C:attention}Joker{}",
          "and create a {C:dark_edition}Negative{} copy",
          "{C:inactive}(Requirement increases by {C:attention}#5#{C:inactive} each time)",
          "{C:inactive,s:0.8}(Excludes Giratinas)",
        },
      },

      j_DF_arceus = {
        name = "Arceus",
        text = {
          "After defeating the {C:attention}Boss Blind{},",
          "create a {C:attention}Shaker Master Ball{}",
          "{C:inactive}(Must have room)",
          "{br:2}ERROR - CONTACT STEAK",
          "After defeating a {C:attention}Small{} or {C:attention}Big Blind{},",
          "generate a {C:attention}Divine Tag{}",
        },
      },

      j_DF_spectrier = {
        name = "Spectrier",
        text = {
          "Each {X:psychic,C:white}Psychic{} Joker gives {X:mult,C:white}X#1#{} Mult",
          "{br:2}ERROR - CONTACT STEAK",
          "After defeating the {C:attention}Boss Blind{},",
          "generate an {C:dark_edition}Ethereal{} {C:attention}Tag{}",
        },
      },

      j_DF_glastrier = {
        name = "Glastrier",
        text = {
          "All {C:attention}listed{} {C:green,E:1,S:1.1}probabilities{}",
          "are always {C:attention}0{}",
          "{br:2}ERROR - CONTACT STEAK",
          "The first {C:attention}#1#{C:inactive} [#2#]{} times a {C:attention}Glass{} card triggers",
          "each round, add a permanent {C:dark_edition}Polychrome{} copy to",
          "your deck and draw it to hand",
        },
      },

      j_DF_calyrex = {
        name = "Calyrex",
        text = {
          "Holds a {C:dark_edition}Negative{} {C:attention}Reins of Unity{}",
          "{br:2}ERROR - CONTACT STEAK",
          "Scored {C:attention}Kings{} without an",
          "{C:attention}Enhancement{} gain a {C:attention}random Seal{}",
          "and {C:attention}random Edition{}",
          "{br:2}ERROR - CONTACT STEAK",
          "If the scoring hand is a {C:attention}Flush{},",
          "retrigger all played cards with both",
          "a {C:attention}Seal{} and {C:attention}Edition{}",
        },
      },

      j_DF_calyrex_ice = {
        name = "Calyrex (Ice Rider)",
        text = {
          "Holds a {C:dark_edition}Negative{} {C:attention}Blizzard{}",
          "{br:2}ERROR - CONTACT STEAK",
          "Retrigger scoring {C:attention}Glass{} cards once",
          "per held {C:attention}Ice Stone{} or {C:attention}Blizzard{}",
          "{C:inactive}(Up to {C:attention}2{} {C:inactive}times)",
          "{br:2}ERROR - CONTACT STEAK",
          "All {C:attention}listed{} {C:green,E:1,S:1.1}probabilities{}",
          "are always {C:attention}0{}",
        },
      },

      j_DF_calyrex_shadow = {
        name = "Calyrex (Shadow Rider)",
        text = {
          "Holds a {C:dark_edition}Negative{} {C:attention}Resurrect{}",
          "{br:2}ERROR - CONTACT STEAK",
          "Each {X:psychic,C:white}Psychic{} Joker gives {X:mult,C:white}X#1#{} Mult",
          "{br:2}ERROR - CONTACT STEAK",
          "Retrigger scoring cards once for each",
          "{C:spectral}Spectral{} consumable or {C:attention}Resurrect{}",
          "{C:inactive}(Up to {C:attention}2{} {C:inactive}times)",
        },
      },

      j_DF_zacian = {
        name = "Zacian",
        text = {
          "{X:mult,C:white}X#1#{} Mult per triggered {C:attention}Rusted{} card",
          "{br:2}ERROR - CONTACT STEAK",
          "{C:green}#2# in #3#{} chance to turn each triggered",
          "{C:attention}Steel{} card {C:attention}Rusted{}",
          "{br:2}ERROR - CONTACT STEAK",
          "{C:green}#4# in #5#{} chance to add {C:dark_edition}Polychrome{}",
          "to each triggered {C:attention}Rusted{} card",
        },
      },

      j_DF_zacian_crowned = {
        name = "Zacian (Crowned)",
        text = {
          "{X:mult,C:white}X#2#{} Mult per triggered {C:attention}Crowned{} card",
          "{br:2}ERROR - CONTACT STEAK",
          "{C:green}#3# in #4#{} chance to turn each triggered",
          "{C:attention}Steel{} card {C:attention}Rusted{}",
          "{C:green}#5# in #6#{} chance if already {C:attention}Rusted{} to turn it {C:attention}Crowned{}",
          "{br:2}ERROR - CONTACT STEAK",
          "Retrigger each triggered {C:attention}Rusted{} or {C:attention}Crowned{} card",
          "{C:green}#7# in #8#{} chance to retrigger a {C:attention}second{} time",
          "{br:2}ERROR - CONTACT STEAK",
          "If you have {C:attention}Crowned Zamazenta{}, all chances are {C:attention}guaranteed{}",
        },
      },

      j_DF_zamazenta = {
        name = "Zamazenta",
        text = {
          "All cards and {C:attention}Jokers{} cannot be {C:attention}debuffed{}",
          "{br:2}ERROR - CONTACT STEAK",
          "{C:green}#1# in #2#{} chance to turn each triggered",
          "{C:attention}Steel{} card {C:attention}Rusted{}",
          "{br:2}ERROR - CONTACT STEAK",
          "{C:green}#3# in #4#{} chance to add a {C:red}Red Seal{}",
          "to each triggered {C:attention}Rusted{} card",
          "{br:2}ERROR - CONTACT STEAK",
          "If you have {C:attention}Zacian{}, all chances are {C:attention}guaranteed{}",
        },
      },

      j_DF_zamazenta_crowned = {
        name = "Zamazenta (Crowned)",
        text = {
          "All cards and {C:attention}Jokers{} cannot be {C:attention}debuffed{}",
          "{br:2}ERROR - CONTACT STEAK",
          "Earn {C:money}$#1#{} per scored {C:attention}Crowned{} card",
          "{C:green}#2# in #3#{} chance to double it",
          "{br:2}ERROR - CONTACT STEAK",
          "{C:green}#4# in #5#{} chance to add {C:red}Red Seal{}",
          "or {C:dark_edition}Polychrome{} to triggered {C:attention}Rusted{} cards",
          "{C:green}#6# in #7#{} chance if it is {C:attention}Crowned{}",
          "{br:2}ERROR - CONTACT STEAK",
          "If you have {C:attention}Crowned Zacian{}, all chances are {C:attention}guaranteed{}",
        },
      },

      j_DF_wo_chien = {
        name = "Wo-Chien",
        text = {
          "The first time a {C:attention}Lucky{} card is scored each round,",
          "add a {C:red}Red Seal{} to the {C:attention}leftmost{} card in the played hand",
          "{br:2}ERROR - CONTACT STEAK",
          "Retrigger all {C:spades}Spade{} cards",
        },
      },

      j_DF_chi_yu = {
        name = "Chi-Yu",
        text = {
          "The first time a {C:attention}Mult{} card is scored each round,",
          "add a {C:red}Red Seal{} to the {C:attention}leftmost{} card in the played hand",
          "{br:2}ERROR - CONTACT STEAK",
          "Retrigger all {C:hearts}Heart{} cards",
        },
      },

      j_DF_ting_lu = {
        name = "Ting-Lu",
        text = {
          "The first time a {C:attention}Stone{} card is scored each round,",
          "add a {C:red}Red Seal{} to the {C:attention}leftmost{} card in the played hand",
          "{br:2}ERROR - CONTACT STEAK",
          "Retrigger all {C:clubs}Club{} cards",
        },
      },

      j_DF_chien_pao = {
        name = "Chien-Pao",
        text = {
          "The first time a {C:attention}Glass{} card is scored each round,",
          "add a {C:red}Red Seal{} to the {C:attention}leftmost{} card in the played hand",
          "{br:2}ERROR - CONTACT STEAK",
          "Retrigger all {C:diamonds}Diamond{} cards",
        },
      },

      j_DF_hoopa = {
        name = "Hoopa",
        text = {
          "{X:mult,C:white}X#1#{} Mult per {C:attention}Legendary Joker{} you have",
          "{br:2}ERROR - CONTACT STEAK",
          "{C:green}#2#%{} chance to create a {C:attention}Legendary Joker{}",
          "when a {C:attention}Legendary Joker{} is {C:attention}sold{}",
          "{C:inactive}(Chance increases with Legendary Deck/Sleeve)",
        },
      },

      j_DF_hoopa_unbound = {
        name = "Hoopa (Unbound)",
        text = {
          "{X:mult,C:white}X#1#{} Mult per {C:attention}Legendary Joker{} and {C:blue}Divine{}{C:attention} Joker{} you have",
          "{br:2}ERROR - CONTACT STEAK",
          "{C:green}#2#%{} chance to create a {C:attention}Legendary Joker{}",
          "when the {C:attention}Blind{} is {C:attention}defeated{}",
          "{C:inactive}(Chance increases with Legendary Deck/Sleeve)",
          "{C:inactive}(If using both, Boss Blind spawn is guaranteed)",
        },
      },
    },

    Back = {
  b_DF_zaciandeck = {
    name = "Zacian Deck",
    text = {
      "Start the run with {C:attention}Zacian{}",
    },
  },

  b_DF_zamazentadeck = {
    name = "Zamazenta Deck",
    text = {
      "Start the run with {C:attention}Zamazenta{}",
    },
  },

  b_DF_legendaryshopdeck = {
    name = "Legendary Shop Deck",
    text = {
      "{C:green}#1#%{} chance for {C:attention}Shops{}",
      "to contain a {C:attention}Legendary{}",
    },
  },
},

Sleeve = {
  sleeve_DF_zaciansleeve = {
    name = "Zacian Sleeve",
    text = {
      "Start the run with a {C:attention}Rusted Sword{}",
    },
  },

  sleeve_DF_zaciansleeve_alt = {
    name = "Divine Zacian Sleeve",
    text = {
      "Start the run with a {C:attention}Rusted Sword{}",
      "{br:2}ERROR - CONTACT STEAK",
      "Start the run with a {C:attention}Master Ball{}",
    },
  },

  sleeve_DF_zamazentasleeve = {
    name = "Zamazenta Sleeve",
    text = {
      "Start the run with a {C:attention}Rusted Shield{}",
    },
  },

  sleeve_DF_zamazentasleeve_alt = {
    name = "Divine Zamazenta Sleeve",
    text = {
      "Start the run with a {C:attention}Rusted Shield{}",
      "{br:2}ERROR - CONTACT STEAK",
      "Start the run with a {C:attention}Master Ball{}",
    },
  },

  sleeve_DF_legendaryshopsleeve = {
    name = "Legendary Shop Sleeve",
    text = {
      "{C:green}#1#%{} chance for {C:attention}Shops{}",
      "to contain a {C:attention}Legendary{}",
    },
  },

  sleeve_DF_legendaryshopsleeve_alt = {
    name = "Divine Legendary Shop Sleeve",
    text = {
      "{C:green}#1#%{} chance for {C:attention}Shops{}",
      "to contain a {C:attention}Legendary{}",
    },
  },
},

    Divine = {
      -- Rusted / Crowned items
      c_DF_rusted_sword = {
  name = "Rusted Sword",
  text = {
    "{C:attention}Once per round{}",
    "{br:2}ERROR - CONTACT STEAK",
    "Select {C:attention}Zacian{} to evolve into",
    "{C:attention}Zacian (Crowned){}, then becomes",
    "{C:attention}Crowned Sword{}",
    "{br:2}ERROR - CONTACT STEAK",
    "You may select up to {C:attention}1{} card to make it {C:attention}Rusted{}",
    "If already {C:attention}Rusted{}, {C:green}1 in 2{} chance",
    "to add {C:dark_edition}Polychrome{}",
  },
},

      c_DF_crowned_sword = {
        name = "Crowned Sword",
        text = {
          "{C:attention}Held{} item",
          "{br:2}ERROR - CONTACT STEAK",
          "{C:attention}Once per Blind{}:",
          "Select up to {C:attention}2{} cards in hand",
          "Turn them into {C:attention}Crowned{}",
          "If already {C:attention}Crowned{}, add {C:dark_edition}Polychrome{}",
          "{br:2}ERROR - CONTACT STEAK",
          "If {C:attention}Zacian (Crowned){} retriggers",
          "{C:attention}10{} {C:attention}Crowned{} cards this Blind,",
          "gain {X:mult,C:white}+0.15{} {C:attention}X Mult{} scaling",
          "{C:inactive}(max 4 times this Run)",
          "{br:2}ERROR - CONTACT STEAK",
          "If {C:attention}Zacian (Crowned){} is gone,",
          "this item {C:red}self-destructs{}",
          "{br:2}ERROR - CONTACT STEAK",
          "{C:attention}Selling{} this item reverts",
          "{C:attention}Zacian (Crowned){} back into {C:attention}Zacian{}",
        },
      },

      c_DF_rusted_shield = {
  name = "Rusted Shield",
  text = {
    "{C:attention}Once per round{}",
    "{br:2}ERROR - CONTACT STEAK",
    "Select {C:attention}Zamazenta{} to evolve into",
    "{C:attention}Zamazenta (Crowned){}, then becomes",
    "{C:attention}Crowned Shield{}",
    "{br:2}ERROR - CONTACT STEAK",
    "You may select up to {C:attention}1{} card to make it {C:attention}Rusted{}",
    "If already {C:attention}Rusted{}, {C:green}1 in 2{} chance",
    "to add a {C:red}Red Seal{}",
  },
},

      c_DF_crowned_shield = {
        name = "Crowned Shield",
        text = {
          "{C:attention}Held{} item",
          "{br:2}ERROR - CONTACT STEAK",
          "{C:attention}Once per Blind{}:",
          "Select up to {C:attention}2{} cards in hand to",
          "turn them into {C:attention}Crowned{}",
          "If already {C:attention}Crowned{}, add a {C:red}Red Seal{}",
          "{br:2}ERROR - CONTACT STEAK",
          "If {C:attention}Zamazenta (Crowned){} earns",
          "{C:money}$50{} this Blind, increase its",
          "Crowned payout by {C:money}+$1{}",
          "{C:inactive}(max 2 times this Run)",
          "{br:2}ERROR - CONTACT STEAK",
          "If {C:attention}Zamazenta (Crowned){} is gone,",
          "this item {C:red}self-destructs{}",
          "{br:2}ERROR - CONTACT STEAK",
          "{C:attention}Selling{} this item reverts",
          "{C:attention}Zamazenta (Crowned){} back into {C:attention}Zamazenta{}",
        },
      },

      -- Shaker Balls + Divine Ball
      c_DF_shaker_pokeball = {
        name = "Shaker Poké Ball",
        text = {
          "Use: {C:attention}Basic{} Joker",
          "{br:2}ERROR - CONTACT STEAK",
          "Shake: {C:green}75%{} to become",
          "{C:attention}Shaker Great Ball{}",
          "{C:red}Otherwise: Shatters{}",
        },
      },

      c_DF_shaker_greatball = {
        name = "Shaker Great Ball",
        text = {
          "Use: {C:attention}Stage 1{} Joker",
          "{br:2}ERROR - CONTACT STEAK",
          "Shake: {C:green}50%{} to become",
          "{C:attention}Shaker Ultra Ball{}",
          "{C:red}Otherwise: Shatters{}",
        },
      },

      c_DF_shaker_ultraball = {
        name = "Shaker Ultra Ball",
        text = {
          "Use: {C:attention}Stage 2{} Joker",
          "{br:2}ERROR - CONTACT STEAK",
          "Shake: {C:green}20%{} to become",
          "{C:attention}Shaker Master Ball{}",
          "{C:red}Otherwise: Shatters{}",
        },
      },

      c_DF_shaker_masterball = {
        name = "Shaker Master Ball",
        text = {
          "Use: {C:attention}Legendary{} Joker",
          "{br:2}ERROR - CONTACT STEAK",
          "Shake: {C:green}10%{} to become",
          "{C:attention}Divine Ball{}",
          "{C:red}Otherwise: Shatters{}",
        },
      },

      c_DF_divine_ball = {
        name = "Divine Ball",
        text = {
          "Use: {C:attention}Divine{} Joker",
        },
      },

      -- Reins of Unity
      c_DF_reins_of_unity = {
        name = "Reins of Unity",
        text = {
          "{C:attention}One use{}",
          "{br:2}ERROR - CONTACT STEAK",
          "If you have {C:attention}Calyrex{} and",
          "{C:attention}Glastrier{}, fuse into",
          "{C:attention}Calyrex Ice{} and gain",
          "{C:attention}2{} {C:dark_edition}Negative{} {C:attention}Ice Stones{}",
          "{br:2}ERROR - CONTACT STEAK",
          "If you have {C:attention}Calyrex{} and",
          "{C:attention}Spectrier{}, fuse into",
          "{C:attention}Calyrex Shadow{} and gain",
          "{C:attention}2{} {C:dark_edition}Negative{} {C:attention}Spectral{} cards",
          "{br:2}ERROR - CONTACT STEAK",
          "{C:inactive}(The mount is consumed)",
        },
      },

      -- Prison Bottle
      c_DF_prison_bottle = {
        name = "Prison Bottle",
        text = {
          "{C:attention}Held{} item",
          "{br:2}ERROR - CONTACT STEAK",
          "{C:attention}Use{}: Transform {C:attention}Hoopa{} into",
          "{C:attention}Hoopa Unbound{} (and back)",
          "{C:attention}Once per turn{}",
          "{br:2}ERROR - CONTACT STEAK",
          "{C:green}20%{} chance each use to create a",
          "{C:attention}Legendary Joker{}",
        },
      },

      c_DF_blizzard = {
        name = "Blizzard",
        text = {
          "Turn {C:green}50%{} of cards in hand into {C:attention}Glass{}",
          "{br:2}ERROR - CONTACT STEAK",
          "{C:green}30%{} chance to gain a {C:attention}Divine item{}",
          "{C:inactive}(Only if you have Calyrex (Ice))",
          "{br:2}ERROR - CONTACT STEAK",
          "{C:attention}Status:{} #1#",
          "{C:attention}Rounds until ready:{} #2#",
          "{C:inactive}(Requires visible hand)",
          "{C:inactive}(If no Calyrex (Ice), this shatters after use)",
        },
      },

      c_DF_resurrect = {
        name = "Resurrect",
        text = {
          "{C:attention}Passive:{} Prevent losing a Blind",
          "{br:2}ERROR - CONTACT STEAK",
          "{C:green}30%{} chance to gain a {C:attention}Divine item{}",
          "{br:2}ERROR - CONTACT STEAK",
          "{C:attention}Status:{} #1#",
          "{C:attention}Rounds until ready:{} #2#",
          "{C:inactive}(If no Calyrex (Shadow), it shatters after use)",
        },
      },
    },

    Enhanced = {
      m_DF_rusted = {
        name = "Rusted",
        text = {
          "While held:",
          "Base {X:mult,C:white}X1{}",
          "{X:mult,C:white}+0.1{} per {C:attention}Steel Joker{}",
          "{X:mult,C:white}+0.2{} per {C:attention}Zacian{} / {C:attention}Zamazenta{}",
        },
      },

      m_DF_crowned = {
        name = "Crowned",
        text = {
          "Gain {C:money}$3{} when created",
          "{br:2}ERROR - CONTACT STEAK",
          "If you have {C:attention}Crowned Zacian{},",
          "gives {X:mult,C:white}X1.5{} Mult when scored",
          "{br:2}ERROR - CONTACT STEAK",
          "If you have {C:attention}Crowned Zamazenta{},",
          "gives {X:mult,C:white}X1.5{} Mult while held",
          "{C:inactive}(Both can apply at once)",
        },
      },
    },

    Tag = {
      tag_DF_divine_pack_tag = {
        name = "Divine Tag",
        text = {
          "Gives a free {C:blue}Divine{}{C:attention} Pack{}",
        },
      },
    },

    Other = {
      p_DF_divinepack_normal_1 = {
        name = "Divine Pack",
        text = {
          "Choose {C:attention}1{} from among",
          "{C:attention}3{}{C:blue} Divine{}{C:item} Item{} Cards",
        },
      },

      p_DF_divinepack_jumbo_1 = {
        name = "Divine Jumbo Pack",
        text = {
          "Choose {C:attention}1{} from among",
          "{C:attention}5{}{C:blue} Divine{}{C:item} Item{} Cards",
        },
      },
    },
  },

  misc = {
    challenge_names = {
    },

    dictionary = {
      -- Rarities
      k_df_divine = "Divine",
      k_df_divine_pack = "Divine Pack",
      k_df_divine_tag = "Divine Tag",

      DF_treasures_of_ruin = "Treasures of Ruin",

      -- Enhancements
      k_df_rusted = "Rusted",
      k_df_crowned = "Crowned",

      m_DF_rusted = "Rusted",
      m_DF_crowned = "Crowned",

      -- Plurals/singulars
      cards_singular = "card",
      cards_plural = "cards",

      joker_singular = "Joker",
      joker_plural = "Jokers",

      boss_blind_singular = "Boss Blind",
      boss_blind_plural = "Boss Blinds",

      DF_turns_left_plural = "hands left",
      DF_turns_left_singular = "hand left",

      -- Settings
      DF_leg_pokemon1 = "Legendary Pokémon 1/1",
      DF_div_pokemon1 = "Divine Pokémon 1/1",
    },

    labels = {
      k_df_divine = "Divine",
      k_df_rusted = "Rusted",
      k_df_crowned = "Crowned",
    },
  },
}
