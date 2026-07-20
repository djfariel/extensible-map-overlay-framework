local assert = require("scripts.test.assert")
local player_fixtures = require("scripts.test.fixtures.player")
local test_env = require("scripts.test.test_env")

return {
  {
    name = "on_player_left_game clears tool cursor and player storage",
    run = function()
      test_env.with_factorio_stubs(function()
        local player_handler = require("scripts.handlers.player")
        local registry = require("scripts.api.registry")
        local emof_storage = require("scripts.emof_storage")
        local tool_state = require("scripts.tools.tool_state")

        local player = player_fixtures.make_player({ gui = true, track_destroyed = true, shortcuts = true })

        registry.clear_buttons()
        registry.register_tool({
          id = "consumer-tool",
          owning_mod = "consumer-mod",
          order = "a",
          cursor_item = "emof-ping-tool",
          on_click = function()
            return "continue"
          end
        })

        tool_state.start(player, {
          name = "consumer-tool",
          cursor_item = "emof-ping-tool",
          on_click = function()
            return "continue"
          end
        })

        assert.truthy(emof_storage.get_player_state(player.index).active_tool)
        assert.equals(player.cursor_stack.name, "emof-ping-tool")

        player_handler.on_player_left_game({ player_index = player.index })

        assert.falsy(emof_storage.get_all_players()[player.index], "expected player storage to be removed")
        assert.falsy(player.cursor_stack.valid_for_read, "expected cursor to be cleared")
      end)
    end
  },
  {
    name = "on_player_left_game closes tag dialog and map panel",
    run = function()
      test_env.with_factorio_stubs(function()
        local bootstrap = require("scripts.bootstrap")
        local constants = require("scripts.constants")
        local dialog = require("scripts.builtin.tag.dialog")
        local player_handler = require("scripts.handlers.player")
        local emof_storage = require("scripts.emof_storage")

        _G.script.active_mods = {
          ["extensible-map-overlay-framework"] = true
        }

        local interfaces = {}
        _G.remote.add_interface = function(name, funcs)
          interfaces[name] = funcs
        end
        _G.remote.call = function(name, fn, payload)
          local iface = interfaces[name]
          if iface and iface[fn] then
            return iface[fn](payload)
          end
        end

        bootstrap.register_remote_interface()
        bootstrap.on_init()

        local player, destroyed = player_fixtures.make_player({ gui = true, track_destroyed = true, shortcuts = true })
        emof_storage.get_player_state(player.index).panel_open = true

        player.gui.screen.add({
          type = "frame",
          name = constants.GUI.map_panel,
          direction = "vertical"
        })

        dialog.open(player, { icon = nil, text = "" })

        player_handler.on_player_left_game({ player_index = player.index })

        assert.truthy(destroyed[dialog.GUI.dialog], "expected tag dialog to be destroyed")
        assert.truthy(destroyed[constants.GUI.map_panel], "expected map panel to be destroyed")
        assert.equals(player.shortcut_toggled[constants.SHORTCUT_OPEN_PANEL], false)
      end)
    end
  },
  {
    name = "on_player_controller_changed syncs vanilla map options",
    run = function()
      test_env.with_factorio_stubs(function()
        local emof_storage = require("scripts.emof_storage")
        local player_handler = require("scripts.handlers.player")
        local player_fixtures = require("scripts.test.fixtures.player")

        emof_storage.ensure_storage()
        local player = player_fixtures.make_player({ index = 1, gui = true, shortcuts = true })
        emof_storage.get_player_state(player.index).panel_open = false
        player.game_view_settings = { show_map_view_options = true }
        player.render_mode = defines.render_mode.chart

        player_handler.on_player_controller_changed({ player_index = player.index })

        assert.equals(player.game_view_settings.show_map_view_options, false)
      end)
    end
  },
  {
    name = "on_tick does not poll untracked connected players for vanilla map options",
    run = function()
      test_env.with_factorio_stubs(function()
        local constants = require("scripts.constants")
        local emof_storage = require("scripts.emof_storage")
        local player_handler = require("scripts.handlers.player")
        local player_fixtures = require("scripts.test.fixtures.player")

        emof_storage.ensure_storage()
        local player = player_fixtures.make_player({ index = 1 })
        player.game_view_settings = { show_map_view_options = true }
        player.render_mode = defines.render_mode.chart
        _G.game.connected_players = { player }

        player_handler.on_tick({ tick = constants.UPDATE_INTERVAL })

        assert.equals(player.game_view_settings.show_map_view_options, true)
      end)
    end
  },
  {
    name = "pending controller re-sync runs once on next update tick",
    run = function()
      test_env.with_factorio_stubs(function()
        local constants = require("scripts.constants")
        local emof_storage = require("scripts.emof_storage")
        local player_handler = require("scripts.handlers.player")
        local player_fixtures = require("scripts.test.fixtures.player")

        emof_storage.ensure_storage()
        local player = player_fixtures.make_player({ index = 1, gui = true, shortcuts = true })
        emof_storage.get_player_state(player.index).panel_open = false
        player.game_view_settings = { show_map_view_options = false }
        player.render_mode = defines.render_mode.chart
        player_handler.on_player_controller_changed({ player_index = player.index })
        assert.equals(player.game_view_settings.show_map_view_options, false)

        player.render_mode = nil
        player.controller_type = nil
        player_handler.on_tick({ tick = constants.UPDATE_INTERVAL })
        assert.equals(player.game_view_settings.show_map_view_options, true)
      end)
    end
  }
}
