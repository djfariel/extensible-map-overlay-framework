local M = {}

local DEFAULT_FLAGS = { "only-in-cursor", "not-stackable", "spawnable" }

--- Build an item-with-label prototype for EMOF map cursor tools.
--- Other mods: require("__extensible-map-overlay-framework__/prototypes/emof-cursor-item")
function M.build(spec)
  if type(spec) ~= "table" then
    error("emof cursor item spec must be a table")
  end

  if type(spec.name) ~= "string" or spec.name == "" then
    error("emof cursor item requires a non-empty name")
  end

  if type(spec.icon) ~= "string" or spec.icon == "" then
    error("emof cursor item requires an icon path")
  end

  local item = {
    type = "item-with-label",
    name = spec.name,
    icon = spec.icon,
    icon_size = spec.icon_size or 64,
    draw_label_for_cursor_render = spec.draw_label_for_cursor_render ~= false,
    auto_recycle = false,
    hidden = spec.hidden ~= false,
    flags = spec.flags or DEFAULT_FLAGS,
    subgroup = spec.subgroup or "tool",
    stack_size = spec.stack_size or 1
  }

  if spec.localised_name ~= nil then
    item.localised_name = spec.localised_name
  end

  if spec.order ~= nil then
    item.order = spec.order
  end

  if spec.default_label_color ~= nil then
    item.default_label_color = spec.default_label_color
  end

  return item
end

return M
