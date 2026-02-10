-- src/consumables/XX_shaker_balls.lua
-- Shaker Ball chain with matching "real ball" effects on use:
-- shaker_pokeball -> (shake/drag) -> shaker_greatball -> shaker_ultraball -> shaker_masterball -> divine_ball

local DF = DF or {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------
local function DF_set_consumable_center(consumable_card, new_center_key)
  if not (consumable_card and new_center_key) then return false end
  if not (G and G.P_CENTERS and G.P_CENTERS[new_center_key]) then return false end
  local new_center = G.P_CENTERS[new_center_key]
  consumable_card:set_ability(new_center, true)
  if consumable_card.set_cost then consumable_card:set_cost() end
  consumable_card:juice_up(0.4, 0.4)
  return true
end

local function DF_setup_drag_transform(self, card, forced_center_key)
  local shake_rqmt = (self and self.config and self.config.shake_rqmt) or 25
  local upgrade_chance = (self and self.config and self.config.upgrade_chance) or 1

  -- Ensure ability tables exist
  card.ability = card.ability or {}
  card.ability.extra = card.ability.extra or {}
  local ex = card.ability.extra

  -- Store per-card settings
  ex._df_next_center_key   = forced_center_key
  ex._df_shake_rqmt        = shake_rqmt
  ex._df_upgrade_chance    = upgrade_chance

  -- Init shake state
  ex.prev_drag_x = ex.prev_drag_x or 0
  ex.prev_drag_y = ex.prev_drag_y or 0
  ex.dist_dragged = ex.dist_dragged or 0

  -- Locks / flags
  ex._df_shake_locked = ex._df_shake_locked or false
  ex._df_forced_snap = ex._df_forced_snap or false
  ex._df_block_until_release = ex._df_block_until_release or false

  -- Helper: is LMB currently down?
  local function lmb_down()
    local ok, down = pcall(function()
      return love and love.mouse and love.mouse.isDown and love.mouse.isDown(1)
    end)
    return ok and down
  end

  -- Helper: roll chance (tries to use Balatro pseudorandom if present)
  local function roll_chance(ch)
    if ch >= 1 then return true end
    if ch <= 0 then return false end

    -- If pseudorandom exists, use it (more consistent with Balatro RNG)
    if type(pseudorandom) == "function" then
      -- pseudorandom() in Balatro typically returns [0,1)
      local r = pseudorandom("DF_shaker_upgrade")
      return r < ch
    end

    -- fallback
    return math.random() < ch
  end

  -- Helper: shatter the card
  local function shatter_card(c)
    if not c then return end

    if card_eval_status_text then
      card_eval_status_text(c, 'extra', nil, nil, nil, { message = "Shattered!", colour = G.C.RED })
    end

    -- Prefer dissolve/destroy visuals if available
    if c.start_dissolve then
      pcall(function() c:start_dissolve(nil, true) end)
      return
    end

    -- Fallback hard-remove (best effort)
    pcall(function()
      if c.remove_from_deck then c:remove_from_deck() end
      if c.area and c.area.remove_card then c.area:remove_card(c) end
      if c.remove then c:remove() end
    end)
  end

  -- Wrap drag ONLY ONCE
  if not ex._df_drag_wrapped then
    ex._df_drag_wrapped = true

    local card_drag_orig = card.drag
    card.drag = function(cself, offset)
      if card_drag_orig then card_drag_orig(cself, offset) end
      if not (card and card.ability) then return end

      card.ability.extra = card.ability.extra or {}
      local ex2 = card.ability.extra

      -- HARD BLOCK: already transformed (or shattered attempt) during this mouse-hold
      if ex2._df_block_until_release then return end

      local next_key = ex2._df_next_center_key
      local rqmt = ex2._df_shake_rqmt or 25
      local ch = ex2._df_upgrade_chance or 1
      if not next_key then return end

      if ex2._df_shake_locked then return end

      if ex2.prev_drag_x == 0 then ex2.prev_drag_x = cself.T.x end
      if ex2.prev_drag_y == 0 then ex2.prev_drag_y = cself.T.y end

      local x1, y1 = ex2.prev_drag_x, ex2.prev_drag_y
      local x2, y2 = cself.T.x, cself.T.y
      local distance = math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)

      ex2.prev_drag_x = x2
      ex2.prev_drag_y = y2
      ex2.dist_dragged = (ex2.dist_dragged or 0) + distance

      if ex2.dist_dragged > rqmt then
        ex2._df_shake_locked = true
        ex2._df_block_until_release = true

        G.E_MANAGER:add_event(Event({
          trigger = 'immediate',
          func = function()
            if not card then return true end

            -- Ensure tables (set_ability might replace them)
            card.ability = card.ability or {}
            card.ability.extra = card.ability.extra or {}
            local ex3 = card.ability.extra

            -- Reset shake state
            ex3.prev_drag_x = 0
            ex3.prev_drag_y = 0
            ex3.dist_dragged = 0

            -- Roll chance
            local success = roll_chance(ch)

            if not success then
              shatter_card(card)
              return true
            end

            local ok = DF_set_consumable_center(card, next_key)

            if ok then
              if card_eval_status_text then
                card_eval_status_text(card, 'extra', nil, nil, nil, { message = "Upgraded!", colour = G.C.GREEN })
              end

              -- Re-ensure after set_ability
              card.ability = card.ability or {}
              card.ability.extra = card.ability.extra or {}
              local ex4 = card.ability.extra

              -- Preserve hold-block + lock even if ability was replaced
              ex4._df_block_until_release = true
              ex4._df_shake_locked = true

              -- Update next target + rqmt + chance from new center config
              local new_center = G.P_CENTERS[next_key]
              local cfg = new_center and new_center.config or nil

              ex4._df_next_center_key = cfg and cfg.next_center_key or nil
              ex4._df_shake_rqmt = (cfg and cfg.shake_rqmt) or ex4._df_shake_rqmt or 25
              ex4._df_upgrade_chance = (cfg and cfg.upgrade_chance) or ex4._df_upgrade_chance or 1
            else
              if card_eval_status_text then
                card_eval_status_text(card, 'extra', nil, nil, nil, { message = "Missing center: " .. tostring(next_key), colour = G.C.RED })
              end
            end

            -- SNAP BACK
            card.ability = card.ability or {}
            card.ability.extra = card.ability.extra or {}
            card.ability.extra._df_forced_snap = true

            if card.stop_drag then
              pcall(function() card:stop_drag() end)
            end
            if card.area and card.area.align_cards then
              pcall(function() card.area:align_cards() end)
            end

            return true
          end
        }))
      end
    end

    local card_stop_drag_orig = card.stop_drag
    card.stop_drag = function(cself)
      if card_stop_drag_orig then card_stop_drag_orig(cself) end
      if not card then return end

      card.ability = card.ability or {}
      card.ability.extra = card.ability.extra or {}
      local ex2 = card.ability.extra

      ex2.prev_drag_x = 0
      ex2.prev_drag_y = 0
      ex2.dist_dragged = 0

      -- If mouse is actually UP, clear the hold-block and unlock for next time.
      if not lmb_down() then
        ex2._df_block_until_release = false
        ex2._df_shake_locked = false
        ex2._df_forced_snap = false
        return
      end

      -- Otherwise mouse is still held: keep block + lock.
      if ex2._df_forced_snap then
        ex2._df_forced_snap = false
      end
      ex2._df_block_until_release = true
      ex2._df_shake_locked = true
    end
  end
end

-- Same "can_use" logic as your normal balls
local function DF_can_use_ball(self, card)
  if #G.jokers.cards < G.jokers.config.card_limit or self.area == G.jokers then
    return true
  else
    return false
  end
end

----------------------------------------------------------------
-- Divine Ball (final form) - you can customize this later
-- For now: acts like Master Ball on use
----------------------------------------------------------------
local divine_ball = {
  name = "divine_ball",
  key = "divine_ball",
  set = "Divine",

  atlas = "AtlasConsumablesBasic",
  pos = { x = 8, y = 7 },
  soul_pos = { x = 7, y = 7 },
  cost = 6,
  pokeball = true,
  unlocked = true,
  discovered = true,
  saveable = true,
  hidden = true,
  soul_set = "Item",

  can_use = DF_can_use_ball,

  config = { next_center_key = nil },

  use = function(self, card, area, copier)
    G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.4, func = function()
      play_sound('timpani')
      local _card = create_random_poke_joker("divineball", "Divine")
      _card:add_to_deck()
      G.jokers:emplace(_card)
      return true
    end}))
    delay(0.6)
  end,

  calculate = function(self, card, context) return end,
  in_pool = function(self) return false end,
}

----------------------------------------------------------------
-- Shaker Master Ball -> shake -> Divine Ball
-- Use effect: like Master Ball
----------------------------------------------------------------
local shaker_masterball = {
  name = "shaker_masterball",
  key = "shaker_masterball",
  set = "Divine",
  pos = { x = 3, y = 3 },
  soul_pos = { x = 4, y = 2 },
  atlas = "AtlasConsumablesBasic",
  cost = 6,
  pokeball = true,
  unlocked = true,
  discovered = true,
  saveable = true,
  hidden = true,
  soul_set = "Item",

  config = { extra = { prev_drag_x = 0, prev_drag_y = 0, dist_dragged = 0 },
           shake_rqmt = 25,
           next_center_key = "c_DF_divine_ball",
           upgrade_chance = 0.10 },

  add_to_deck = function(self, card) DF_setup_drag_transform(self, card, self.config and self.config.next_center_key) end,
load        = function(self, card) DF_setup_drag_transform(self, card, self.config and self.config.next_center_key) end,

  can_use = DF_can_use_ball,

  use = function(self, card, area, copier)
    G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.4, func = function()
      play_sound('timpani')
      local _card = create_random_poke_joker("masterball", "Legendary")
      _card:add_to_deck()
      G.jokers:emplace(_card)
      return true
    end}))
    delay(0.6)
  end,

  calculate = function(self, card, context) return end,
  in_pool = function(self) return false end,
}

----------------------------------------------------------------
-- Shaker Ultra Ball -> shake -> Shaker Master Ball
-- Use effect: like Ultra Ball
----------------------------------------------------------------
local shaker_ultraball = {
  name = "shaker_ultraball",
  key = "shaker_ultraball",
  set = "Divine",

  atlas = "AtlasConsumablesBasic",
  pos = { x = 2, y = 3 },
  cost = 5,
  pokeball = true,
  unlocked = true,
  discovered = true,
  saveable = true,
  hidden = true,
  soul_set = "Item",

  config = { extra = { prev_drag_x = 0, prev_drag_y = 0, dist_dragged = 0 },
           shake_rqmt = 25,
           next_center_key = "c_DF_shaker_masterball",
           upgrade_chance = 0.20 },

  add_to_deck = function(self, card) DF_setup_drag_transform(self, card, self.config and self.config.next_center_key) end,
load        = function(self, card) DF_setup_drag_transform(self, card, self.config and self.config.next_center_key) end,

  can_use = DF_can_use_ball,

  use = function(self, card, area, copier)
    G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.4, func = function()
      play_sound('timpani')
      local _card = create_random_poke_joker("ultraball", "Two")
      _card:add_to_deck()
      G.jokers:emplace(_card)
      return true
    end}))
    delay(0.6)
  end,

  calculate = function(self, card, context) return end,
  in_pool = function(self) return false end,
}

----------------------------------------------------------------
-- Shaker Great Ball -> shake -> Shaker Ultra Ball
-- Use effect: like Great Ball
----------------------------------------------------------------
local shaker_greatball = {
  name = "shaker_greatball",
  key = "shaker_greatball",
  set = "Divine",

  atlas = "AtlasConsumablesBasic",
  pos = { x = 1, y = 3 },
  cost = 4,
  pokeball = true,
  unlocked = true,
  discovered = true,
  saveable = true,
  hidden = true,
  soul_set = "Item",

  config = { extra = { prev_drag_x = 0, prev_drag_y = 0, dist_dragged = 0 },
           shake_rqmt = 25,
           next_center_key = "c_DF_shaker_ultraball",
           upgrade_chance = 0.50 },

  add_to_deck = function(self, card) DF_setup_drag_transform(self, card, self.config and self.config.next_center_key) end,
  load        = function(self, card) DF_setup_drag_transform(self, card, self.config and self.config.next_center_key) end,

  can_use = DF_can_use_ball,

  use = function(self, card, area, copier)
    -- match your normal greatball: spoon item + stage 1 joker
    if type(set_spoon_item) == "function" then set_spoon_item(card) end
    G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.4, func = function()
      play_sound('timpani')
      local _card = create_random_poke_joker("greatball", "One")
      _card:add_to_deck()
      G.jokers:emplace(_card)
      return true
    end}))
    delay(0.6)
  end,

  calculate = function(self, card, context) return end,
  in_pool = function(self) return false end,
}

----------------------------------------------------------------
-- Shaker Poké Ball -> shake -> Shaker Great Ball
-- Use effect: like Poké Ball
----------------------------------------------------------------
local shaker_pokeball = {
  name = "shaker_pokeball",
  key = "shaker_pokeball",
  set = "Divine",
  hidden = true,
  soul_set = "Item",

  atlas = "AtlasConsumablesBasic",
  pos = { x = 0, y = 3 },
  cost = 3,
  pokeball = true,
  unlocked = true,
  discovered = true,
  saveable = true,

  config = { extra = { prev_drag_x = 0, prev_drag_y = 0, dist_dragged = 0 },
           shake_rqmt = 25,
           next_center_key = "c_DF_shaker_greatball",
           upgrade_chance = 0.75 },

  add_to_deck = function(self, card) DF_setup_drag_transform(self, card, self.config and self.config.next_center_key) end,
  load        = function(self, card) DF_setup_drag_transform(self, card, self.config and self.config.next_center_key) end,

  can_use = DF_can_use_ball,

  use = function(self, card, area, copier)
    -- match your normal pokeball: spoon item + basic joker
    if type(set_spoon_item) == "function" then set_spoon_item(card) end
    G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.4, func = function()
      play_sound('timpani')
      local _card = create_random_poke_joker("pokeball", "Basic")
      _card:add_to_deck()
      G.jokers:emplace(_card)
      return true
    end}))
    delay(0.6)
  end,

  calculate = function(self, card, context) return end,
  in_pool = function(self) return false end,
}

return {
  name = "Shaker Balls",
  list = {
    shaker_pokeball,
    shaker_greatball,
    shaker_ultraball,
    shaker_masterball,
    divine_ball
  }
}
