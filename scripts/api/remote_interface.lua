-- Remote surface for consumer mods. Error policy is mixed by design - see
-- documentation.md (Remote API error handling) before calling from reload handlers.

local callbacks = require("scripts.api.callbacks")
local constants = require("scripts.constants")
local panel = require("scripts.gui.panel")
local player_resolution = require("scripts.player_resolution")

local M = {}

function M.register()
  remote.add_interface(constants.INTERFACE_NAME, {
    register_overlay_toggle = callbacks.register_overlay_toggle,
    register_action_button = callbacks.register_action_button,
    register_map_tool = callbacks.register_map_tool,
    try_register_map_tool = callbacks.try_register_map_tool,
    start_map_tool = callbacks.start_map_tool,
    cancel_map_tool = callbacks.cancel_map_tool,
    unregister = callbacks.unregister,
    set_player_toggle = callbacks.set_player_toggle,
    get_player_toggle = callbacks.get_player_toggle,
    sync_chart_controls = function(player_index)
      local player = player_resolution.from_index(player_index)
      if player then
        panel.sync(player)
      end
    end,
    get_map_panel_name = function()
      return constants.GUI.map_panel
    end,
    get_extension_slot_name = function()
      return constants.GUI.extension_slot
    end,
    get_tool_state_changed_event = function()
      return constants.PUBLIC_EVENT.tool_state_changed
    end
  })
end

return M
