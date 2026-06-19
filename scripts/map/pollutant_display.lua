-- Per-tick pollutant icon cache (module-local). Cleared on player leave; empty after save
-- load. Does not require an on_load rebuild.

local view_context = require("scripts.map.view_context")

local M = {}

local cache_by_player = {}

local function resolve_uncached(player)
  local surface = view_context.chart_surface(player)
  if not (surface and surface.valid) then
    return nil
  end

  local pollutant = surface.pollutant_type
  if not (pollutant and pollutant.valid) then
    return nil
  end

  local sprite = "airborne-pollutant/" .. pollutant.name
  if not helpers.is_valid_sprite_path(sprite) then
    sprite = "utility/missing_icon"
  end

  return {
    pollutant_name = pollutant.name,
    caption = pollutant.localised_name,
    tooltip = pollutant.localised_name,
    sprite = sprite
  }
end

function M.resolve_cached(player)
  if not (player and player.valid) then
    return nil
  end

  local tick = game.tick
  local entry = cache_by_player[player.index]
  if entry and entry.tick == tick then
    return entry.display
  end

  local display = resolve_uncached(player)
  cache_by_player[player.index] = {
    tick = tick,
    display = display
  }
  return display
end

function M.clear_cache(player_index)
  cache_by_player[player_index] = nil
end

return M
