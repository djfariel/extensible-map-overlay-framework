local callbacks = require("scripts.api.callbacks")
local constants = require("scripts.constants")
local ping_logic = require("scripts.placement.ping")
local player_resolution = require("scripts.player_resolution")
local tag_logic = require("scripts.placement.tag")
local tag_setup = require("scripts.builtin.tag.setup")

local M = {}

local function with_player(payload, handler, invalid_result)
  local player = player_resolution.from_index(payload.player_index)
  if not player then
    return invalid_result
  end

  return handler(player)
end

local function ping_on_click(payload)
  return with_player(payload, function(player)
    return ping_logic.try_ping(player, payload)
  end, "done")
end

local function tag_on_click(payload)
  return with_player(payload, function(player)
    local tag_options = payload.data or {}
    local text = tag_options.text or ""
    local pending_tag = {
      position = payload.cursor_position,
      surface_index = payload.surface_index,
      icon = tag_logic.resolve_chart_tag_icon(tag_options.icon, text),
      text = text
    }

    if tag_logic.confirm_pending_tag(player, pending_tag) then
      return "done"
    end

    return "continue"
  end, "done")
end

local function tag_setup_open(payload)
  with_player(payload, function(player)
    tag_setup.start_setup(player)
  end)
end

local function tag_setup_cancel(payload)
  with_player(payload, function(player)
    tag_setup.cancel_setup(player)
  end)
end

local function tag_setup_is_open(payload)
  return with_player(payload, function(player)
    return tag_setup.is_setup_open(player)
  end, false)
end

function M.register_remote_interface()
  remote.add_interface(constants.BUILTIN_REMOTE_INTERFACE, {
    ping_on_click = ping_on_click,
    tag_on_click = tag_on_click,
    tag_setup_open = tag_setup_open,
    tag_setup_cancel = tag_setup_cancel,
    tag_setup_is_open = tag_setup_is_open
  })
end

function M.register_tools()
  callbacks.register_map_tool({
    id = constants.BUILTIN_TOOL.ping,
    owning_mod = constants.OWNING_MOD,
    order = "0000",
    cursor_item = constants.CURSOR_TOOL.ping,
    cursor_label = { "item-name.emof-ping-tool" },
    on_click = {
      interface = constants.BUILTIN_REMOTE_INTERFACE,
      function_name = "ping_on_click"
    }
  })

  callbacks.register_map_tool({
    id = constants.BUILTIN_TOOL.tag,
    owning_mod = constants.OWNING_MOD,
    order = "0001",
    cursor_item = constants.CURSOR_TOOL.tag,
    on_click = {
      interface = constants.BUILTIN_REMOTE_INTERFACE,
      function_name = "tag_on_click"
    },
    setup = {
      open = {
        interface = constants.BUILTIN_REMOTE_INTERFACE,
        function_name = "tag_setup_open"
      },
      cancel = {
        interface = constants.BUILTIN_REMOTE_INTERFACE,
        function_name = "tag_setup_cancel"
      },
      is_open = {
        interface = constants.BUILTIN_REMOTE_INTERFACE,
        function_name = "tag_setup_is_open"
      }
    }
  })
end

return M
