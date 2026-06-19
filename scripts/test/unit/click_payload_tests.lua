local assert = require("scripts.test.assert")
local player_fixtures = require("scripts.test.fixtures.player")
local test_env = require("scripts.test.test_env")

return {
  {
    name = "click_payload uses update_selected_entity at cursor position",
    run = function()
      test_env.with_factorio_stubs(function()
        local click_payload = require("scripts.tools.click_payload")

        local clicked_entity = {
          valid = true,
          unit_number = 42,
          gps_tag = "Train GPS",
          surface = { valid = true, index = 1, name = "nauvis" }
        }

        local player = player_fixtures.make_player()
        player.selected = {
          valid = true,
          unit_number = 99,
          gps_tag = "Wrong GPS",
          surface = player.surface
        }

        local cleared = false
        player.clear_selected_entity = function()
          cleared = true
          player.selected = nil
        end

        local updated_position = nil
        player.update_selected_entity = function(position)
          updated_position = position
          player.selected = clicked_entity
        end

        local payload = click_payload.build(player, {
          cursor_position = { x = 12, y = 34 },
          tick = 100
        })

        assert.truthy(cleared, "Expected click payload to clear stale selection first")
        assert.equals(updated_position.x, 12)
        assert.equals(updated_position.y, 34)
        assert.equals(payload.entity, clicked_entity)
      end)
    end
  },
  {
    name = "click_payload omits entity when cursor selection is empty",
    run = function()
      test_env.with_factorio_stubs(function()
        local click_payload = require("scripts.tools.click_payload")

        local player = player_fixtures.make_player()
        player.selected = {
          valid = true,
          unit_number = 99,
          gps_tag = "Wrong GPS",
          surface = player.surface
        }

        player.clear_selected_entity = function()
          player.selected = nil
        end

        player.update_selected_entity = function()
          player.selected = nil
        end

        local payload = click_payload.build(player, {
          cursor_position = { x = 1, y = 2 },
          tick = 100
        })

        assert.falsy(payload.entity, "Expected empty cursor selection to omit entity")
      end)
    end
  }
}
