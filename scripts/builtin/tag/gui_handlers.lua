local constants = require("scripts.constants")
local dialog = require("scripts.builtin.tag.dialog")
local player_resolution = require("scripts.player_resolution")
local setup = require("scripts.builtin.tag.setup")
local setup_dispatch = require("scripts.tools.setup_dispatch")

local M = {}

function M.on_gui_click(event)
  if not (event.element and event.element.valid) then
    return
  end

  local player = player_resolution.from_event(event)
  if not player then
    return
  end

  if event.element.name == dialog.GUI.confirm then
    setup.confirm_setup(player)
    return
  end

  if event.element.name == dialog.GUI.cancel then
    setup_dispatch.cancel(player, constants.BUILTIN_TOOL.tag)
  end
end

function M.on_gui_elem_changed(event, player)
  if not (event.element and event.element.valid) then
    return
  end

  player = player or player_resolution.from_event(event)
  if not player then
    return
  end

  if event.element.name == dialog.GUI.icon then
    setup.on_setup_elem_changed(player, event.element)
    return
  end

  if event.element.name == dialog.GUI.text then
    dialog.sync_confirm_state(player)
  end
end

function M.on_gui_text_changed(event, player)
  if not (event.element and event.element.valid) then
    return
  end

  player = player or player_resolution.from_event(event)
  if not player then
    return
  end

  if event.element.name == dialog.GUI.text then
    dialog.sync_confirm_state(player)
  end
end

function M.on_gui_closed(event)
  if not (event.element and event.element.valid) then
    return
  end

  local player = player_resolution.from_event(event)
  if not player then
    return
  end

  if event.element.name == dialog.GUI.dialog then
    setup_dispatch.cancel(player, constants.BUILTIN_TOOL.tag)
  end
end

return M
