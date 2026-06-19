local emof_storage = require("scripts.emof_storage")
local vanilla_overlays = require("scripts.map.vanilla_overlays")

local M = {}

local function write_map_setting(player, key, value)
  local update = {}
  update[key] = value
  player.map_view_settings = update
end

function M.get_vanilla_toggle(state, overlay)
  local value = state.vanilla_toggles[overlay.map_key]
  if value == nil then
    value = overlay.default_value
    state.vanilla_toggles[overlay.map_key] = value
  end
  return value
end

function M.apply_vanilla_toggle(player, key, enabled)
  if not (player and player.valid) then
    return
  end

  local state = emof_storage.get_player_state(player.index)
  state.vanilla_toggles[key] = enabled
  write_map_setting(player, key, enabled)
end

function M.ensure_default_map_settings(player)
  if not (player and player.valid) then
    return
  end

  local state = emof_storage.get_player_state(player.index)
  if state.initialized_map_settings then
    return
  end

  local initial = {}
  for _, overlay in ipairs(vanilla_overlays.get_all()) do
    local value = M.get_vanilla_toggle(state, overlay)
    initial[overlay.map_key] = value
  end

  player.map_view_settings = initial
  state.initialized_map_settings = true
end

function M.merge_missing_vanilla_settings(player)
  if not (player and player.valid) then
    return
  end

  local state = emof_storage.get_player_state(player.index)
  if not state.initialized_map_settings then
    return
  end

  local update = {}
  for _, overlay in ipairs(vanilla_overlays.get_all()) do
    if state.vanilla_toggles[overlay.map_key] == nil then
      local value = M.get_vanilla_toggle(state, overlay)
      update[overlay.map_key] = value
    end
  end

  if next(update) ~= nil then
    player.map_view_settings = update
  end
end

return M
