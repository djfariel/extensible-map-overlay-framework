local constants = require("scripts.constants")
local registry = require("scripts.api.registry")
local emof_storage = require("scripts.emof_storage")

local M = {}

local function assert_type(value, expected, field_name)
  if type(value) ~= expected then
    error("Extensible Map Overlay Framework invalid field '" .. field_name .. "': expected " .. expected)
  end
end

local function assert_non_empty_string(value, field_name)
  assert_type(value, "string", field_name)
  if value == "" then
    error("Extensible Map Overlay Framework invalid field '" .. field_name .. "': must not be empty")
  end
end

local function assert_cursor_label(value, field_name)
  local value_type = type(value)
  if value_type == "string" then
    if value == "" then
      error("Extensible Map Overlay Framework invalid field '" .. field_name .. "': must not be empty")
    end
    return
  end

  if value_type == "table" then
    if next(value) == nil then
      error("Extensible Map Overlay Framework invalid field '" .. field_name .. "': must not be empty")
    end
    return
  end

  error(
    "Extensible Map Overlay Framework invalid field '"
      .. field_name
      .. "': expected string or localised string table"
  )
end

local function validate_callback(callback, field_name)
  assert_type(callback, "table", field_name)
  assert_non_empty_string(callback.interface, field_name .. ".interface")
  assert_non_empty_string(callback.function_name, field_name .. ".function_name")
end

local function normalize_visible_when(visible_when, field_name)
  if visible_when == nil then
    return nil
  end

  assert_type(visible_when, "table", field_name)

  if visible_when.surfaces ~= nil then
    assert_type(visible_when.surfaces, "table", field_name .. ".surfaces")
    for index, surface_name in ipairs(visible_when.surfaces) do
      assert_non_empty_string(surface_name, field_name .. ".surfaces[" .. index .. "]")
    end
  end

  if visible_when.remote_view_only ~= nil then
    assert_type(visible_when.remote_view_only, "boolean", field_name .. ".remote_view_only")
  end

  return {
    surfaces = visible_when.surfaces,
    remote_view_only = visible_when.remote_view_only
  }
end

function M.normalize_mod_data_spec(proto, data, owning_mod)
  local spec = {
    id = proto.name,
    owning_mod = owning_mod,
    order = proto.order or proto.name
  }

  if proto.localised_name then
    spec.caption = proto.localised_name
  end

  if proto.localised_description then
    spec.tooltip = proto.localised_description
  end

  if data.caption then
    spec.caption = { data.caption }
  end

  if data.tooltip then
    spec.tooltip = { data.tooltip }
  end

  if data.sprite then
    spec.sprite = data.sprite
  end

  if data.visible_when then
    spec.visible_when = data.visible_when
  end

  return spec
end

local function normalize_common(spec)
  assert_type(spec, "table", "spec")
  assert_non_empty_string(spec.id, "id")
  assert_non_empty_string(spec.owning_mod, "owning_mod")

  if spec.order ~= nil then
    assert_non_empty_string(spec.order, "order")
  end

  if spec.sprite ~= nil then
    assert_non_empty_string(spec.sprite, "sprite")
  end

  return {
    id = spec.id,
    owning_mod = spec.owning_mod,
    order = spec.order or spec.id,
    caption = spec.caption,
    tooltip = spec.tooltip,
    sprite = spec.sprite,
    visible_when = normalize_visible_when(spec.visible_when, "visible_when")
  }
end

function M.validate_overlay_toggle_spec(spec)
  return normalize_common(spec)
end

local function assert_registered_tool_id(tool_id, context)
  if registry.get_tool(tool_id) then
    return
  end

  error(
    "Extensible Map Overlay Framework unregistered tool_id '"
      .. tool_id
      .. "' referenced by "
      .. context
  )
end

local function assert_tool_has_setup(tool_id, context)
  local tool_spec = registry.get_tool(tool_id)
  if tool_spec and tool_spec.setup then
    return
  end

  error(
    "Extensible Map Overlay Framework "
      .. context
      .. " requires setup handlers on map tool '"
      .. tool_id
      .. "'"
  )
end

function M.validate_action_tool_reference(spec)
  if not (spec and spec.tool_id) then
    return
  end

  local context = "action button '" .. spec.id .. "'"
  assert_registered_tool_id(spec.tool_id, context)

  if spec.tool_start == constants.TOOL_START.setup then
    assert_tool_has_setup(spec.tool_id, context)
  end
end

function M.validate_all_action_tool_references()
  for _, spec in ipairs(registry.get_action_specs_sorted()) do
    M.validate_action_tool_reference(spec)
  end
end

function M.run_pending_action_tool_validation()
  if not emof_storage.consume_action_tool_validation_pending() then
    return
  end

  M.validate_all_action_tool_references()
end

function M.validate_action_button_spec(spec, opts)
  local normalized = normalize_common(spec)

  local size = spec.size
  if size == nil then
    size = "half"
  end

  if size ~= "half" and size ~= "full" then
    error("Extensible Map Overlay Framework invalid field 'size': expected 'half' or 'full'")
  end

  normalized.size = size

  if spec.tool_id ~= nil then
    assert_non_empty_string(spec.tool_id, "tool_id")
    normalized.tool_id = spec.tool_id

    local tool_start = spec.tool_start
    if tool_start == nil then
      tool_start = "immediate"
    end

    if tool_start ~= "immediate" and tool_start ~= "setup" then
      error(
        "Extensible Map Overlay Framework invalid field 'tool_start': expected 'immediate' or 'setup'"
      )
    end

    normalized.tool_start = tool_start
  elseif spec.tool_start ~= nil then
    error("Extensible Map Overlay Framework invalid field 'tool_start': requires tool_id")
  end

  if spec.enabled ~= nil then
    validate_callback(spec.enabled, "enabled")
    normalized.enabled = {
      interface = spec.enabled.interface,
      function_name = spec.enabled.function_name
    }
  end

  if opts and opts.require_registered_tool then
    M.validate_action_tool_reference(normalized)
  end

  return normalized
end

function M.validate_map_tool(spec)
  local normalized = normalize_common(spec)
  assert_non_empty_string(spec.cursor_item, "cursor_item")
  validate_callback(spec.on_click, "on_click")

  if spec.on_cancel ~= nil then
    validate_callback(spec.on_cancel, "on_cancel")
    normalized.on_cancel = {
      interface = spec.on_cancel.interface,
      function_name = spec.on_cancel.function_name
    }
  end

  if spec.cursor_label ~= nil then
    assert_cursor_label(spec.cursor_label, "cursor_label")
  end

  if spec.cursor_label_color ~= nil then
    assert_type(spec.cursor_label_color, "table", "cursor_label_color")
  end

  normalized.cursor_item = spec.cursor_item
  normalized.cursor_label = spec.cursor_label
  normalized.cursor_label_color = spec.cursor_label_color
  normalized.on_click = {
    interface = spec.on_click.interface,
    function_name = spec.on_click.function_name
  }

  if spec.setup ~= nil then
    assert_type(spec.setup, "table", "setup")
    validate_callback(spec.setup.open, "setup.open")
    validate_callback(spec.setup.cancel, "setup.cancel")

    normalized.setup = {
      open = {
        interface = spec.setup.open.interface,
        function_name = spec.setup.open.function_name
      },
      cancel = {
        interface = spec.setup.cancel.interface,
        function_name = spec.setup.cancel.function_name
      }
    }

    if spec.setup.is_open ~= nil then
      validate_callback(spec.setup.is_open, "setup.is_open")
      normalized.setup.is_open = {
        interface = spec.setup.is_open.interface,
        function_name = spec.setup.is_open.function_name
      }
    end
  end

  return normalized
end

return M
