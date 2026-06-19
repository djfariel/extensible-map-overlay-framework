local player_iteration = require("scripts.map.player_iteration")

local M = {}

function M.hide_vanilla_map_options_for_player(player)
  if not (player and player.valid) then
    return
  end

  player.game_view_settings.show_map_view_options = false
end

function M.hide_vanilla_map_options_for_all_players()
  player_iteration.each_saved(function(player)
    M.hide_vanilla_map_options_for_player(player)
  end)
end

return M
