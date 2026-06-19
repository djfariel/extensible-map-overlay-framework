local assert = require("scripts.test.assert")
local player_fixtures = require("scripts.test.fixtures.player")
local test_env = require("scripts.test.test_env")

local function make_player_with_quickbar(opts)
  local player = player_fixtures.make_player(opts)
  local slots = {}

  function player.get_quick_bar_slot(index)
    return slots[index]
  end

  function player.set_quick_bar_slot(index, filter)
    slots[index] = filter
  end

  return player, slots
end

return {
  {
    name = "quickbar_guard clears registered map-tool cursor items from quickbar slots",
    run = function()
      test_env.with_factorio_stubs(function()
        local quickbar_guard = require("scripts.tools.quickbar_guard")
        local registry = require("scripts.api.registry")

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

        local player, slots = make_player_with_quickbar({ index = 1 })
        slots[3] = { name = "emof-ping-tool" }
        slots[7] = { name = "iron-plate" }

        quickbar_guard.clear_blocked_slots(player)

        assert.falsy(slots[3], "expected blocked cursor tool to be cleared from quickbar")
        assert.equals(slots[7].name, "iron-plate", "expected unrelated quickbar slot to remain")
      end)
    end
  },
  {
    name = "quickbar_guard on_player_set_quick_bar_slot clears blocked slots for player",
    run = function()
      test_env.with_factorio_stubs(function()
        local quickbar_guard = require("scripts.tools.quickbar_guard")
        local registry = require("scripts.api.registry")

        registry.clear_buttons()
        registry.register_tool({
          id = "consumer-tool",
          owning_mod = "consumer-mod",
          order = "a",
          cursor_item = "emof-tag-tool",
          on_click = function()
            return "continue"
          end
        })

        local player, slots = make_player_with_quickbar({ index = 2 })
        slots[1] = { name = "emof-tag-tool" }

        quickbar_guard.on_player_set_quick_bar_slot({ player_index = player.index })

        assert.falsy(slots[1], "expected event handler to clear blocked quickbar slot")
      end)
    end
  },
  {
    name = "quickbar_guard is_blocked_cursor_item reflects registry cursor items",
    run = function()
      test_env.with_factorio_stubs(function()
        local quickbar_guard = require("scripts.tools.quickbar_guard")
        local registry = require("scripts.api.registry")

        registry.clear_buttons()
        registry.register_tool({
          id = "consumer-tool",
          owning_mod = "consumer-mod",
          order = "a",
          cursor_item = "doodle-line-cursor",
          on_click = function()
            return "continue"
          end
        })

        assert.truthy(quickbar_guard.is_blocked_cursor_item("doodle-line-cursor"))
        assert.falsy(quickbar_guard.is_blocked_cursor_item("iron-plate"))
      end)
    end
  }
}
