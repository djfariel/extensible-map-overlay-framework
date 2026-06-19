local constants = require("scripts.constants")
local emof_storage = require("scripts.emof_storage")

local M = {}

local KIND_LABEL = {
  overlay_specs = "overlay toggle",
  action_specs = "action button",
  tool_specs = "map tool"
}

local KIND_TO_SPECS = {
  [constants.REGISTRATION_KIND.overlay] = "overlay_specs",
  [constants.REGISTRATION_KIND.action] = "action_specs",
  [constants.REGISTRATION_KIND.tool] = "tool_specs"
}

local function duplicate_id_error(kind, id, first_owner, second_owner)
  error(
    "Extensible Map Overlay Framework duplicate "
      .. (KIND_LABEL[kind] or "registration")
      .. " id:\n"
      .. "  id: "
      .. id
      .. "\n"
      .. "  first owner: "
      .. first_owner
      .. "\n"
      .. "  second owner: "
      .. second_owner
      .. "\n"
      .. "This is a mod incompatibility and should be reported."
  )
end

local function sort_specs(specs_by_id)
  local sorted = {}
  for _, spec in pairs(specs_by_id) do
    sorted[#sorted + 1] = spec
  end

  table.sort(sorted, function(a, b)
    if a.order ~= b.order then
      return a.order < b.order
    end
    return a.id < b.id
  end)

  return sorted
end

local function register_spec(kind, spec)
  local registry = emof_storage.get_registry()
  local existing = registry[kind][spec.id]
  if existing then
    duplicate_id_error(kind, spec.id, existing.owning_mod, spec.owning_mod)
  end

  registry[kind][spec.id] = spec
end

local function clear_extension_toggle(id)
  for _, state in pairs(emof_storage.get_all_players()) do
    state.extension_toggles[id] = nil
  end
end

function M.register_overlay(spec)
  register_spec("overlay_specs", spec)
end

function M.register_action(spec)
  register_spec("action_specs", spec)
end

function M.register_tool(spec)
  register_spec("tool_specs", spec)
end

function M.get_overlay(id)
  local registry = emof_storage.get_registry()
  return registry.overlay_specs[id]
end

function M.get_action(id)
  local registry = emof_storage.get_registry()
  return registry.action_specs[id]
end

function M.get_tool(id)
  local registry = emof_storage.get_registry()
  return registry.tool_specs[id]
end

function M.get_overlay_specs_sorted()
  local registry = emof_storage.get_registry()
  return sort_specs(registry.overlay_specs)
end

function M.get_action_specs_sorted()
  local registry = emof_storage.get_registry()
  return sort_specs(registry.action_specs)
end

function M.clear_buttons()
  local registry = emof_storage.get_registry()
  registry.overlay_specs = {}
  registry.action_specs = {}
  registry.tool_specs = {}
end

function M.prune_extension_toggles()
  local registry = emof_storage.get_registry()

  for _, state in pairs(emof_storage.get_all_players()) do
    for id in pairs(state.extension_toggles) do
      if registry.overlay_specs[id] == nil then
        state.extension_toggles[id] = nil
      end
    end
  end
end

function M.get_tool_specs()
  local registry = emof_storage.get_registry()
  return registry.tool_specs
end

function M.unregister(mod_name, id, kind)
  if type(mod_name) ~= "string" or mod_name == "" or type(id) ~= "string" or id == "" then
    return false
  end

  local spec_key = KIND_TO_SPECS[kind]
  if not spec_key then
    return false
  end

  local registry = emof_storage.get_registry()
  local spec = registry[spec_key][id]
  if not (spec and spec.owning_mod == mod_name) then
    return false
  end

  registry[spec_key][id] = nil

  if kind == constants.REGISTRATION_KIND.overlay then
    clear_extension_toggle(id)
  end

  return true
end

return M
