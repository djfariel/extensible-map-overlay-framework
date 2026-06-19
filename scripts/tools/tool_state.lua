-- Map tool runtime dispatch table. Not persisted - repopulated from storage registry
-- on save load via callbacks.rebuild_registered_tools() in bootstrap.on_load.

local constants = require("scripts.constants")
local click_payload = require("scripts.tools.click_payload")
local cursor = require("scripts.tools.cursor")
local player_resolution = require("scripts.player_resolution")
local emof_storage = require("scripts.emof_storage")
local tool_notify = require("scripts.tools.tool_notify")

local M = {}

local registered_specs = {}
local map_click_registered = false
local cancel_registered = false

local function clear_remote_click_position(player_index)
  emof_storage.clear_remote_view_click_position(player_index)
end

local function should_wait_for_remote_click_release(player, event)
  local pos = event.cursor_position
  if not pos or player.controller_type ~= defines.controllers.remote then
    return false
  end

  local positions = emof_storage.get_remote_view_click_positions()
  local prev = positions[event.player_index]
  local tick = event.tick or game.tick or 0

  if prev
    and prev.x == pos.x
    and prev.y == pos.y
    then
    positions[event.player_index] = nil
    return false
  end

  positions[event.player_index] = { x = pos.x, y = pos.y, tick = tick }
  return true
end

local function storage_has_active_tool()
  for _, state in pairs(emof_storage.get_all_players()) do
    if state.active_tool ~= nil then
      return true
    end
  end
  return false
end

local function active_tool_has_cursor(player_index, active_tool)
  if not game then
    return false
  end

  local player = player_resolution.from_index(player_index)
  if not player then
    return false
  end

  return active_tool.cursor_item and cursor.is_equipped(player, active_tool.cursor_item)
end

local function has_active_tool(skip_cursor_check)
  if skip_cursor_check then
    return storage_has_active_tool()
  end

  for player_index, state in pairs(emof_storage.get_all_players()) do
    if state.active_tool ~= nil then
      if active_tool_has_cursor(player_index, state.active_tool) then
        return true
      end

      state.active_tool = nil
      clear_remote_click_position(player_index)
    end
  end
  return false
end

local function active_spec(active_tool)
  if not active_tool then
    return nil
  end
  return registered_specs[active_tool.name]
end

local function resolve_cursor_label_options(spec)
  if not spec then
    return nil
  end

  local label = spec.cursor_label
  local label_color = spec.cursor_label_color

  if label == nil and spec.data then
    label = spec.data.cursor_label
    if spec.data.cursor_label_color ~= nil then
      label_color = spec.data.cursor_label_color
    end
  end

  if label == nil and label_color == nil then
    return nil
  end

  return {
    label = label,
    label_color = label_color
  }
end

local function end_tool(player, active_tool)
  local state = emof_storage.get_player_state(player.index)
  state.active_tool = nil
  clear_remote_click_position(player.index)

  if active_tool and active_tool.cursor_item then
    cursor.clear(player, active_tool.cursor_item)
  end

  M.sync_input_handlers()
  tool_notify.raise(player.index, {
    active_tool_id = nil,
    cancelled_tool_id = active_tool and active_tool.name or nil,
    reason = "done"
  })
end

local function dispatch_tool_click(player, event, active_tool)
  local payload = click_payload.build(player, event)
  if not payload then
    return
  end

  local spec = active_spec(active_tool)
  if not (spec and spec.on_click) then
    M.cancel(player, "missing-handler")
    return
  end

  local result = spec.on_click(player, payload, active_tool)
  if result == "done" then
    end_tool(player, active_tool)
  end
end

function M.register(spec)
  if not (spec and spec.name) then
    error("Tool spec requires a name")
  end

  registered_specs[spec.name] = spec
end

function M.unregister(name)
  if type(name) ~= "string" or name == "" then
    return false
  end

  if registered_specs[name] == nil then
    return false
  end

  registered_specs[name] = nil
  return true
end

function M.prune_registered(is_registered)
  for name in pairs(registered_specs) do
    if not is_registered(name) then
      registered_specs[name] = nil
    end
  end
end

local function clear_or_cancel_player_tool(player_index, state, reason)
  local player = player_resolution.from_index(player_index)
  if player then
    M.cancel(player, reason)
    return
  end

  state.active_tool = nil
  clear_remote_click_position(player_index)
end

local function cancel_matching_players(should_cancel, reason)
  for player_index, state in pairs(emof_storage.get_all_players()) do
    local active_tool = state.active_tool
    if active_tool and should_cancel(active_tool) then
      clear_or_cancel_player_tool(player_index, state, reason)
    end
  end

  M.sync_input_handlers()
end

function M.cancel_all_players(reason)
  cancel_matching_players(function()
    return true
  end, reason)
end

function M.cancel_players_using_tool(tool_name, reason)
  if type(tool_name) ~= "string" or tool_name == "" then
    return
  end

  cancel_matching_players(function(active_tool)
    return active_tool.name == tool_name
  end, reason)
end

function M.start(player, spec)
  if not (player and player.valid and spec and spec.name and spec.cursor_item) then
    return false
  end

  if spec.on_click then
    M.register(spec)
  end

  M.cancel(player)
  clear_remote_click_position(player.index)

  if not cursor.equip(player, spec.cursor_item, resolve_cursor_label_options(spec)) then
    return false
  end

  local state = emof_storage.get_player_state(player.index)
  state.active_tool = {
    name = spec.name,
    cursor_item = spec.cursor_item,
    data = spec.data or {}
  }

  M.sync_input_handlers()
  tool_notify.raise(player.index, { active_tool_id = spec.name })
  return true
end

function M.get(player)
  if not (player and player.valid) then
    return nil
  end

  return emof_storage.get_player_state(player.index).active_tool
end

function M.cancel(player, reason)
  if not (player and player.valid) then
    return false
  end

  local state = emof_storage.get_player_state(player.index)
  local active_tool = state.active_tool
  if not active_tool then
    clear_remote_click_position(player.index)
    return false
  end

  local cancelled_tool_id = active_tool.name
  state.active_tool = nil
  clear_remote_click_position(player.index)

  local spec = active_spec(active_tool)
  if spec and spec.on_cancel then
    local ok, err = pcall(spec.on_cancel, player, active_tool, reason or "cancel")
    if not ok and log then
      log("[extensible-map-overlay-framework] tool on_cancel failed: " .. tostring(err))
    end
  end

  if active_tool.cursor_item then
    cursor.clear(player, active_tool.cursor_item)
  end

  M.sync_input_handlers()
  tool_notify.raise(player.index, {
    active_tool_id = nil,
    cancelled_tool_id = cancelled_tool_id,
    reason = reason or "cancel"
  })
  return true
end

function M.handle_primary_input(event)
  local player = player_resolution.from_event(event)
  if not player then
    return
  end

  local active_tool = M.get(player)
  if not active_tool then
    M.sync_input_handlers()
    clear_remote_click_position(player.index)
    return
  end

  if active_tool.cursor_item and not cursor.is_equipped(player, active_tool.cursor_item) then
    M.cancel(player, "cursor-cleared")
    return
  end

  if event.in_gui then
    return
  end

  if should_wait_for_remote_click_release(player, event) then
    return
  end

  dispatch_tool_click(player, event, active_tool)
end

function M.handle_cancel_input(event)
  local player = player_resolution.from_event(event)
  if player then
    M.cancel(player, "cancel-input")
  end
end

function M.handle_cursor_changed(event)
  local player = player_resolution.from_event(event)
  if not player then
    return
  end

  local active_tool = M.get(player)
  if active_tool and active_tool.cursor_item and not cursor.is_equipped(player, active_tool.cursor_item) then
    M.cancel(player, "cursor-cleared")
  end
end

function M.sync_input_handlers()
  local should_register = has_active_tool(game == nil)

  if should_register and not map_click_registered then
    script.on_event(constants.CUSTOM_INPUT.map_click, M.handle_primary_input)
    map_click_registered = true
  elseif not should_register and map_click_registered then
    script.on_event(constants.CUSTOM_INPUT.map_click, nil)
    map_click_registered = false
  end

  if should_register and not cancel_registered then
    script.on_event(constants.CUSTOM_INPUT.cancel, M.handle_cancel_input)
    cancel_registered = true
  elseif not should_register and cancel_registered then
    script.on_event(constants.CUSTOM_INPUT.cancel, nil)
    cancel_registered = false
  end
end

return M
