local assert = require("scripts.test.assert")
local player_fixtures = require("scripts.test.fixtures.player")
local test_env = require("scripts.test.test_env")

return {
  {
    name = "merge_missing_vanilla_settings adds new overlay keys for initialized players",
    run = function()
      test_env.with_factorio_stubs(function()
        local settings_writer = require("scripts.map.settings_writer")
        local emof_storage = require("scripts.emof_storage")
        local vanilla_overlays = require("scripts.map.vanilla_overlays")

        local player, writes = player_fixtures.make_player({ map_view_settings = true })
        _G.game.players[1] = player

        local state = emof_storage.get_player_state(player.index)
        state.initialized_map_settings = true

        for _, overlay in ipairs(vanilla_overlays.get_all()) do
          state.vanilla_toggles[overlay.map_key] = overlay.default_value
        end

        state.vanilla_toggles["show-pipelines"] = nil

        settings_writer.merge_missing_vanilla_settings(player)

        assert.equals(state.vanilla_toggles["show-pipelines"], true)
        assert.equals(#writes, 1)
        assert.equals(writes[1]["show-pipelines"], true)
      end)
    end
  },
  {
    name = "merge_missing_vanilla_settings skips players not yet initialized",
    run = function()
      test_env.with_factorio_stubs(function()
        local settings_writer = require("scripts.map.settings_writer")
        local emof_storage = require("scripts.emof_storage")

        local player, writes = player_fixtures.make_player({ map_view_settings = true })
        _G.game.players[1] = player

        local state = emof_storage.get_player_state(player.index)
        state.initialized_map_settings = false
        state.vanilla_toggles = {}

        settings_writer.merge_missing_vanilla_settings(player)

        assert.falsy(next(state.vanilla_toggles))
        assert.equals(#writes, 0)
      end)
    end
  },
  {
    name = "merge_missing_vanilla_settings writes nothing when all keys exist",
    run = function()
      test_env.with_factorio_stubs(function()
        local settings_writer = require("scripts.map.settings_writer")
        local emof_storage = require("scripts.emof_storage")
        local vanilla_overlays = require("scripts.map.vanilla_overlays")

        local player, writes = player_fixtures.make_player({ map_view_settings = true })
        _G.game.players[1] = player

        local state = emof_storage.get_player_state(player.index)
        state.initialized_map_settings = true

        for _, overlay in ipairs(vanilla_overlays.get_all()) do
          state.vanilla_toggles[overlay.map_key] = overlay.default_value
        end

        settings_writer.merge_missing_vanilla_settings(player)

        assert.equals(#writes, 0)
      end)
    end
  }
}
