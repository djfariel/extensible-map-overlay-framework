local view_context = require("scripts.map.view_context")

local M = {}

local function matches_surface(player, surfaces)
  if not surfaces then
    return true
  end

  local chart_surface = view_context.chart_surface(player)
  if not (chart_surface and chart_surface.valid) then
    return false
  end

  for _, surface_name in ipairs(surfaces) do
    if surface_name == chart_surface.name then
      return true
    end
  end

  return false
end

function M.is_visible(player, spec)
  local visible_when = spec.visible_when
  if not visible_when then
    return true
  end

  if not matches_surface(player, visible_when.surfaces) then
    return false
  end

  if visible_when.remote_view_only and player.controller_type ~= defines.controllers.remote then
    return false
  end

  return true
end

function M.filter_visible_specs(player, specs)
  local visible = {}

  for _, spec in ipairs(specs) do
    if M.is_visible(player, spec) then
      visible[#visible + 1] = spec
    end
  end

  return visible
end

return M
