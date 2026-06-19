local constants = require("scripts.constants")
local gui_dispatch = require("scripts.gui.dispatch")
local panel = require("scripts.gui.panel")
local player_resolution = require("scripts.player_resolution")

local M = {}

function M.on_gui_click(event)
  if not (event.element and event.element.valid) then
    return
  end

  local player = player_resolution.from_event(event)
  if not player then
    return
  end

  if panel.handle_gui_click(player, event.element) then
    return
  end

  gui_dispatch.on_gui_click(event)
end

function M.on_gui_elem_changed(event)
  if not (event.element and event.element.valid) then
    return
  end

  local player = player_resolution.from_event(event)
  if not player then
    return
  end

  gui_dispatch.on_gui_elem_changed(event, player)
end

function M.on_gui_text_changed(event)
  if not (event.element and event.element.valid) then
    return
  end

  local player = player_resolution.from_event(event)
  if not player then
    return
  end

  gui_dispatch.on_gui_text_changed(event, player)
end

function M.on_gui_closed(event)
  if not (event.element and event.element.valid) then
    return
  end

  local player = player_resolution.from_event(event)
  if not player then
    return
  end

  if event.element.name == constants.GUI.map_panel then
    panel.close(player)
    return
  end

  gui_dispatch.on_gui_closed(event)
end

function M.on_lua_shortcut(event)
  panel.on_lua_shortcut(event)
end

function M.on_toggle_panel_input(event)
  local player = player_resolution.from_event(event)
  if not player then
    return
  end

  panel.toggle(player)
end

return M
