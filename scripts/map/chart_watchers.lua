--- Tracks players who need periodic chart UI polling.
---
--- Only players with the Chart Controls panel open are polled on tick. Closing
--- the panel removes them entirely; entering/leaving chart view or zoom while
--- the panel stays open is handled by the watcher loop.

local emof_storage = require("scripts.emof_storage")
local player_resolution = require("scripts.player_resolution")

local M = {}

local function watcher_map()
  return emof_storage.get_chart_watchers()
end

function M.track(player_index)
  if player_index then
    watcher_map()[player_index] = true
  end
end

function M.untrack(player_index)
  if player_index then
    watcher_map()[player_index] = nil
  end
end

function M.sync_tracking(player_index, panel_open)
  if panel_open then
    M.track(player_index)
  else
    M.untrack(player_index)
  end
end

function M.each_tracked(callback)
  if not callback then
    return
  end

  local watchers = watcher_map()
  for player_index in pairs(watchers) do
    local player = player_resolution.from_index(player_index)
    if player then
      callback(player)
    else
      watchers[player_index] = nil
    end
  end
end

return M
