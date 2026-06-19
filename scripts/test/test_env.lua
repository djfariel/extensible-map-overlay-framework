local M = {}

local function clear_loaded_scripts_modules()
  for key in pairs(package.loaded) do
    if string.find(key, "scripts.", 1, true) == 1 then
      package.loaded[key] = nil
    end
  end
end

function M.with_factorio_stubs(test_fn)
  local previous = {
    script = rawget(_G, "script"),
    remote = rawget(_G, "remote"),
    defines = rawget(_G, "defines"),
    storage = rawget(_G, "storage"),
    helpers = rawget(_G, "helpers"),
    game = rawget(_G, "game"),
    prototypes = rawget(_G, "prototypes")
  }

  ---@diagnostic disable-next-line: missing-fields
  _G.script = {
    on_init = function() end,
    on_configuration_changed = function() end,
    on_load = function() end,
    on_event = function() end,
    on_nth_tick = function() end,
    raise_event = function() end,
    active_mods = {
      ["extensible-map-overlay-framework"] = true,
      ["consumer-mod"] = true,
      ["test-mod"] = true,
      ["removed-mod"] = true
    },
    generate_event_name = (function()
      local counter = 2000
      return function()
        counter = counter + 1
        return counter
      end
    end)()
  }

  ---@diagnostic disable-next-line: missing-fields
  _G.remote = {
    add_interface = function() end,
    call = function() end
  }

  _G.defines = {
    events = {
      on_player_created = 1,
      on_player_joined_game = 2,
      on_player_left_game = 3,
      on_player_controller_changed = 4,
      on_player_changed_surface = 5,
      on_tick = 6,
      on_gui_click = 7,
      on_gui_elem_changed = 8,
      on_gui_closed = 9,
      on_lua_shortcut = 10,
      on_player_cursor_stack_changed = 11,
      on_player_set_quick_bar_slot = 15,
      on_gui_text_changed = 12,
      on_gui_value_changed = 13,
      on_string_translated = 14
    },
    controllers = {
      remote = 1
    },
    render_mode = {
      chart = 1,
      chart_zoomed_in = 2
    }
  }

  _G.storage = {}
  _G.helpers = {
    is_valid_sprite_path = function()
      return true
    end
  }

  _G.game = {
    players = {},
    connected_players = {},
    get_player = function(player_index)
      return _G.game.players[player_index]
    end,
    get_surface = function()
      return nil
    end
  }

  _G.prototypes = {
    mod_data = {},
    custom_event = {
      ["emof-on-map-action-clicked"] = {
        valid = true,
        event_id = 3001
      },
      ["emof-on-map-overlay-toggled"] = {
        valid = true,
        event_id = 3002
      },
      ["emof-on-tool-state-changed"] = {
        valid = true,
        event_id = 3003
      }
    },
    get_history = function()
      return {
        created = "test-mod"
      }
    end
  }

  clear_loaded_scripts_modules()

  local ok, err = pcall(test_fn)

  clear_loaded_scripts_modules()

  _G.script = previous.script
  _G.remote = previous.remote
  _G.defines = previous.defines
  _G.storage = previous.storage
  _G.helpers = previous.helpers
  _G.game = previous.game
  _G.prototypes = previous.prototypes

  if not ok then
    error(err)
  end
end

function M.read_file(path)
  ---@diagnostic disable-next-line: undefined-global
  local handle, open_err = io.open(path, "r")
  if not handle then
    error("Failed to open file: " .. tostring(path) .. " (" .. tostring(open_err) .. ")")
  end

  local text = handle:read("*a")
  handle:close()
  return text
end

function M.get_repo_root()
  local current = M.normalize_path(arg and arg[0] or "tools/run-unit-tests.lua")
  return current:match("^(.*)/tools/[^/]+$") or "."
end

function M.normalize_path(path)
  return (path:gsub("\\", "/"))
end

return M
