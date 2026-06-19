local registry = require("scripts.api.registry")

local M = {}

local QUICKBAR_SLOT_COUNT = 100

local function blocked_cursor_items()
  local blocked = {}
  for _, spec in pairs(registry.get_tool_specs()) do
    if spec.cursor_item then
      blocked[spec.cursor_item] = true
    end
  end
  return blocked
end

local function filter_item_name(filter)
  if filter == nil then
    return nil
  end

  if type(filter) == "string" then
    return filter
  end

  if type(filter) == "table" and type(filter.name) == "string" then
    return filter.name
  end

  return nil
end

function M.is_blocked_cursor_item(item_name)
  if type(item_name) ~= "string" or item_name == "" then
    return false
  end

  return blocked_cursor_items()[item_name] == true
end

function M.clear_blocked_slots(player)
  if not (player and player.valid) then
    return
  end

  if not (player.get_quick_bar_slot and player.set_quick_bar_slot) then
    return
  end

  local blocked = blocked_cursor_items()
  if next(blocked) == nil then
    return
  end

  for index = 1, QUICKBAR_SLOT_COUNT do
    local filter = player.get_quick_bar_slot(index)
    local name = filter_item_name(filter)
    if name and blocked[name] then
      player.set_quick_bar_slot(index, nil)
    end
  end
end

function M.on_player_set_quick_bar_slot(event)
  if not event then
    return
  end

  local player = game.get_player(event.player_index)
  M.clear_blocked_slots(player)
end

return M
