local assert = require("scripts.test.assert")
local test_env = require("scripts.test.test_env")

return {
  {
    name = "set_vanilla_map_options_visible preserves other game_view_settings keys",
    run = function()
      test_env.with_factorio_stubs(function()
        local player_settings = require("scripts.map.player_settings")

        local player = {
          valid = true,
          game_view_settings = {
            show_map_view_options = true,
            show_other_settings = true
          }
        }

        player_settings.set_vanilla_map_options_visible(player, false)

        assert.equals(player.game_view_settings.show_map_view_options, false)
        assert.equals(player.game_view_settings.show_other_settings, true)

        player_settings.set_vanilla_map_options_visible(player, true)
        assert.equals(player.game_view_settings.show_map_view_options, true)
      end)
    end
  },
  {
    name = "sync_vanilla_map_options_for_player hides in chart view and shows outside",
    run = function()
      test_env.with_factorio_stubs(function()
        local player_settings = require("scripts.map.player_settings")
        local player_fixtures = require("scripts.test.fixtures.player")

        local player = player_fixtures.make_player()
        player.game_view_settings = { show_map_view_options = true }

        player.render_mode = defines.render_mode.chart
        player_settings.sync_vanilla_map_options_for_player(player)
        assert.equals(player.game_view_settings.show_map_view_options, false)

        player.render_mode = nil
        player.controller_type = nil
        player_settings.sync_vanilla_map_options_for_player(player)
        assert.equals(player.game_view_settings.show_map_view_options, true)
      end)
    end
  },
  {
    name = "sync_vanilla_map_options_for_player no-ops for invalid player",
    run = function()
      test_env.with_factorio_stubs(function()
        local player_settings = require("scripts.map.player_settings")
        player_settings.sync_vanilla_map_options_for_player(nil)
        player_settings.sync_vanilla_map_options_for_player({ valid = false })
      end)
    end
  }
}
