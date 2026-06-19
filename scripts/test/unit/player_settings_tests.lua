local assert = require("scripts.test.assert")
local test_env = require("scripts.test.test_env")

return {
  {
    name = "hide_vanilla_map_options preserves other game_view_settings keys",
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

        player_settings.hide_vanilla_map_options_for_player(player)

        assert.equals(player.game_view_settings.show_map_view_options, false)
        assert.equals(player.game_view_settings.show_other_settings, true)
      end)
    end
  }
}
