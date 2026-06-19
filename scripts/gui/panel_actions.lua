local action_tools = require("scripts.gui.action_tools")
local callbacks = require("scripts.api.callbacks")
local constants = require("scripts.constants")
local element_tree = require("scripts.gui.element_tree")
local panel_layout = require("scripts.gui.panel_layout")
local registry = require("scripts.api.registry")
local visibility = require("scripts.map.visibility")

local M = {}

local ACTION_BUTTON_HEIGHT = 28
local ACTION_STYLE = "map_view_add_button"

local function action_caption(spec)
  if spec.sprite then
    return { "", "[img=" .. spec.sprite .. "] ", spec.caption or spec.id }
  end
  return spec.caption or spec.id
end

local function add_action_button(row, spec, player)
  local pressed = spec.tool_id ~= nil and action_tools.is_action_pressed(player, spec)
  local enabled = action_tools.is_action_enabled(player, spec)
  local width = spec.size == "full" and panel_layout.ACTION_FULL_WIDTH or panel_layout.ACTION_HALF_WIDTH

  local button = row.add({
    type = "button",
    name = constants.GUI.action_button_prefix .. spec.id,
    style = ACTION_STYLE,
    caption = action_caption(spec),
    tooltip = spec.tooltip or spec.caption,
    enabled = enabled
  })
  button.style.width = width
  button.style.height = ACTION_BUTTON_HEIGHT
  button.toggled = pressed
end

local function add_half_spacer(row)
  local spacer = row.add({
    type = "empty-widget"
  })
  spacer.style.minimal_width = panel_layout.ACTION_HALF_WIDTH
  spacer.style.maximal_width = panel_layout.ACTION_HALF_WIDTH
  spacer.style.height = ACTION_BUTTON_HEIGHT
end

local function build_actions(player)
  return visibility.filter_visible_specs(player, registry.get_action_specs_sorted())
end

function M.signature(player)
  local parts = {}
  for _, spec in ipairs(build_actions(player)) do
    parts[#parts + 1] = spec.id
  end
  return table.concat(parts, "\0")
end

function M.sync_states(panel, player)
  local container = panel[constants.GUI.actions_inset]
  if not (container and container.valid) then
    return
  end

  for _, spec in ipairs(build_actions(player)) do
    local button = element_tree.find_descendant(container, constants.GUI.action_button_prefix .. spec.id)
    if button and button.valid then
      button.toggled = spec.tool_id ~= nil and action_tools.is_action_pressed(player, spec)
      button.enabled = action_tools.is_action_enabled(player, spec)
    end
  end
end

function M.render(panel, player)
  local container = panel[constants.GUI.actions_inset]
  if not (container and container.valid) then
    return
  end

  container.clear()
  local actions_flow = container.add({ type = "flow", direction = "vertical" })
  actions_flow.style.vertical_spacing = 0

  local pending_half_row = nil
  local pending_half_count = 0

  for _, spec in ipairs(build_actions(player)) do
    if spec.size == "full" then
      if pending_half_row then
        add_half_spacer(pending_half_row)
        pending_half_row = nil
        pending_half_count = 0
      end

      local row = actions_flow.add({ type = "flow", direction = "horizontal" })
      row.style.horizontal_spacing = 0
      add_action_button(row, spec, player)
    else
      if not pending_half_row then
        pending_half_row = actions_flow.add({ type = "flow", direction = "horizontal" })
        pending_half_row.style.horizontal_spacing = 0
        pending_half_count = 0
      end

      add_action_button(pending_half_row, spec, player)
      pending_half_count = pending_half_count + 1
      if pending_half_count >= 2 then
        pending_half_row = nil
        pending_half_count = 0
      end
    end
  end

  if pending_half_row then
    add_half_spacer(pending_half_row)
  end
end

function M.on_button_clicked(player, id)
  local spec = registry.get_action(id)
  if not spec or not visibility.is_visible(player, spec) then
    return
  end

  if spec.tool_id then
    action_tools.handle_action_click(player, spec)
    return
  end

  callbacks.dispatch_action_click(player, spec)
end

return M
