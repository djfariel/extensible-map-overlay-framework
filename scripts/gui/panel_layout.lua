local constants = require("scripts.constants")

local M = {}

M.PANEL_WIDTH = 256
M.PANEL_DEFAULT_RIGHT_MARGIN = 16
M.ACTION_FULL_WIDTH = 240
M.ACTION_HALF_WIDTH = M.ACTION_FULL_WIDTH / 2
M.EXTENSION_SLOT_PADDING = 8
M.EXTENSION_SLOT_TOP_MARGIN = 8
M.OVERLAY_REGION_TOP_MARGIN = 8
M.TITLEBAR_NAME = "emof_titlebar"
M.CLOSE_BUTTON_NAME = "emof_close_button"

function M.get_panel(player)
  return player.gui.screen[constants.GUI.map_panel]
end

function M.read_panel_location(panel)
  if not (panel and panel.valid) then
    return nil
  end

  local ok, location = pcall(function()
    return panel.location
  end)

  if not (ok and location and location.x and location.y) then
    return nil
  end

  return { x = location.x, y = location.y }
end

local function read_panel_size(panel)
  if not (panel and panel.valid) then
    return { width = M.PANEL_WIDTH, height = 240 }
  end

  local ok, size = pcall(function()
    return panel.get_size and panel.get_size() or nil
  end)

  if ok and size and size.width and size.height and size.width > 0 and size.height > 0 then
    return size
  end

  return { width = M.PANEL_WIDTH, height = 240 }
end

local function default_panel_location(player, panel)
  local resolution = player.display_resolution
  local scale = player.display_scale or 1
  if not (resolution and resolution.width and resolution.height) then
    return { x = 0, y = 0 }
  end

  local panel_size = read_panel_size(panel)
  local viewport_width = resolution.width / scale
  local viewport_height = resolution.height / scale

  local x = math.floor(viewport_width - M.PANEL_WIDTH - M.PANEL_DEFAULT_RIGHT_MARGIN)
  if x < 0 then
    x = 0
  end

  local y = math.floor((viewport_height - panel_size.height) / 2)
  if y < 0 then
    y = 0
  end

  return { x = x, y = y }
end

function M.apply_saved_or_default_location(player, panel, state)
  local location = state.panel_location
  if not location then
    location = default_panel_location(player, panel)
    state.panel_location = { x = location.x, y = location.y }
  end

  panel.location = { x = location.x, y = location.y }
end

local function apply_extension_slot_style(slot)
  slot.style.width = M.ACTION_FULL_WIDTH
  slot.style.padding = M.EXTENSION_SLOT_PADDING
  slot.style.top_margin = M.EXTENSION_SLOT_TOP_MARGIN
end

local function apply_overlay_region_style(region)
  if not (region and region.valid) then
    return
  end

  region.style.width = M.ACTION_FULL_WIDTH
  region.style.top_margin = M.OVERLAY_REGION_TOP_MARGIN
end

function M.apply_panel_section_styles(panel)
  apply_overlay_region_style(panel[constants.GUI.overlay_region])

  local slot = panel[constants.GUI.extension_slot]
  if slot and slot.valid and slot.type == "frame" then
    apply_extension_slot_style(slot)
  end
end

function M.ensure_extension_slot(panel)
  local slot = panel[constants.GUI.extension_slot]
  if slot and slot.valid and slot.type == "frame" then
    apply_extension_slot_style(slot)
    return slot
  end

  if slot and slot.valid then
    slot.destroy()
  end

  slot = panel.add({
    type = "frame",
    name = constants.GUI.extension_slot,
    direction = "vertical",
    style = "deep_frame_in_shallow_frame"
  })
  apply_extension_slot_style(slot)
  slot.visible = false
  return slot
end

function M.get_or_create_panel(player)
  local panel = M.get_panel(player)
  if panel and panel.valid then
    return panel, false
  end

  panel = player.gui.screen.add({
    type = "frame",
    name = constants.GUI.map_panel,
    direction = "vertical",
    style = "frame"
  })
  panel.auto_center = false
  panel.style.padding = 4
  panel.style.width = M.PANEL_WIDTH
  panel.style.horizontally_stretchable = false
  panel.style.vertically_stretchable = false
  panel.style.vertically_squashable = false

  local titlebar = panel.add({
    type = "flow",
    name = M.TITLEBAR_NAME,
    direction = "horizontal",
    style = "frame_header_flow"
  })

  local title = titlebar.add({
    type = "label",
    caption = { "emof-framework.panel-title" }
  })
  title.style = "frame_title"
  title.ignored_by_interaction = true

  local filler = titlebar.add({
    type = "empty-widget",
    style = "draggable_space_header"
  })
  filler.style.horizontally_stretchable = true
  filler.style.height = 24
  filler.drag_target = panel

  titlebar.add({
    type = "sprite-button",
    name = M.CLOSE_BUTTON_NAME,
    style = "frame_action_button",
    sprite = "utility/close",
    hovered_sprite = "utility/close_black",
    clicked_sprite = "utility/close_black",
    tooltip = { "gui.close" }
  })

  local actions = panel.add({
    type = "frame",
    name = constants.GUI.actions_inset,
    direction = "vertical",
    style = "deep_frame_in_shallow_frame"
  })
  actions.style.width = M.ACTION_FULL_WIDTH

  local overlays = panel.add({
    type = "frame",
    name = constants.GUI.overlay_region,
    direction = "vertical",
    style = "slot_button_deep_frame"
  })
  overlays.style.width = M.ACTION_FULL_WIDTH
  apply_overlay_region_style(overlays)

  M.ensure_extension_slot(panel)

  return panel, true
end

function M.clear_layout_cache(state)
  state.cached_action_signature = nil
  state.cached_overlay_signature = nil
end

return M
