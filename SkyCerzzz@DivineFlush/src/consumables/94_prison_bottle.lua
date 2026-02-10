-- src/consumables/??_prison_bottle.lua
-- Prison Bottle: toggles Hoopa <-> Hoopa Unbound
-- Kept item, multi-use, but only once per ROUND (ante:blind gate)
-- Each use: 20% chance to create a Legendary Joker (NOW ACTUALLY IMPLEMENTED)
-- Includes a print that shows the final chance + roll each use

local DF = DF or {}

----------------------------------------------------------------
-- Helpers (self-contained)
----------------------------------------------------------------
local function DF_find_first_joker_by_key(joker_key)
  if not (G and G.jokers and G.jokers.cards) then return nil end
  for _, j in ipairs(G.jokers.cards) do
    if j and j.config and j.config.center and j.config.center.key == joker_key then
      return j
    end
  end
  return nil
end

local function DF_create_legendary_joker(source_card, reason_key)
  if not (G and G.jokers) then return end

  -- Prefer mod/backends if they exist
  if type(poke_backend_create_random_legendary_joker) == "function" then
    return poke_backend_create_random_legendary_joker()
  end
  if type(poke_create_random_legendary_joker) == "function" then
    return poke_create_random_legendary_joker()
  end

  -- Fallback: try creating a "rarity 4" joker
  local ok, created = pcall(function()
    local j = create_card('Joker', G.jokers, nil, "Legendary", nil, nil, nil)
    if j then
      j:add_to_deck()
      G.jokers:emplace(j)
      if card_eval_status_text then
        card_eval_status_text(j, 'extra', nil, nil, nil, { message = "Legendary!", colour = G.C.FILTER })
      end
    end
    return j
  end)

  if not ok then
    if card_eval_status_text and source_card then
      card_eval_status_text(source_card, 'extra', nil, nil, nil, { message = "Couldn't spawn Legendary", colour = G.C.RED })
    end
    return nil
  end
  return created
end

-- Once per ROUND gate shared by all Prison Bottles
local function DF_round_id()
  if not (G and G.GAME and G.GAME.round_resets) then return "0:0" end
  local rr = G.GAME.round_resets
  return tostring(rr.ante or 0) .. ":" .. tostring(rr.blind or 0)
end

local function DF_prison_bottle_used_this_round()
  if not (G and G.GAME) then return false end
  G.GAME.DF = G.GAME.DF or {}
  local rid = DF_round_id()
  return G.GAME.DF._df_prison_bottle_last_round_id == rid
end

local function DF_mark_prison_bottle_used_this_round()
  if not (G and G.GAME) then return end
  G.GAME.DF = G.GAME.DF or {}
  G.GAME.DF._df_prison_bottle_last_round_id = DF_round_id()
end

----------------------------------------------------------------
-- Prison Bottle
----------------------------------------------------------------
local prison_bottle = {
  name = "prison_bottle",
  key = "prison_bottle",
  set = "Divine",
  helditem = true,
  saveable = true,

  atlas = "DFConsumables",
  pos = { x = 0, y = 3 },
  soul_pos = { x = 1, y = 3 },

  cost = 4,
  hidden = true,
  soul_set = "Item",
  unlocked = true,
  discovered = true,

  config = { extra = { chance_num = 20, chance_den = 100 } },

  loc_vars = function(self, info_queue, card)
    return { vars = { self.config.extra.chance_num } }
  end,

  can_use = function(self, card)
    -- must have either Hoopa form
    local h = DF_find_first_joker_by_key("j_DF_hoopa") or DF_find_first_joker_by_key("j_DF_hoopa_unbound")
    if not h then return false end

    -- global once-per-round gate across ALL prison bottles
    if DF_prison_bottle_used_this_round() then return false end

    return true
  end,

  keep_on_use = function(self, card)
    return true
  end,

  use = function(self, card)
    local h = DF_find_first_joker_by_key("j_DF_hoopa") or DF_find_first_joker_by_key("j_DF_hoopa_unbound")
    if not h then
      if card_eval_status_text then
        card_eval_status_text(card, 'extra', nil, nil, nil, { message = "No Hoopa", colour = G.C.RED })
      end
      return
    end

    -- global once-per-round gate across ALL prison bottles
    if DF_prison_bottle_used_this_round() then
      if card_eval_status_text then
        card_eval_status_text(card, 'extra', nil, nil, nil, { message = "Already used this round", colour = G.C.RED })
      end
      return
    end

    -- mark immediately (prevents double-use from multiple context calls)
    DF_mark_prison_bottle_used_this_round()

    card.ability = card.ability or {}
    card.ability.extra = card.ability.extra or {}
    local num = (card.ability.extra.chance_num) or (self.config.extra.chance_num or 20)
    local den = (card.ability.extra.chance_den) or (self.config.extra.chance_den or 100)

    G.E_MANAGER:add_event(Event({
      trigger = 'immediate',
      func = function()
        ----------------------------------------------------------------
        -- 1) Toggle Hoopa forms
        ----------------------------------------------------------------
        local cur = h.config and h.config.center and h.config.center.key
        local to_key = (cur == "j_DF_hoopa_unbound") and "j_DF_hoopa" or "j_DF_hoopa_unbound"

        if type(poke_backend_evolve) == "function" then
          poke_backend_evolve(h, to_key)
        else
          if G.P_CENTERS and G.P_CENTERS[to_key] then
            h:set_ability(G.P_CENTERS[to_key], true)
          end
        end

        if h.juice_up then h:juice_up(0.6, 0.6) end
        if card_eval_status_text then
          card_eval_status_text(h, 'extra', nil, nil, nil, { message = "Transformed!", colour = G.C.FILTER })
        end

        ----------------------------------------------------------------
        -- 2) 20% chance to create a Legendary Joker
        ----------------------------------------------------------------
        local chance = (tonumber(num) or 20) / (tonumber(den) or 100)
        local roll = pseudorandom("df_prison_bottle_legendary_spawn")

        -- PRINT: shows chance and roll every use
        print("[PRISON BOTTLE] chance:", chance, "roll:", roll)

        if roll < chance then
          DF_create_legendary_joker(card, "df_prison_bottle_legendary_spawn")
          if card_eval_status_text then
            card_eval_status_text(card, 'extra', nil, nil, nil, { message = "Legendary!", colour = G.C.FILTER })
          end
        end

        return true
      end
    }))
  end,

  calculate = function(self, card, context)
    return
  end,

  in_pool = function(self)
    return false
  end,
}

return {
  list = { prison_bottle }
}
