local player_iteration = require("scripts.map.player_iteration")
local view_context = require("scripts.map.view_context")

local M = {}

function M.set_vanilla_map_options_visible(player, visible)
  if not (player and player.valid and player.game_view_settings) then
    return
  end

  player.game_view_settings.show_map_view_options = visible and true or false
end

function M.sync_vanilla_map_options_for_player(player)
  if not (player and player.valid) then
    return
  end

  M.set_vanilla_map_options_visible(player, not view_context.is_chart_view(player))
end

-- Temporary wrappers until bootstrap/handler call sites are updated (Task 3).
function M.hide_vanilla_map_options_for_player(player)
  M.set_vanilla_map_options_visible(player, false)
end

function M.hide_vanilla_map_options_for_all_players()
  player_iteration.each_saved(function(player)
    M.hide_vanilla_map_options_for_player(player)
  end)
end

return M
