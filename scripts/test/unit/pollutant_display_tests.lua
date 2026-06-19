local assert = require("scripts.test.assert")
local test_env = require("scripts.test.test_env")

return {
  {
    name = "resolve_cached reuses result within the same tick",
    run = function()
      test_env.with_factorio_stubs(function()
        local pollutant_display = require("scripts.map.pollutant_display")

        _G.game.tick = 100

        local player = {
          index = 1,
          valid = true,
          surface = {
            valid = true,
            index = 1,
            name = "nauvis",
            pollutant_type = {
              valid = true,
              name = "pollution",
              localised_name = { "pollution" }
            }
          }
        }

        local first = pollutant_display.resolve_cached(player)
        local second = pollutant_display.resolve_cached(player)

        assert.truthy(first == second, "expected cached table reuse within tick")

        _G.game.tick = 101
        local third = pollutant_display.resolve_cached(player)

        assert.truthy(third)
        assert.truthy(third ~= first, "expected fresh resolve on next tick")
      end)
    end
  }
}
