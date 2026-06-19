local panel = require("scripts.gui.panel")
local builtin = require("scripts.builtin.init")
local builtin_tools = require("scripts.api.builtin_tools")
local callbacks = require("scripts.api.callbacks")
local mod_data_loader = require("scripts.api.mod_data_loader")
local player_iteration = require("scripts.map.player_iteration")
local player_settings = require("scripts.map.player_settings")
local quickbar_guard = require("scripts.tools.quickbar_guard")
local registry = require("scripts.api.registry")
local remote_interface = require("scripts.api.remote_interface")
local settings_writer = require("scripts.map.settings_writer")
local emof_storage = require("scripts.emof_storage")
local tool_state = require("scripts.tools.tool_state")

local M = {}

local function initialize_players(opts)
  local merge_vanilla_settings = opts and opts.merge_vanilla_settings

  -- Persist map/chart settings for every saved player, including offline MP peers.
  player_iteration.each_saved(function(player)
    settings_writer.ensure_default_map_settings(player)
    if merge_vanilla_settings then
      settings_writer.merge_missing_vanilla_settings(player)
    end
  end)

  -- Panel and shortcut state only matter for connected players.
  player_iteration.each_connected(function(player)
    panel.refresh(player)
  end)
end

local function reload_button_registry()
  tool_state.cancel_all_players("configuration-changed")
  registry.clear_buttons()
  mod_data_loader.load_all()
  builtin_tools.register_tools()
  tool_state.prune_registered(function(id)
    return registry.get_tool(id) ~= nil
  end)
  registry.prune_extension_toggles()
  emof_storage.schedule_action_tool_validation()
end

function M.register_remote_interface()
  builtin.register()
  builtin_tools.register_remote_interface()
  remote_interface.register()
end

function M.on_init()
  emof_storage.ensure_storage()
  reload_button_registry()
  player_settings.hide_vanilla_map_options_for_all_players()
  initialize_players()
end

function M.on_configuration_changed()
  emof_storage.ensure_storage()
  reload_button_registry()
  player_settings.hide_vanilla_map_options_for_all_players()
  initialize_players({ merge_vanilla_settings = true })
  player_iteration.each_connected(quickbar_guard.clear_blocked_slots)
end

function M.on_load()
  -- Save load re-executes Lua modules, so module-level caches (tool_state.registered_specs,
  -- pollutant_display cache, input handler flags) start empty while registry specs remain
  -- in emof_storage. Rebuild runtime dispatch from the persisted registry here; see documentation.md.
  callbacks.rebuild_registered_tools()
  tool_state.sync_input_handlers()
end

return M
