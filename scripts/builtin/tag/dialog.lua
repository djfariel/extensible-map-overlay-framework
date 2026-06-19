local element_tree = require("scripts.gui.element_tree")
local tag_logic = require("scripts.placement.tag")

local M = {}

M.GUI = {
  dialog = "emof_tag_dialog",
  icon = "emof_tag_icon",
  text = "emof_tag_text",
  confirm = "emof_tag_confirm",
  cancel = "emof_tag_cancel"
}

local function get_dialog(player)
  return player.gui.screen[M.GUI.dialog]
end

function M.is_open(player)
  local dialog = get_dialog(player)
  return dialog and dialog.valid
end

function M.open(player, pending_tag)
  M.close(player)

  local frame = player.gui.screen.add({
    type = "frame",
    name = M.GUI.dialog,
    direction = "vertical"
  })
  frame.auto_center = true

  local titlebar = frame.add({
    type = "flow",
    direction = "horizontal"
  })
  titlebar.style.horizontal_spacing = 8
  titlebar.drag_target = frame

  local title = titlebar.add({
    type = "label",
    style = "frame_title",
    caption = { "emof-framework.tag-dialog-title" }
  })
  title.ignored_by_interaction = true

  local filler = titlebar.add({
    type = "empty-widget",
    style = "draggable_space_header"
  })
  filler.style.height = 24
  filler.style.horizontally_stretchable = true
  filler.style.right_margin = 4
  filler.ignored_by_interaction = true

  titlebar.add({
    type = "sprite-button",
    name = M.GUI.cancel,
    style = "cancel_close_button",
    sprite = "utility/close",
    tooltip = { "gui.close" }
  })

  local inner_frame = frame.add({
    type = "frame",
    direction = "vertical",
    style = "entity_frame"
  })
  inner_frame.style.horizontally_stretchable = true

  local content = inner_frame.add({
    type = "flow",
    direction = "vertical",
    style = "inset_frame_container_vertical_flow"
  })
  content.style.horizontally_stretchable = true

  local top_row = content.add({
    type = "flow",
    direction = "horizontal",
    style = "player_input_horizontal_flow"
  })
  top_row.style.horizontally_stretchable = true

  local icon_picker = top_row.add({
    type = "choose-elem-button",
    name = M.GUI.icon,
    elem_type = "signal",
    style = "slot_button_in_shallow_frame"
  })
  icon_picker.elem_value = pending_tag.icon

  local text = top_row.add({
    type = "textfield",
    name = M.GUI.text,
    text = pending_tag.text or "",
    style = "textbox",
    icon_selector = true
  })
  text.style.maximal_width = 0
  text.style.horizontally_stretchable = true

  local footer = frame.add({
    type = "flow",
    direction = "horizontal",
    style = "dialog_buttons_horizontal_flow"
  })
  footer.style.top_margin = 6

  local footer_filler = footer.add({
    type = "empty-widget",
    style = "draggable_space"
  })
  footer_filler.style.horizontally_stretchable = true
  footer_filler.style.vertically_stretchable = true
  footer_filler.drag_target = frame

  footer.add({
    type = "button",
    name = M.GUI.confirm,
    style = "confirm_button",
    caption = { "emof-framework.tag-dialog-confirm" },
    enabled = false
  })

  M.sync_confirm_state(player)
end

function M.can_confirm(player)
  local dialog = get_dialog(player)
  if not (dialog and dialog.valid) then
    return false
  end

  local icon_picker = element_tree.find_descendant(dialog, M.GUI.icon)
  local text_field = element_tree.find_descendant(dialog, M.GUI.text)
  local icon = icon_picker and icon_picker.elem_value or nil
  local text = text_field and text_field.text or ""

  return tag_logic.setup_has_content(icon, text)
end

function M.sync_confirm_state(player)
  local dialog = get_dialog(player)
  if not (dialog and dialog.valid) then
    return
  end

  local confirm = element_tree.find_descendant(dialog, M.GUI.confirm)
  if confirm and confirm.valid then
    confirm.enabled = M.can_confirm(player)
  end
end

function M.close(player)
  local dialog = get_dialog(player)
  if dialog and dialog.valid then
    dialog.destroy()
  end
end

function M.read_inputs(player, pending_tag)
  local dialog = get_dialog(player)
  if not (dialog and dialog.valid) then
    return false
  end

  local icon_picker = element_tree.find_descendant(dialog, M.GUI.icon)
  local text_field = element_tree.find_descendant(dialog, M.GUI.text)

  pending_tag.icon = icon_picker and icon_picker.elem_value or nil
  pending_tag.text = text_field and text_field.text or ""
  M.sync_confirm_state(player)
  return true
end

return M
