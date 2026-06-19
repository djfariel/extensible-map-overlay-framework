local callbacks = require("scripts.api.callbacks")
local constants = require("scripts.constants")
local dialog = require("scripts.builtin.tag.dialog")
local tag_logic = require("scripts.placement.tag")
local emof_storage = require("scripts.emof_storage")

local M = {}

function M.start_setup(player)
  local setup = emof_storage.get_tag_setup_state(player.index)
  dialog.open(player, setup)
end

function M.confirm_setup(player)
  local setup = emof_storage.get_tag_setup_state(player.index)
  if not dialog.can_confirm(player) then
    return false
  end

  if not dialog.read_inputs(player, setup) then
    return false
  end

  local text = setup.text or ""
  local icon = tag_logic.resolve_chart_tag_icon(setup.icon, text)
  local started = callbacks.start_map_tool(player.index, constants.BUILTIN_TOOL.tag, {
    cursor_label = text,
    icon = icon,
    text = text
  })

  if started then
    dialog.close(player)
    emof_storage.clear_tag_setup_state(player.index)
  end

  return started
end

function M.cancel_setup(player)
  dialog.close(player)
  emof_storage.clear_tag_setup_state(player.index)
end

function M.is_setup_open(player)
  return dialog.is_open(player)
end

function M.on_setup_elem_changed(player, element)
  if element.name == dialog.GUI.icon then
    dialog.sync_confirm_state(player)
  end
end

return M
