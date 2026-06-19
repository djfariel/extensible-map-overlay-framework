local constants = require("scripts.constants")
local cursor = require("scripts.tools.cursor")
local gui_handler = require("scripts.handlers.gui")
local player_handler = require("scripts.handlers.player")
local quickbar_guard = require("scripts.tools.quickbar_guard")
local tool_state = require("scripts.tools.tool_state")
local validation = require("scripts.api.validation")

local M = {}

function M.register()
  script.on_event(defines.events.on_player_created, player_handler.on_player_created)
  script.on_event(defines.events.on_player_joined_game, player_handler.on_player_joined_game)
  script.on_event(defines.events.on_player_left_game, player_handler.on_player_left_game)
  script.on_event(defines.events.on_player_controller_changed, player_handler.on_player_controller_changed)
  script.on_event(defines.events.on_player_changed_surface, player_handler.on_player_changed_surface)
  script.on_event(defines.events.on_tick, player_handler.on_tick)

  script.on_event(defines.events.on_gui_click, gui_handler.on_gui_click)
  script.on_event(defines.events.on_gui_elem_changed, gui_handler.on_gui_elem_changed)
  script.on_event(defines.events.on_gui_text_changed, gui_handler.on_gui_text_changed)
  script.on_event(defines.events.on_gui_closed, gui_handler.on_gui_closed)
  script.on_event(defines.events.on_lua_shortcut, gui_handler.on_lua_shortcut)
  script.on_event(defines.events.on_player_cursor_stack_changed, tool_state.handle_cursor_changed)
  script.on_event(defines.events.on_player_set_quick_bar_slot, quickbar_guard.on_player_set_quick_bar_slot)
  script.on_event(defines.events.on_string_translated, function(event)
    cursor.handle_string_translated(event)
  end)
  script.on_event(constants.CUSTOM_INPUT.toggle_panel, gui_handler.on_toggle_panel_input)

  script.on_event(constants.CUSTOM_EVENT.registry_changed, player_handler.on_registry_changed)
  script.on_event(constants.CUSTOM_EVENT.player_toggle_changed, player_handler.on_player_toggle_changed)
  script.on_event(constants.CUSTOM_EVENT.action_state_changed, player_handler.on_action_state_changed)

  script.on_nth_tick(1, validation.run_pending_action_tool_validation)

  tool_state.sync_input_handlers()
end

return M
