local M = {}

local function color_component(color, key, index, fallback)
  if color[key] ~= nil then
    return color[key]
  end

  if color[index] ~= nil then
    return color[index]
  end

  return fallback
end

function M.colored_player_name(player)
  if not (player and player.valid) then
    return ""
  end

  local color = player.chat_color or player.color
  if not color then
    return player.name
  end

  local r = color_component(color, "r", 1, 1)
  local g = color_component(color, "g", 2, 1)
  local b = color_component(color, "b", 3, 1)
  local a = color_component(color, "a", 4, 1)

  if a ~= 1 then
    return string.format("[color=%g,%g,%g,%g]%s[/color]", r, g, b, a, player.name)
  end

  return string.format("[color=%g,%g,%g]%s[/color]", r, g, b, player.name)
end

function M.rich_tag_for_ping_target(entity)
  if not (entity and entity.valid) then
    return nil
  end

  local tag = "[entity=" .. entity.name .. "]"
  if entity.gps_tag then
    tag = tag .. entity.gps_tag
  end

  return tag
end

function M.entity_for_click(player, payload)
  if not (player and player.valid and payload) then
    return nil
  end

  local ref = payload.selected_entity
  if ref and ref.unit_number then
    local entity = game.get_entity_by_unit_number(ref.unit_number)
    if entity and entity.valid then
      if ref.surface_index == nil or entity.surface.index == ref.surface_index then
        return entity
      end
    end
  end

  if payload.entity and payload.entity.valid then
    return payload.entity
  end

  return nil
end

local function rounded(value)
  if value >= 0 then
    return math.floor(value + 0.5)
  end
  return math.ceil(value - 0.5)
end

local function coordinate_gps_tag(surface, position)
  return "[gps="
    .. rounded(position.x)
    .. ","
    .. rounded(position.y)
    .. ","
    .. surface.name
    .. "]"
end

local function print_ping(player, tag)
  player.force.print({ "", M.colored_player_name(player), ": ", tag })
end

function M.try_ping(player, payload)
  local entity = M.entity_for_click(player, payload)
  local tag = M.rich_tag_for_ping_target(entity)
  if tag then
    print_ping(player, tag)
    return "done"
  end

  local surface = game.get_surface(payload.surface_index)
  if not (surface and surface.valid) then
    player.print({ "emof-framework.ping-invalid-surface" })
    return "done"
  end

  print_ping(player, coordinate_gps_tag(surface, payload.cursor_position))
  return "done"
end

return M
