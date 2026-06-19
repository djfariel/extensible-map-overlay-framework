local constants = require("scripts.constants")

local M = {}

function M.setup_has_content(icon, text)
  if icon then
    return true
  end

  return text and text:match("%S") ~= nil
end

function M.resolve_chart_tag_icon(icon, text)
  if icon then
    return icon
  end

  if text and text:match("%S") then
    return nil
  end

  return constants.DEFAULT_TAG_ICON
end

function M.confirm_pending_tag(player, pending_tag)
  if not (pending_tag and pending_tag.position and pending_tag.surface_index) then
    return false
  end

  local surface = game.get_surface(pending_tag.surface_index)
  if not (surface and surface.valid) then
    return false
  end

  local position = pending_tag.position
  local text = pending_tag.text or ""
  local icon = M.resolve_chart_tag_icon(pending_tag.icon, text)
  local chunk = {
    x = math.floor(position.x / 32),
    y = math.floor(position.y / 32)
  }

  if not player.force.is_chunk_charted(surface, chunk) then
    player.print({ "cant-build-reason.uncharted-area" })
    return false
  end

  player.force.add_chart_tag(surface, {
    position = position,
    text = text,
    icon = icon
  })

  return true
end

return M
