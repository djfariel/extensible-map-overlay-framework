local constants = require("scripts.constants")
local public_events = require("scripts.api.public_events")

local M = {}

function M.raise(player_index, detail)
  local payload = {
    player_index = player_index,
    active_tool_id = detail and detail.active_tool_id or nil,
    cancelled_tool_id = detail and detail.cancelled_tool_id or nil,
    reason = detail and detail.reason or nil
  }

  script.raise_event(public_events.event_id(constants.PUBLIC_EVENT.tool_state_changed), payload)
  script.raise_event(constants.CUSTOM_EVENT.action_state_changed, {
    player_index = player_index
  })
end

return M
