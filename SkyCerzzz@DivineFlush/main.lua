DF = {}

divineflush_config = SMODS.current_mod.config

SMODS.current_mod.optional_features = {
  retrigger_joker = true,
  quantum_enhancements = true,
}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------
local function DF_is_legendary_center(center)
  if type(center) ~= "table" then return false end
  if center.set ~= "Joker" then return false end
  if center.aux_poke then return false end

  local stage = center.stage
  if not stage and type(center.config) == "table" then stage = center.config.stage end
  return stage == "Legendary"
end

local function DF_flag_on()
  return (G and G.GAME and G.GAME.modifiers and G.GAME.modifiers.DF_legendary_shop) == true
end

local function DF_get_rate()
  if not (G and G.GAME and G.GAME.modifiers) then return 0.005 end
  local r = G.GAME.modifiers.DF_legendary_rate
  if type(r) ~= "number" then return 0.005 end
  if r < 0 then r = 0 end
  if r > 1 then r = 1 end
  return r
end

-- anti-repeat memory
local function DF_seen_init()
  if not (G and G.GAME) then return end
  G.GAME.DF_seen_legendaries = G.GAME.DF_seen_legendaries or {}
  G.GAME.DF_seen_legendary_queue = G.GAME.DF_seen_legendary_queue or {}
end

local function DF_seen_add(key)
  if not (G and G.GAME) then return end
  DF_seen_init()
  if G.GAME.DF_seen_legendaries[key] then return end

  G.GAME.DF_seen_legendaries[key] = true
  table.insert(G.GAME.DF_seen_legendary_queue, key)

  local N = 12
  while #G.GAME.DF_seen_legendary_queue > N do
    local old = table.remove(G.GAME.DF_seen_legendary_queue, 1)
    if old then G.GAME.DF_seen_legendaries[old] = nil end
  end
end

local function DF_is_owned_joker_key(key)
  if not (G and G.jokers and G.jokers.cards) then return false end
  for _, c in pairs(G.jokers.cards) do
    if c and c.config and c.config.center and c.config.center.key == key then
      return true
    end
  end
  return false
end

local function DF_get_legendary_keys_for_pool()
  local keys = {}
  if not (G and G.P_CENTERS and G.GAME) then return keys end
  DF_seen_init()

  for key, center in pairs(G.P_CENTERS) do
    if DF_is_legendary_center(center) and type(key) == "string" then
      if G.GAME.banned_keys and G.GAME.banned_keys[key] then goto continue end
      if DF_is_owned_joker_key(key) then goto continue end
      if G.GAME.used_jokers and G.GAME.used_jokers[key] then goto continue end
      if G.GAME.DF_seen_legendaries and G.GAME.DF_seen_legendaries[key] then goto continue end

      local ok = true
      if type(center.in_pool) == "function" then
        ok = center:in_pool()
      end

      if ok then
        keys[#keys + 1] = key
      end
    end
    ::continue::
  end

  return keys
end

----------------------------------------------------------------
-- Pool patch: "true rare-like chance per Joker roll"
----------------------------------------------------------------
function DF.patch_shop_pool_for_legendaries()
  if DF._pool_wrapped then return end
  if type(get_current_pool) ~= "function" then
    print("[DF] get_current_pool not found; can't hook.")
    return
  end

  DF._pool_wrapped = true
  local old_get_current_pool = get_current_pool

  get_current_pool = function(_type, _rarity, _legendary, _append, ...)
    local pool, pool_key = old_get_current_pool(_type, _rarity, _legendary, _append, ...)

    if DF_flag_on() and _type == "Joker" and type(pool) == "table" then
      local LEG_RATE = DF_get_rate()

      local r = (pseudorandom and pseudorandom("DF_leg_rate")) or math.random()
      if r < LEG_RATE then
        local leg_pool = DF_get_legendary_keys_for_pool()
        if #leg_pool > 0 then
          -- Force this one roll to be legendary (no weights, independent of pool size)
          pool = leg_pool

          -- mark one as seen to reduce repeat chains
          local pick = pool[math.random(#pool)]
          DF_seen_add(pick)
        end
      end
    end

    return pool, pool_key
  end

  print("[DF] wrapped get_current_pool for legendary rate")
end

----------------------------------------------------------------
-- Normal DF loading
----------------------------------------------------------------
assert(SMODS.load_file("src/sprites.lua"))()
assert(SMODS.load_file("src/rarities.lua"))()

local load_directory, l = assert(SMODS.load_file("src/loader.lua"))()

load_directory("src/functions")
load_directory("src/pokemon", l.load_pokemon, { post_load = l.load_pokemon_family })
load_directory("src/consumables", function(a) SMODS.Consumable(a) end)
load_directory("src/boosters", function(a) SMODS.Booster(a) end)
load_directory("src/tags", function(a) SMODS.Tag(a) end)
load_directory("src/consumable types", function(a) SMODS.ConsumableType(a) end)
load_directory("src/enhancements", function(a) SMODS.Enhancement(a) end)
load_directory("src/backs", function(a) SMODS.Back(a) end, { post_load = l.load_sleeves })
load_directory("src/challenges", function(a)
  a.button_colour = HEX("F792BC")
  SMODS.Challenge(a)
end)

assert(SMODS.load_file("src/settings.lua"))()

if (SMODS.Mods["JokerDisplay"] or {}).can_load then
  assert(SMODS.load_file("src/jokerdisplay.lua"))()
end

----------------------------------------------------------------
-- Hooks
----------------------------------------------------------------
DF.hookbeforefunc(SMODS.current_mod, 'reset_game_globals', function(run_start)
  if run_start then
    for _, center in pairs(G.P_CENTERS) do
      if center.DF_config_key and not divineflush_config[center.DF_config_key] then
        G.GAME.banned_keys[center.key] = true
      end
    end
  end
end)

DF.hookafterfunc(SMODS.current_mod, 'reset_game_globals', function(run_start)
  if not (G and G.GAME) then return end
  G.GAME.modifiers = G.GAME.modifiers or {}

  local has_deck   = G.GAME.modifiers.DF_has_leg_deck == true
  local has_sleeve = G.GAME.modifiers.DF_has_leg_sleeve == true

  local rate = 0.000 -- fallback default when neither is active
  if has_deck or has_sleeve then
    rate = 0.005
  end
  if has_deck and has_sleeve then
    rate = 0.025
  end

  G.GAME.modifiers.DF_legendary_rate = rate

  DF.patch_shop_pool_for_legendaries()
  
end)
