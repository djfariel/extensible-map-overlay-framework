local M = {}

local function ensure_registry(root)
  root.registry = root.registry or {}
  root.registry.overlay_specs = root.registry.overlay_specs or {}
  root.registry.action_specs = root.registry.action_specs or {}
  root.registry.tool_specs = root.registry.tool_specs or {}
end

local function ensure_tag_setup(root)
  root.builtin_tag_setup = root.builtin_tag_setup or {}
end

local function ensure_players(root)
  root.players = root.players or {}
end

local function ensure_cursor_label_requests(root)
  root.cursor_label_requests = root.cursor_label_requests or {}
end

local function normalize_player_state(state)
  if state.panel_open == nil then
    state.panel_open = true
  end
end

function M.ensure_storage()
  storage.emof = storage.emof or {}
  ensure_registry(storage.emof)
  ensure_players(storage.emof)
  ensure_tag_setup(storage.emof)
  ensure_cursor_label_requests(storage.emof)
  if storage.emof.validate_action_tools_pending == nil then
    storage.emof.validate_action_tools_pending = false
  end
  storage.emof.chart_watchers = storage.emof.chart_watchers or {}
end

function M.schedule_action_tool_validation()
  M.ensure_storage()
  storage.emof.validate_action_tools_pending = true
end

function M.consume_action_tool_validation_pending()
  M.ensure_storage()
  if not storage.emof.validate_action_tools_pending then
    return false
  end

  storage.emof.validate_action_tools_pending = false
  return true
end

function M.get_registry()
  M.ensure_storage()
  return storage.emof.registry
end

function M.get_all_players()
  M.ensure_storage()
  return storage.emof.players
end

function M.get_cursor_label_requests()
  M.ensure_storage()
  return storage.emof.cursor_label_requests
end

function M.get_chart_watchers()
  M.ensure_storage()
  return storage.emof.chart_watchers
end

function M.get_player_state(player_index)
  M.ensure_storage()

  local players = storage.emof.players
  local state = players[player_index]

  if state then
    normalize_player_state(state)
    return state
  end

  state = {
    panel_visible = false,
    panel_open = true,
    panel_location = nil,
    overlay_drawer_visible = false,
    last_pollutant_name = nil,
    initialized_map_settings = false,
    vanilla_toggles = {},
    extension_toggles = {},
    active_tool = nil
  }

  players[player_index] = state
  return state
end

function M.remove_player(player_index)
  M.ensure_storage()
  storage.emof.players[player_index] = nil
  storage.emof.chart_watchers[player_index] = nil
  M.clear_tag_setup_state(player_index)
end

function M.get_tag_setup_state(player_index)
  M.ensure_storage()
  local all = storage.emof.builtin_tag_setup
  local state = all[player_index]
  if not state then
    state = {
      icon = nil,
      text = ""
    }
    all[player_index] = state
  end
  return state
end

function M.clear_tag_setup_state(player_index)
  M.ensure_storage()
  storage.emof.builtin_tag_setup[player_index] = nil
end

return M
