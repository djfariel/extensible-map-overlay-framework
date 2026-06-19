local assert = require("scripts.test.assert")
local test_env = require("scripts.test.test_env")

return {
  {
    name = "each_saved iterates valid game.players only",
    run = function()
      test_env.with_factorio_stubs(function()
        local player_iteration = require("scripts.map.player_iteration")

        _G.game.players[1] = { index = 1, valid = true }
        _G.game.players[2] = { index = 2, valid = false }

        local seen = {}
        player_iteration.each_saved(function(player)
          seen[#seen + 1] = player.index
        end)

        assert.equals(#seen, 1)
        assert.equals(seen[1], 1)
      end)
    end
  },
  {
    name = "each_connected iterates valid connected players only",
    run = function()
      test_env.with_factorio_stubs(function()
        local player_iteration = require("scripts.map.player_iteration")

        _G.game.connected_players = {
          { index = 1, valid = true },
          { index = 2, valid = false }
        }

        local seen = {}
        player_iteration.each_connected(function(player)
          seen[#seen + 1] = player.index
        end)

        assert.equals(#seen, 1)
        assert.equals(seen[1], 1)
      end)
    end
  }
}
