-- src/boosterpacks/divine_packs.lua
-- Divine Pack that spawns ONLY your custom item cards, with NO duplicates per pack.
-- Now with per-item WEIGHTS (lower = rarer).

-- EDIT THESE WEIGHTS:
-- Higher number = more likely to appear
-- 0 = never appears
local DIVINE_ITEM_WEIGHTS = {
  c_DF_rusted_sword      = 9,
  c_DF_rusted_shield     = 9,
  c_DF_prison_bottle     = 9,
  c_DF_reins_of_unity    = 9,
  c_DF_blizzard          = 3,
  c_DF_resurrect         = 1,

  c_DF_shaker_pokeball   = 10,
  c_DF_shaker_greatball  = 5,
  c_DF_shaker_ultraball  = 1,
  c_DF_shaker_masterball = 0.5,

  c_DF_divine_ball       = 0.1,
}

-- Convenience list (auto-generated from weights)
local DIVINE_ITEM_KEYS = {}
for k, _ in pairs(DIVINE_ITEM_WEIGHTS) do
  DIVINE_ITEM_KEYS[#DIVINE_ITEM_KEYS + 1] = k
end

local function DF_pick_divine_key(seed, seen)
  local candidates = {}
  local weights = {}

  for _, key in ipairs(DIVINE_ITEM_KEYS) do
    local full_key = key
    local w = DIVINE_ITEM_WEIGHTS[key] or 0

    if w > 0
      and G.P_CENTERS and G.P_CENTERS[full_key]
      and not (seen and seen[full_key])
    then
      candidates[#candidates + 1] = full_key
      weights[#weights + 1] = w
    end
  end

  if #candidates == 0 then return nil end

  -- Weighted roll using Balatro RNG
  local total = 0
  for i = 1, #weights do total = total + weights[i] end
  if total <= 0 then return nil end

  local r = pseudorandom(seed) * total
  local acc = 0
  for i = 1, #candidates do
    acc = acc + weights[i]
    if r <= acc then
      return candidates[i]
    end
  end

  -- fallback
  return candidates[#candidates]
end

local function create_divine_card(self, card, i)
  -- IMPORTANT: do NOT use card.ability.extra (it's a number for packs)
  card.ability = card.ability or {}
  card.ability._df_divine_seen = card.ability._df_divine_seen or {}
  local seen = card.ability._df_divine_seen

  local key = DF_pick_divine_key("divine_" .. tostring(i), seen)

  if key then
    seen[key] = true
    return SMODS.create_card {
      key = key,
      area = G.pack_cards,
      skip_materialize = true,
    }
  end

  -- If you ever increase extra above the number of available uniques,
  -- you'll run out of uniques; fallback to random Item.
  return SMODS.create_card {
    set = "Item",
    area = G.pack_cards,
    skip_materialize = true,
    soulable = true,
    key_append = "divine_fallback"
  }
end

local function divine_background(self)
  ease_colour(G.C.DYN_UI.MAIN, mix_colours(G.C.SECONDARY_SET.Spectral, G.C.BLACK, 0.85))
  ease_background_colour{ new_colour = G.C.BLACK, contrast = 3 }
end

local function divine_particles(self)
  G.booster_pack_stars = Particles(1, 1, 0, 0, {
    timer = 0.06,
    scale = 0.10,
    initialize = true,
    lifespan = 12,
    speed = 0.12,
    padding = -3,
    attach = G.ROOM_ATTACH,
    colours = { G.C.WHITE, G.C.PURPLE, G.C.BLUE },
    fill = true
  })
end

local divine_pack_1 = {
  name = "Divine Pack",
  key = "divinepack_normal_1",
  kind = "Divine",
  atlas = "AtlasBoosterpacksBasic",
  pos = { x = 0, y = 0 },

  config = { extra = 3, choose = 1 },

  cost = 20,
  order = 1,
  weight = 2,

  draw_hand = true,
  unlocked = true,
  discovered = true,

  create_card = create_divine_card,

  loc_vars = function(self, info_queue, card)
    return { vars = { card.config.center.config.choose, card.ability.extra - 1, 1 } }
  end,

  in_pool = function(self)
    return true
  end,

  ease_background_colour = divine_background,
  particles = divine_particles,

  group_key = "k_df_divine_pack",
}

local divine_pack_2 = {
  name = "Divine Pack",
  key = "divinepack_jumbo_1",
  kind = "Divine",
  atlas = "AtlasBoosterpacksBasic",
  pos = { x = 1, y = 0 },

  config = { extra = 5, choose = 1 },

  cost = 20,
  order = 1,
  weight = 1,

  draw_hand = true,
  unlocked = true,
  discovered = true,

  create_card = create_divine_card,

  loc_vars = function(self, info_queue, card)
    return { vars = { card.config.center.config.choose, card.ability.extra - 1, 1 } }
  end,

  in_pool = function(self)
    return true
  end,

  ease_background_colour = divine_background,
  particles = divine_particles,

  group_key = "k_df_divine_pack",
}

return {
  name = "Divine Packs",
  list = { divine_pack_1, divine_pack_2}
}