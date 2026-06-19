local assert = require("scripts.test.assert")
local test_env = require("scripts.test.test_env")

return {
  {
    name = "ping rich tag uses entity and gps for entities",
    run = function()
      test_env.with_factorio_stubs(function()
        local ping = require("scripts.placement.ping")

        local tag = ping.rich_tag_for_ping_target({
          valid = true,
          type = "assembling-machine",
          name = "assembling-machine-3",
          gps_tag = "[gps=12,34,nauvis]"
        })

        assert.equals("[entity=assembling-machine-3][gps=12,34,nauvis]", tag)
      end)
    end
  },
  {
    name = "ping colored player name uses chat color",
    run = function()
      test_env.with_factorio_stubs(function()
        local ping = require("scripts.placement.ping")

        local label = ping.colored_player_name({
          valid = true,
          name = "Alice",
          chat_color = { r = 0.2, g = 0.8, b = 1 }
        })

        assert.equals("[color=0.2,0.8,1]Alice[/color]", label)
      end)
    end
  },
  {
    name = "ping try_ping prefers payload entity over player selected",
    run = function()
      test_env.with_factorio_stubs(function()
        local ping = require("scripts.placement.ping")

        local printed = nil
        local player = {
          valid = true,
          name = "Alice",
          chat_color = { r = 1, g = 1, b = 1 },
          selected = {
            valid = true,
            type = "assembling-machine",
            name = "assembling-machine-1",
            gps_tag = "[gps=0,0,nauvis]"
          },
          force = {
            print = function(message)
              printed = message
            end
          }
        }

        ping.try_ping(player, {
          surface_index = 1,
          cursor_position = { x = 1, y = 2 },
          entity = {
            valid = true,
            type = "locomotive",
            name = "locomotive",
            gps_tag = "[gps=5,10,nauvis]"
          }
        })

        assert.equals(printed[4], "[entity=locomotive][gps=5,10,nauvis]")
      end)
    end
  },
  {
    name = "entity_for_click prefers selected_entity over player selected",
    run = function()
      test_env.with_factorio_stubs(function()
        local ping = require("scripts.placement.ping")

        _G.game.get_entity_by_unit_number = function(unit_number)
          if unit_number == 42 then
            return {
              valid = true,
              type = "locomotive",
              name = "locomotive",
              surface = { index = 1 },
              gps_tag = "[gps=5,10,nauvis]"
            }
          end
        end

        local player = {
          valid = true,
          selected = {
            valid = true,
            type = "assembling-machine",
            name = "assembling-machine-1"
          }
        }

        local entity = ping.entity_for_click(player, {
          selected_entity = {
            unit_number = 42,
            surface_index = 1
          }
        })

        assert.equals(entity.name, "locomotive")
      end)
    end
  },
  {
    name = "entity_for_click ignores stale player selected without payload entity",
    run = function()
      test_env.with_factorio_stubs(function()
        local ping = require("scripts.placement.ping")

        local player = {
          valid = true,
          selected = {
            valid = true,
            type = "assembling-machine",
            name = "assembling-machine-1"
          }
        }

        local entity = ping.entity_for_click(player, {
          surface_index = 1,
          cursor_position = { x = 1, y = 2 }
        })

        assert.falsy(entity, "Expected stale player.selected to be ignored")
      end)
    end
  },
  {
    run = function()
      test_env.with_factorio_stubs(function()
        local ping = require("scripts.placement.ping")

        local printed = nil
        local player = {
          valid = true,
          name = "Alice",
          selected = nil,
          print = function(message)
            printed = message
          end,
          force = {
            print = function()
              error("Expected invalid-surface ping not to force.print")
            end
          }
        }

        local result = ping.try_ping(player, {
          surface_index = 999,
          cursor_position = { x = 1, y = 2 }
        })

        assert.equals(result, "done")
        assert.equals(printed[1], "emof-framework.ping-invalid-surface")
      end)
    end
  }
}
