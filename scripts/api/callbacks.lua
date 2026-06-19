local constants = require("scripts.constants")
local player_resolution = require("scripts.player_resolution")
local public_events = require("scripts.api.public_events")
local registry = require("scripts.api.registry")
local emof_storage = require("scripts.emof_storage")
local tool_notify = require("scripts.tools.tool_notify")
local tool_state = require("scripts.tools.tool_state")
local validation = require("scripts.api.validation")
local view_context = require("scripts.map.view_context")

local M = {}

local function raise_registry_changed()
  script.raise_event(constants.CUSTOM_EVENT.registry_changed, {})
end

local function raise_player_toggle_changed(player_index)
  script.raise_event(constants.CUSTOM_EVENT.player_toggle_changed, {
    player_index = player_index
  })
end

local function set_optional_surface_index(payload, player)
  local surface_index = view_context.surface_index(player)
  if surface_index then
    payload.surface_index = surface_index
  end
end

local function log_remote_callback_error(interface, function_name, err)
  local message = "[extensible-map-overlay-framework] remote callback failed: "
    .. interface
    .. "."
    .. function_name
    .. ": "
    .. tostring(err)

  if log then
    log(message)
  end
end

local function invoke_remote_callback(interface, function_name, payload)
  local ok, result = pcall(remote.call, interface, function_name, payload)
  if not ok then
    log_remote_callback_error(interface, function_name, result)
    return false, nil
  end

  return true, result
end

local function require_valid_player(player_index)
  return player_resolution.require_index(player_index)
end

local function require_active_owning_mod(owning_mod)
  if not script.active_mods[owning_mod] then
    error(
      "Extensible Map Overlay Framework map tool owner is not active: "
        .. tostring(owning_mod)
    )
  end
end

function M.register_overlay_toggle(spec)
  local normalized = validation.validate_overlay_toggle_spec(spec)
  registry.register_overlay(normalized)
  raise_registry_changed()
end

function M.register_action_button(spec)
  local normalized = validation.validate_action_button_spec(spec, { require_registered_tool = true })
  registry.register_action(normalized)
  raise_registry_changed()
end

function M.register_map_tool(spec)
  local normalized = validation.validate_map_tool(spec)
  require_active_owning_mod(normalized.owning_mod)
  registry.register_tool(normalized)
  tool_state.register({
    name = normalized.id,
    cursor_item = normalized.cursor_item,
    on_click = M.dispatch_map_tool_click,
    on_cancel = M.dispatch_map_tool_cancel
  })
  raise_registry_changed()
end

function M.try_register_map_tool(spec)
  local ok, err = pcall(M.register_map_tool, spec)
  if ok then
    return { ok = true }
  end

  return { ok = false, error = tostring(err) }
end

function M.is_action_enabled(player_index, action_id)
  local spec = registry.get_action(action_id)
  if not (spec and spec.enabled) then
    return true
  end

  local ok, result = invoke_remote_callback(spec.enabled.interface, spec.enabled.function_name, {
    player_index = player_index,
    id = action_id
  })

  if not ok then
    return false
  end

  return result == true
end

function M.unregister(mod_name, id, kind)
  if type(mod_name) ~= "string" or mod_name == "" then
    error("Extensible Map Overlay Framework invalid field 'mod_name': expected non-empty string")
  end
  if type(id) ~= "string" or id == "" then
    error("Extensible Map Overlay Framework invalid field 'id': expected non-empty string")
  end
  if type(kind) ~= "string" or constants.REGISTRATION_KIND[kind] == nil then
    error(
      "Extensible Map Overlay Framework invalid field 'kind': expected 'overlay', 'action', or 'tool'"
    )
  end

  local removed = registry.unregister(mod_name, id, kind)
  if removed then
    if kind == constants.REGISTRATION_KIND.tool then
      tool_state.unregister(id)
      tool_state.cancel_players_using_tool(id, "unregistered")
    end
    raise_registry_changed()
  end
  return removed
end

function M.set_player_toggle(player_index, id, value)
  if type(value) ~= "boolean" then
    error("Extensible Map Overlay Framework invalid field 'value': expected boolean")
  end

  if registry.get_overlay(id) == nil then
    error("Extensible Map Overlay Framework unknown overlay id: " .. id)
  end

  local player = require_valid_player(player_index)
  local state = emof_storage.get_player_state(player.index)
  state.extension_toggles[id] = value
  raise_player_toggle_changed(player.index)
  return value
end

function M.get_player_toggle(player_index, id)
  local player = require_valid_player(player_index)
  local state = emof_storage.get_player_state(player.index)
  return state.extension_toggles[id]
end

function M.dispatch_overlay_toggle(player, spec, enabled)
  local payload = {
    player_index = player.index,
    id = spec.id,
    enabled = enabled
  }
  set_optional_surface_index(payload, player)
  script.raise_event(public_events.event_id(constants.PUBLIC_EVENT.map_overlay_toggled), payload)
end

function M.dispatch_action_click(player, spec)
  local payload = {
    player_index = player.index,
    id = spec.id
  }
  set_optional_surface_index(payload, player)
  script.raise_event(public_events.event_id(constants.PUBLIC_EVENT.map_action_clicked), payload)
end

function M.start_map_tool(player_index, id, data)
  local player = player_resolution.from_index(player_index)
  if not player then
    return false
  end

  local spec = registry.get_tool(id)
  if not spec then
    error("Extensible Map Overlay Framework unknown map tool id: " .. tostring(id))
  end

  require_active_owning_mod(spec.owning_mod)

  local payload = data or {}
  local cursor_label = payload.cursor_label
  local cursor_label_color = payload.cursor_label_color

  if cursor_label == nil then
    cursor_label = spec.cursor_label
  end

  if cursor_label_color == nil then
    cursor_label_color = spec.cursor_label_color
  end

  return tool_state.start(player, {
    name = spec.id,
    cursor_item = spec.cursor_item,
    cursor_label = cursor_label,
    cursor_label_color = cursor_label_color,
    data = payload
  })
end

function M.cancel_map_tool(player_index, reason)
  local player = player_resolution.from_index(player_index)
  if not player then
    return false
  end

  return tool_state.cancel(player, reason or "remote-cancel")
end

function M.dispatch_map_tool_click(player, payload, active_tool)
  local spec = registry.get_tool(active_tool.name)
  if not spec then
    return "done"
  end

  local remote_payload = {
    player_index = player.index,
    id = spec.id,
    surface_index = payload.surface_index,
    cursor_position = payload.cursor_position,
    tick = payload.tick,
    data = active_tool.data or {}
  }

  local entity = payload.entity
  if entity and entity.valid then
    remote_payload.selected_entity = {
      unit_number = entity.unit_number,
      surface_index = entity.surface.index
    }
  end

  local ok, result = invoke_remote_callback(spec.on_click.interface, spec.on_click.function_name, remote_payload)
  if not ok then
    return "done"
  end

  return result
end

local function invoke_setup_callback(tool_spec, callback_key, player_index)
  local setup = tool_spec and tool_spec.setup
  local callback = setup and setup[callback_key]
  if not callback then
    return false, nil
  end

  return invoke_remote_callback(callback.interface, callback.function_name, {
    player_index = player_index
  })
end

function M.is_tool_setup_open(player_index, tool_id)
  local spec = registry.get_tool(tool_id)
  if not (spec and spec.setup and spec.setup.is_open) then
    return false
  end

  local ok, result = invoke_setup_callback(spec, "is_open", player_index)
  return ok and result == true
end

function M.open_tool_setup(player_index, tool_id)
  require_valid_player(player_index)
  local spec = registry.get_tool(tool_id)
  if not spec then
    error("Extensible Map Overlay Framework unknown map tool id: " .. tostring(tool_id))
  end

  if not (spec.setup and spec.setup.open) then
    return false
  end

  require_active_owning_mod(spec.owning_mod)
  M.cancel_map_tool(player_index, "new-tool-setup")
  M.cancel_any_tool_setup(player_index)

  local ok = invoke_setup_callback(spec, "open", player_index)
  if ok then
    tool_notify.raise(player_index)
  end
  return ok
end

function M.cancel_tool_setup(player_index, tool_id)
  require_valid_player(player_index)
  local spec = registry.get_tool(tool_id)
  if not (spec and spec.setup and spec.setup.cancel) then
    return false
  end

  require_active_owning_mod(spec.owning_mod)
  local ok = invoke_setup_callback(spec, "cancel", player_index)
  if ok then
    tool_notify.raise(player_index)
  end
  return ok
end

function M.cancel_any_tool_setup(player_index)
  -- Scans all registered tools with setup handlers; O(tools) per call. Fine for small
  -- registries; consider indexing open setups if consumer mods register many tools.
  require_valid_player(player_index)

  local cancelled_any = false
  for _, spec in pairs(registry.get_tool_specs()) do
    if spec.setup and spec.setup.cancel and M.is_tool_setup_open(player_index, spec.id) then
      local ok = invoke_setup_callback(spec, "cancel", player_index)
      if ok then
        cancelled_any = true
      end
    end
  end

  if cancelled_any then
    tool_notify.raise(player_index)
  end
end

function M.dispatch_map_tool_cancel(player, active_tool, reason)
  local spec = registry.get_tool(active_tool.name)
  if not (spec and spec.on_cancel) then
    return
  end

  local payload = {
    player_index = player.index,
    id = spec.id,
    reason = reason,
    data = active_tool.data or {}
  }
  set_optional_surface_index(payload, player)
  invoke_remote_callback(spec.on_cancel.interface, spec.on_cancel.function_name, payload)
end

function M.rebuild_registered_tools()
  for _, spec in pairs(registry.get_tool_specs()) do
    tool_state.register({
      name = spec.id,
      cursor_item = spec.cursor_item,
      on_click = M.dispatch_map_tool_click,
      on_cancel = M.dispatch_map_tool_cancel
    })
  end
end

return M
