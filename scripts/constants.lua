local M = {}

M.INTERFACE_NAME = "extensible_map_overlay_framework"
M.SHORTCUT_OPEN_PANEL = "emof-toggle-chart-controls"

M.MOD_DATA_TYPE = {
  map_action_button = "emof.map-action-button",
  map_overlay_toggle = "emof.map-overlay-toggle"
}

M.PUBLIC_EVENT = {
  map_action_clicked = "emof-on-map-action-clicked",
  map_overlay_toggled = "emof-on-map-overlay-toggled",
  tool_state_changed = "emof-on-tool-state-changed"
}

M.CUSTOM_INPUT = {
  map_click = "emof-map-click",
  cancel = "emof-cancel",
  toggle_panel = "emof-toggle-chart-controls"
}

M.CURSOR_TOOL = {
  ping = "emof-ping-tool",
  tag = "emof-tag-tool"
}

M.CUSTOM_EVENT = {
  registry_changed = script.generate_event_name(),
  player_toggle_changed = script.generate_event_name(),
  action_state_changed = script.generate_event_name()
}

M.TOOL_START = {
  immediate = "immediate",
  setup = "setup"
}

M.BUILTIN_TOOL = {
  ping = "ping",
  tag = "tag"
}

M.BUILTIN_REMOTE_INTERFACE = "emof_builtin_map_tools"
M.OWNING_MOD = "extensible-map-overlay-framework"

M.GUI = {
  map_panel = "emof_map_panel",
  actions_inset = "emof_actions_inset",
  overlay_region = "emof_overlay_region",
  extension_slot = "emof_extension_slot",
  overlay_drawer = "emof_overlay_drawer",

  toggle_button_prefix = "emof_toggle__",
  action_button_prefix = "emof_action__"
}

M.UPDATE_INTERVAL = 10

M.REGISTRATION_KIND = {
  overlay = "overlay",
  action = "action",
  tool = "tool"
}

M.DEFAULT_TAG_ICON = {
  type = "virtual",
  name = "signal-map-marker"
}

return M
