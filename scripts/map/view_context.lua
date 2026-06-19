local M = {}

function M.chart_surface(player)
  if not (player and player.valid) then
    return nil
  end

  local surface = player.surface
  if surface and surface.valid then
    return surface
  end

  local physical_surface = player.physical_surface
  if physical_surface and physical_surface.valid then
    return physical_surface
  end

  return nil
end

function M.is_chart_view(player)
  if not (player and player.valid) then
    return false
  end

  local render_mode = player.render_mode
  if render_mode == defines.render_mode.chart or render_mode == defines.render_mode.chart_zoomed_in then
    return true
  end

  return player.controller_type == defines.controllers.remote
end

function M.surface_index(player)
  local surface = M.chart_surface(player)
  return surface and surface.valid and surface.index or nil
end

function M.is_overlay_drawer_visible(player)
  if not M.is_chart_view(player) then
    return false
  end

  return player.render_mode ~= defines.render_mode.chart_zoomed_in
end

return M
