local M = {}

function M.from_index(player_index)
  if player_index == nil then
    return nil
  end

  local player = game.get_player(player_index)
  if player and player.valid then
    return player
  end

  return nil
end

function M.from_event(event)
  if not event then
    return nil
  end

  return M.from_index(event.player_index)
end

function M.require_index(player_index)
  if type(player_index) ~= "number" then
    error("Extensible Map Overlay Framework invalid field 'player_index': expected number")
  end

  local player = M.from_index(player_index)
  if not player then
    error(
      "Extensible Map Overlay Framework invalid field 'player_index': no valid player for index "
        .. tostring(player_index)
    )
  end

  return player
end

return M
