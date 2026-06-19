local M = {}

function M.make_cursor_stack()
  local stack = {
    valid_for_read = false,
    name = nil,
    label = nil,
    label_color = nil,
    is_item_with_label = true
  }

  function stack.can_set_stack()
    return true
  end

  function stack.set_stack(value)
    stack.valid_for_read = true
    stack.name = value.name
  end

  return stack
end

function M.make_gui_element(def)
  local element = {
    valid = true,
    name = def.name,
    children = {},
    elem_value = def.elem_value,
    text = def.text or "",
    enabled = def.enabled,
    style = {}
  }

  function element.add(child_def)
    local child = M.make_gui_element(child_def)
    element.children[#element.children + 1] = child
    if child.name then
      element[child.name] = child
    end
    return child
  end

  function element.destroy()
    element.valid = false
  end

  return element
end

function M.make_player(opts)
  opts = opts or {}

  local map_view_settings_writes = nil
  if opts.map_view_settings then
    map_view_settings_writes = {}
  end

  local destroyed = nil
  if opts.track_destroyed then
    destroyed = {}
  end

  local screen = nil
  if opts.gui then
    screen = {}

    function screen.add(def)
      local element
      if opts.track_destroyed then
        element = M.make_gui_element(def)

        local base_destroy = element.destroy
        function element.destroy()
          base_destroy()
          destroyed[def.name] = true
        end
      else
        element = M.make_gui_element(def)
      end

      if element.name then
        screen[element.name] = element
      end
      return element
    end
  end

  local player = {
    index = opts.index or 1,
    valid = true,
    surface = opts.surface or { valid = true, index = 1, name = "nauvis" },
    cursor_stack = M.make_cursor_stack(),
    shortcut_toggled = opts.shortcuts and {} or nil,
    printed = opts.capture_print and nil or nil
  }

  if screen then
    player.gui = { screen = screen }
  end

  if opts.map_view_settings then
    setmetatable(player, {
      __newindex = function(table, key, value)
        if key == "map_view_settings" then
          map_view_settings_writes[#map_view_settings_writes + 1] = value
          return
        end

        rawset(table, key, value)
      end
    })
  end

  function player.clear_cursor()
    player.cursor_stack.valid_for_read = false
    player.cursor_stack.name = nil
    player.cursor_stack.label = nil
    player.cursor_stack.label_color = nil
  end

  if opts.shortcuts then
    function player.set_shortcut_toggled(shortcut, toggled)
      player.shortcut_toggled[shortcut] = toggled
    end
  end

  if opts.capture_print then
    function player.print(message)
      player.printed = message
    end
  end

  _G.game.players[player.index] = player

  if opts.map_view_settings then
    return player, map_view_settings_writes
  end

  if opts.track_destroyed then
    return player, destroyed
  end

  return player
end

return M
