local constants = require("scripts.constants")
local registry = require("scripts.api.registry")
local validation = require("scripts.api.validation")

local M = {}

local function resolve_owning_mod(proto, data)
  if data.owning_mod then
    return data.owning_mod
  end

  local history = prototypes.get_history("mod-data", proto.name)
  if history and history.created then
    return history.created
  end

  error(
    "Extensible Map Overlay Framework could not resolve owning_mod for mod-data '"
      .. proto.name
      .. "'. Add data.owning_mod to the prototype."
  )
end

local function load_overlay(proto)
  local data = proto.data or {}
  local spec = validation.normalize_mod_data_spec(proto, data, resolve_owning_mod(proto, data))
  registry.register_overlay(validation.validate_overlay_toggle_spec(spec))
end

local function load_action(proto)
  local data = proto.data or {}
  local spec = validation.normalize_mod_data_spec(proto, data, resolve_owning_mod(proto, data))
  spec.size = data.size
  spec.tool_id = data.tool_id
  spec.tool_start = data.tool_start
  spec.enabled = data.enabled
  registry.register_action(validation.validate_action_button_spec(spec))
end

function M.load_all()
  for _, proto in pairs(prototypes.mod_data) do
    if proto.valid and proto.data_type == constants.MOD_DATA_TYPE.map_overlay_toggle then
      load_overlay(proto)
    elseif proto.valid and proto.data_type == constants.MOD_DATA_TYPE.map_action_button then
      load_action(proto)
    end
  end
end

return M
