--- Iteration helpers for `game.players` vs `game.connected_players`.
---
--- `each_saved` - every player record in the save, including offline multiplayer
--- players. Use for persisted settings (`map_view_settings`, `game_view_settings`)
--- during bootstrap and configuration reload so values are ready before reconnect.
---
--- `each_connected` - only online players. Use for runtime UI work (chart panel,
--- toggles, pollutant cache, map tools) and per-tick chart view polling.

local M = {}

function M.each_saved(callback)
  if not callback then
    return
  end

  for _, player in pairs(game.players) do
    if player and player.valid then
      callback(player)
    end
  end
end

function M.each_connected(callback)
  if not callback then
    return
  end

  for _, player in pairs(game.connected_players) do
    if player and player.valid then
      callback(player)
    end
  end
end

return M
