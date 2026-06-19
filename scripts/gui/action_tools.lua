local callbacks = require("scripts.api.callbacks")
local constants = require("scripts.constants")
local registry = require("scripts.api.registry")
local setup_dispatch = require("scripts.tools.setup_dispatch")
local tool_state = require("scripts.tools.tool_state")
local view_context = require("scripts.map.view_context")

local M = {}

function M.is_tool_active(player, tool_id)
  if not (player and player.valid and tool_id) then
    return false
  end

  local active_tool = tool_state.get(player)
  return active_tool ~= nil and active_tool.name == tool_id
end

function M.is_action_enabled(player, spec)
  if not (player and player.valid and spec and spec.id) then
    return true
  end

  return callbacks.is_action_enabled(player.index, spec.id)
end

function M.is_action_pressed(player, spec)
  if not (spec and spec.tool_id) then
    return false
  end

  if M.is_tool_active(player, spec.tool_id) then
    return true
  end

  if spec.tool_start == constants.TOOL_START.setup then
    return setup_dispatch.is_open(player, spec.tool_id)
  end

  return false
end

function M.cancel_tool_action(player, spec)
  if M.is_tool_active(player, spec.tool_id) then
    callbacks.cancel_map_tool(player.index, "toolbar-toggle")
    return true
  end

  if spec.tool_start == constants.TOOL_START.setup and setup_dispatch.is_open(player, spec.tool_id) then
    setup_dispatch.cancel(player, spec.tool_id)
    return true
  end

  return false
end

function M.activate_tool_action(player, spec)
  if not registry.get_tool(spec.tool_id) then
    if player and player.valid then
      player.print({ "emof-framework.action-missing-tool", spec.tool_id })
    end
    return false
  end

  if spec.tool_start == constants.TOOL_START.setup then
    if not setup_dispatch.has_setup(spec.tool_id) then
      if player and player.valid then
        player.print({ "emof-framework.action-missing-setup", spec.tool_id })
      end
      return false
    end

    setup_dispatch.open(player, spec.tool_id)
    return true
  end

  setup_dispatch.cancel_any_open(player)

  local data = {}
  local surface_index = view_context.surface_index(player)
  if surface_index then
    data.surface_index = surface_index
  end

  local started = callbacks.start_map_tool(player.index, spec.tool_id, data)
  if started then
    callbacks.dispatch_action_click(player, spec)
  end

  return started
end

function M.handle_action_click(player, spec)
  if not (spec and spec.tool_id) then
    return false
  end

  if M.cancel_tool_action(player, spec) then
    return true
  end

  return M.activate_tool_action(player, spec)
end

return M
