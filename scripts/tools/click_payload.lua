local view_context = require("scripts.map.view_context")

local M = {}

local function entity_at_cursor(player, cursor_position)
  if not (player and player.valid and cursor_position) then
    return nil
  end

  if not player.update_selected_entity then
    return nil
  end

  if player.clear_selected_entity then
    player.clear_selected_entity()
  end

  player.update_selected_entity(cursor_position)

  local selected = player.selected
  if selected and selected.valid then
    return selected
  end

  return nil
end

function M.build(player, event)
  if not (player and player.valid and event) then
    return nil
  end

  local cursor_position = event.cursor_position
  if not cursor_position then
    return nil
  end

  local surface = view_context.chart_surface(player)
  if not (surface and surface.valid) then
    return nil
  end

  local entity = entity_at_cursor(player, cursor_position)

  return {
    player_index = player.index,
    surface_index = surface.index,
    cursor_position = { x = cursor_position.x, y = cursor_position.y },
    tick = event.tick,
    entity = entity
  }
end

return M
