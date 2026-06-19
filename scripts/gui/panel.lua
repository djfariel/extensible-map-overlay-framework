local constants = require("scripts.constants")
local chart_watchers = require("scripts.map.chart_watchers")
local panel_layout = require("scripts.gui.panel_layout")
local panel_actions = require("scripts.gui.panel_actions")
local panel_overlays = require("scripts.gui.panel_overlays")
local player_resolution = require("scripts.player_resolution")
local player_iteration = require("scripts.map.player_iteration")
local settings_writer = require("scripts.map.settings_writer")
local setup_dispatch = require("scripts.tools.setup_dispatch")
local emof_storage = require("scripts.emof_storage")
local tool_state = require("scripts.tools.tool_state")
local view_context = require("scripts.map.view_context")

local M = {}

local function set_shortcut_toggled(player, toggled)
  if not (player and player.valid) then
    return
  end

  pcall(function()
    player.set_shortcut_toggled(constants.SHORTCUT_OPEN_PANEL, toggled)
  end)
end

local function persist_panel_location(player, state)
  local location = panel_layout.read_panel_location(panel_layout.get_panel(player))
  if location then
    state.panel_location = location
  end
end

local function hide_panel(player, state)
  persist_panel_location(player, state)
  panel_layout.clear_layout_cache(state)
  M.destroy(player)
end

function M.destroy(player)
  local panel = panel_layout.get_panel(player)
  if panel and panel.valid then
    panel.destroy()
  end
end

function M.sync_shortcut(player)
  local state = emof_storage.get_player_state(player.index)
  set_shortcut_toggled(player, state.panel_open == true)
end

function M.close(player)
  setup_dispatch.cancel_any_open(player)
  tool_state.cancel(player, "panel-close")

  local state = emof_storage.get_player_state(player.index)
  persist_panel_location(player, state)
  state.panel_open = false
  panel_layout.clear_layout_cache(state)
  chart_watchers.untrack(player.index)
  M.sync_shortcut(player)
  M.destroy(player)
end

function M.open(player)
  local state = emof_storage.get_player_state(player.index)
  state.panel_open = true
  chart_watchers.track(player.index)
  M.sync_shortcut(player)
  M.refresh(player)
end

function M.toggle(player)
  local state = emof_storage.get_player_state(player.index)
  if state.panel_open then
    M.close(player)
  else
    M.open(player)
  end
end

function M.on_lua_shortcut(event)
  if event.prototype_name ~= constants.SHORTCUT_OPEN_PANEL then
    return
  end

  local player = player_resolution.from_event(event)
  if not player then
    return
  end

  M.toggle(player)
end

function M.sync(player)
  if not (player and player.valid) then
    return
  end

  local state = emof_storage.get_player_state(player.index)
  if not state.panel_open or not view_context.is_chart_view(player) then
    return
  end

  local panel = panel_layout.get_panel(player)
  if not (panel and panel.valid) then
    return
  end

  panel_actions.sync_states(panel, player)
  panel_overlays.sync_drawer(panel, player, state)
end

function M.refresh(player, opts)
  if not (player and player.valid) then
    return
  end

  local state = emof_storage.get_player_state(player.index)
  local in_chart_view = view_context.is_chart_view(player)
  local force_rebuild = opts and opts.rebuild == true
  M.sync_shortcut(player)
  state.panel_visible = in_chart_view and state.panel_open

  if not state.panel_open or not in_chart_view then
    hide_panel(player, state)
    return
  end

  settings_writer.ensure_default_map_settings(player)

  local panel, created = panel_layout.get_or_create_panel(player)
  local action_sig = panel_actions.signature(player)
  local overlay_sig = panel_overlays.structure_signature(player)
  local region = panel[constants.GUI.overlay_region]
  local drawer = region and region[constants.GUI.overlay_drawer]
  local drawer_valid = drawer and drawer.valid

  if force_rebuild or created or state.cached_action_signature ~= action_sig then
    panel_actions.render(panel, player)
    state.cached_action_signature = action_sig
  else
    panel_actions.sync_states(panel, player)
  end

  if force_rebuild or created or state.cached_overlay_signature ~= overlay_sig or not drawer_valid then
    panel_overlays.render_region(panel, player, state)
    state.cached_overlay_signature = overlay_sig
  else
    panel_overlays.sync_drawer(panel, player, state)
  end

  panel_layout.ensure_extension_slot(panel)
  panel_layout.apply_panel_section_styles(panel)

  if created then
    panel_layout.apply_saved_or_default_location(player, panel, state)
  else
    local location = panel_layout.read_panel_location(panel)
    if location then
      state.panel_location = location
    end
  end
end

function M.refresh_all_connected()
  player_iteration.each_connected(function(player)
    M.refresh(player, { rebuild = true })
  end)
end

function M.on_overlay_toggle_clicked(player, id)
  panel_overlays.on_toggle_clicked(player, id)
  M.sync(player)
end

function M.on_action_button_clicked(player, id)
  panel_actions.on_button_clicked(player, id)
  M.sync(player)
end

function M.handle_gui_click(player, element)
  if element.name == panel_layout.CLOSE_BUTTON_NAME then
    M.close(player)
    return true
  end

  if string.find(element.name, constants.GUI.toggle_button_prefix, 1, true) == 1 then
    local id = string.sub(element.name, #constants.GUI.toggle_button_prefix + 1)
    M.on_overlay_toggle_clicked(player, id)
    return true
  end

  if string.find(element.name, constants.GUI.action_button_prefix, 1, true) == 1 then
    local id = string.sub(element.name, #constants.GUI.action_button_prefix + 1)
    M.on_action_button_clicked(player, id)
    return true
  end

  return false
end

return M
