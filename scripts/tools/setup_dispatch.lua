local callbacks = require("scripts.api.callbacks")
local registry = require("scripts.api.registry")

local M = {}

function M.has_setup(tool_id)
  local spec = registry.get_tool(tool_id)
  return spec ~= nil and spec.setup ~= nil and spec.setup.open ~= nil
end

function M.is_open(player, tool_id)
  return callbacks.is_tool_setup_open(player.index, tool_id)
end

function M.open(player, tool_id)
  return callbacks.open_tool_setup(player.index, tool_id)
end

function M.cancel(player, tool_id)
  return callbacks.cancel_tool_setup(player.index, tool_id)
end

function M.cancel_any_open(player)
  callbacks.cancel_any_tool_setup(player.index)
end

return M
