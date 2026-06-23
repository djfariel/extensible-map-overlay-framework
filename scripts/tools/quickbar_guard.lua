local registry = require("scripts.api.registry")

local M = {}

local QUICKBAR_PAGE_COUNT = 10
local DEFAULT_QUICKBAR_WIDTH = 10

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

local function quickbar_width(player)
  local width = player.quick_bar_width
  if type(width) == "number" and width > 0 then
    return width
  end

  return DEFAULT_QUICKBAR_WIDTH
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

  local width = quickbar_width(player)
  for page_index = 1, QUICKBAR_PAGE_COUNT do
    for slot_index = 1, width do
      local filter = player.get_quick_bar_slot(page_index, slot_index)
      local name = filter_item_name(filter)
      if name and blocked[name] then
        player.set_quick_bar_slot(page_index, slot_index, nil)
      end
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
