local constants = require("scripts.constants")
local chart_watchers = require("scripts.map.chart_watchers")
local cursor = require("scripts.tools.cursor")
local panel = require("scripts.gui.panel")
local player_resolution = require("scripts.player_resolution")
local player_settings = require("scripts.map.player_settings")
local pollutant_display = require("scripts.map.pollutant_display")
local quickbar_guard = require("scripts.tools.quickbar_guard")
local registry = require("scripts.api.registry")
local settings_writer = require("scripts.map.settings_writer")
local emof_storage = require("scripts.emof_storage")
local setup_dispatch = require("scripts.tools.setup_dispatch")
local tool_state = require("scripts.tools.tool_state")
local view_context = require("scripts.map.view_context")

local M = {}

local function clear_registered_cursors(player)
  for _, spec in pairs(registry.get_tool_specs()) do
    if spec.cursor_item then
      cursor.clear(player, spec.cursor_item)
    end
  end
end

local function cleanup_leaving_player(player)
  if not player then
    return
  end

  setup_dispatch.cancel_any_open(player)
  tool_state.cancel(player, "disconnect")
  clear_registered_cursors(player)
  panel.close(player)
end

local function initialize_player(player)
  if not player then
    return
  end

  local state = emof_storage.get_player_state(player.index)
  chart_watchers.sync_tracking(player.index, state.panel_open)
  player_settings.hide_vanilla_map_options_for_player(player)
  settings_writer.ensure_default_map_settings(player)
  quickbar_guard.clear_blocked_slots(player)
  panel.refresh(player)
  tool_state.sync_input_handlers()
end

function M.on_player_created(event)
  initialize_player(player_resolution.from_event(event))
end

function M.on_player_joined_game(event)
  initialize_player(player_resolution.from_event(event))
end

local function on_player_context_changed(event)
  local player = player_resolution.from_event(event)
  if not player then
    return
  end

  player_settings.hide_vanilla_map_options_for_player(player)
  panel.refresh(player)
  tool_state.sync_input_handlers()
end

function M.on_player_controller_changed(event)
  on_player_context_changed(event)
end

function M.on_player_changed_surface(event)
  on_player_context_changed(event)
end

function M.on_player_left_game(event)
  chart_watchers.untrack(event.player_index)
  cleanup_leaving_player(player_resolution.from_event(event))
  pollutant_display.clear_cache(event.player_index)
  emof_storage.remove_player(event.player_index)
  tool_state.sync_input_handlers()
end

function M.on_registry_changed()
  panel.refresh_all_connected()
  tool_state.sync_input_handlers()
end

function M.on_player_toggle_changed(event)
  local player = player_resolution.from_event(event)
  if player then
    panel.sync(player)
  end
end

function M.on_action_state_changed(event)
  local player = player_resolution.from_event(event)
  if player then
    panel.sync(player)
  end
end

local function sync_chart_panel_on_tick(player, state)
  local in_chart_view = view_context.is_chart_view(player)

  if in_chart_view ~= state.panel_visible then
    panel.refresh(player)
    return
  end

  if not (state.panel_open and in_chart_view) then
    return
  end

  local overlay_visible = view_context.is_overlay_drawer_visible(player)
  if overlay_visible ~= state.overlay_drawer_visible then
    panel.sync(player)
    return
  end

  if not overlay_visible then
    return
  end

  local display = pollutant_display.resolve_cached(player)
  local pollutant_name = display and display.pollutant_name or false
  if pollutant_name ~= state.last_pollutant_name then
    panel.sync(player)
  end
end

function M.on_tick(event)
  if event.tick % constants.UPDATE_INTERVAL ~= 0 then
    return
  end

  chart_watchers.each_tracked(function(player)
    sync_chart_panel_on_tick(player, emof_storage.get_player_state(player.index))
  end)
end

return M
