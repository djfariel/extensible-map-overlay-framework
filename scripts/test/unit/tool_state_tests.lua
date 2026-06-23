local assert = require("scripts.test.assert")
local player_fixtures = require("scripts.test.fixtures.player")
local test_env = require("scripts.test.test_env")

local function with_tool_state(test_fn)
  test_env.with_factorio_stubs(function()
    local registered_handlers = {}
    script.on_event = function(event_name, handler)
      registered_handlers[event_name] = handler
    end

    local constants = require("scripts.constants")
    local emof_storage = require("scripts.emof_storage")
    local tool_state = require("scripts.tools.tool_state")
    local player = player_fixtures.make_player()

    test_fn({
      constants = constants,
      handlers = registered_handlers,
      player = player,
      emof_storage = emof_storage,
      tool_state = tool_state
    })
  end)
end

return {
  {
    name = "tool_state.start stores active tool and registers inputs",
    run = function()
      with_tool_state(function(ctx)
        local started = ctx.tool_state.start(ctx.player, {
          name = "test-start",
          cursor_item = "emof-ping-tool",
          on_click = function()
            return true
          end
        })

        assert.truthy(started, "Expected tool start to succeed")
        assert.equals(ctx.tool_state.get(ctx.player).name, "test-start")
        assert.equals(ctx.player.cursor_stack.name, "emof-ping-tool")
        assert.truthy(ctx.handlers[ctx.constants.CUSTOM_INPUT.map_click], "Expected map click input to be registered")
        assert.truthy(ctx.handlers[ctx.constants.CUSTOM_INPUT.cancel], "Expected cancel input to be registered")
      end)
    end
  },
  {
    name = "tool_state.start applies cursor_label to equipped stack",
    run = function()
      with_tool_state(function(ctx)
        local started = ctx.tool_state.start(ctx.player, {
          name = "test-cursor-label",
          cursor_item = "emof-ping-tool",
          cursor_label = "Ping Tool",
          on_click = function()
            return true
          end
        })

        assert.truthy(started, "Expected tool start to succeed")
        assert.equals(ctx.player.cursor_stack.label, "Ping Tool")
      end)
    end
  },
  {
    name = "tool_state.start prefers spec cursor_label over data cursor_label",
    run = function()
      with_tool_state(function(ctx)
        ctx.tool_state.start(ctx.player, {
          name = "test-cursor-label-priority",
          cursor_item = "emof-ping-tool",
          cursor_label = "Spec label",
          data = {
            cursor_label = "Data label"
          },
          on_click = function()
            return true
          end
        })

        assert.equals(ctx.player.cursor_stack.label, "Spec label")
      end)
    end
  },
  {
    name = "tool_state.start skips empty cursor_label",
    run = function()
      with_tool_state(function(ctx)
        local started = ctx.tool_state.start(ctx.player, {
          name = "test-empty-cursor-label",
          cursor_item = "emof-ping-tool",
          cursor_label = "",
          on_click = function()
            return true
          end
        })

        assert.truthy(started, "Expected tool start to succeed")
        assert.falsy(ctx.player.cursor_stack.label, "Expected empty cursor label to be omitted")
      end)
    end
  },
  {
    name = "tool_state.start resolves localised cursor_label asynchronously",
    run = function()
      with_tool_state(function(ctx)
        local cursor = require("scripts.tools.cursor")
        local request_id = 101

        function ctx.player.request_translation(localised)
          ctx.player.last_translation_request = localised
          return request_id
        end

        local started = ctx.tool_state.start(ctx.player, {
          name = "test-localised-cursor-label",
          cursor_item = "emof-ping-tool",
          cursor_label = { "item-name.emof-ping-tool" },
          on_click = function()
            return true
          end
        })

        assert.truthy(started, "Expected tool start to succeed")
        assert.falsy(ctx.player.cursor_stack.label, "Expected label to arrive asynchronously")
        assert.equals(ctx.player.last_translation_request[1], "item-name.emof-ping-tool")

        cursor.handle_string_translated({
          id = request_id,
          player_index = ctx.player.index,
          translated = true,
          result = "Ping Tool"
        })

        assert.equals(ctx.player.cursor_stack.label, "Ping Tool")
      end)
    end
  },
  {
    name = "tool_state done click calls handler and clears active tool",
    run = function()
      with_tool_state(function(ctx)
        local click_count = 0
        ctx.tool_state.start(ctx.player, {
          name = "test-one-shot",
          cursor_item = "emof-ping-tool",
          on_click = function()
            click_count = click_count + 1
            return "done"
          end
        })

        ctx.tool_state.handle_primary_input({ player_index = 1, cursor_position = { x = 1, y = 2 } })

        assert.equals(click_count, 1)
        assert.falsy(ctx.tool_state.get(ctx.player), "Expected one-shot tool to end")
        assert.falsy(ctx.player.cursor_stack.valid_for_read, "Expected cursor to be cleared")
      end)
    end
  },
  {
    name = "tool_state continue click keeps active tool",
    run = function()
      with_tool_state(function(ctx)
        ctx.tool_state.start(ctx.player, {
          name = "test-multi-use",
          cursor_item = "emof-ping-tool",
          on_click = function()
            return "continue"
          end
        })

        ctx.tool_state.handle_primary_input({ player_index = 1, cursor_position = { x = 1, y = 2 } })

        assert.equals(ctx.tool_state.get(ctx.player).name, "test-multi-use")
        assert.equals(ctx.player.cursor_stack.name, "emof-ping-tool")
      end)
    end
  },
  {
    name = "tool_state ignores primary input while cursor is over gui",
    run = function()
      with_tool_state(function(ctx)
        local click_count = 0
        ctx.tool_state.start(ctx.player, {
          name = "test-gui-ignore",
          cursor_item = "emof-ping-tool",
          on_click = function()
            click_count = click_count + 1
            return "continue"
          end
        })

        ctx.tool_state.handle_primary_input({
          player_index = 1,
          in_gui = true,
          cursor_position = { x = 1, y = 2 }
        })

        assert.equals(click_count, 0)
        assert.equals(ctx.tool_state.get(ctx.player).name, "test-gui-ignore")
      end)
    end
  },
  {
    name = "tool_state cancel calls handler and clears state",
    run = function()
      with_tool_state(function(ctx)
        local cancel_reason = nil
        ctx.tool_state.start(ctx.player, {
          name = "test-cancel",
          cursor_item = "emof-ping-tool",
          on_click = function()
            return true
          end,
          on_cancel = function(_, _, reason)
            cancel_reason = reason
          end
        })

        ctx.tool_state.cancel(ctx.player, "unit-test")

        assert.equals(cancel_reason, "unit-test")
        assert.falsy(ctx.tool_state.get(ctx.player), "Expected cancel to clear active tool")
        assert.falsy(ctx.player.cursor_stack.valid_for_read, "Expected cancel to clear cursor")
      end)
    end
  },
  {
    name = "tool_state cursor clear event cancels active tool",
    run = function()
      with_tool_state(function(ctx)
        local cancel_reason = nil
        ctx.tool_state.start(ctx.player, {
          name = "test-cursor-clear",
          cursor_item = "emof-ping-tool",
          on_click = function()
            return true
          end,
          on_cancel = function(_, _, reason)
            cancel_reason = reason
          end
        })

        ctx.player.clear_cursor()
        ctx.tool_state.handle_cursor_changed({ player_index = 1 })

        assert.equals(cancel_reason, "cursor-cleared")
        assert.falsy(ctx.tool_state.get(ctx.player), "Expected cursor clear to cancel active tool")
      end)
    end
  },
  {
    name = "tool_state sync clears stale active tool without cursor",
    run = function()
      with_tool_state(function(ctx)
        ctx.tool_state.start(ctx.player, {
          name = "test-stale-tool",
          cursor_item = "emof-ping-tool",
          on_click = function()
            return true
          end
        })

        ctx.player.clear_cursor()
        ctx.tool_state.sync_input_handlers()

        assert.falsy(ctx.tool_state.get(ctx.player), "Expected stale active tool to be cleared")
        assert.falsy(ctx.handlers[ctx.constants.CUSTOM_INPUT.map_click], "Expected map click input to be unregistered")
        assert.falsy(ctx.handlers[ctx.constants.CUSTOM_INPUT.cancel], "Expected cancel input to be unregistered")
      end)
    end
  },
  {
    name = "tool_state remote click dispatches immediately",
    run = function()
      with_tool_state(function(ctx)
        local click_count = 0
        ctx.player.controller_type = defines.controllers.remote
        ctx.tool_state.start(ctx.player, {
          name = "test-remote-immediate",
          cursor_item = "emof-ping-tool",
          on_click = function()
            click_count = click_count + 1
            return "continue"
          end
        })

        ctx.tool_state.handle_primary_input({ player_index = 1, tick = 100, cursor_position = { x = 12, y = 34 } })
        assert.equals(click_count, 1, "Expected remote click event to dispatch immediately")
      end)
    end
  },
  {
    name = "tool_state remote duplicate click positions are not deduplicated",
    run = function()
      with_tool_state(function(ctx)
        local click_count = 0
        ctx.player.controller_type = defines.controllers.remote
        ctx.tool_state.start(ctx.player, {
          name = "test-remote-duplicates",
          cursor_item = "emof-ping-tool",
          on_click = function()
            click_count = click_count + 1
            return "continue"
          end
        })

        ctx.tool_state.handle_primary_input({ player_index = 1, tick = 100, cursor_position = { x = 12, y = 34 } })
        ctx.tool_state.handle_primary_input({ player_index = 1, tick = 120, cursor_position = { x = 12, y = 34 } })

        assert.equals(click_count, 2, "Expected remote duplicate positions to both dispatch")
      end)
    end
  },
  {
    name = "tool_state non-remote duplicate click positions are not deduplicated",
    run = function()
      with_tool_state(function(ctx)
        local click_count = 0
        ctx.player.controller_type = nil
        ctx.tool_state.start(ctx.player, {
          name = "test-non-remote",
          cursor_item = "emof-ping-tool",
          on_click = function()
            click_count = click_count + 1
            return "continue"
          end
        })

        ctx.tool_state.handle_primary_input({ player_index = 1, cursor_position = { x = 12, y = 34 } })
        ctx.tool_state.handle_primary_input({ player_index = 1, cursor_position = { x = 12, y = 34 } })

        assert.equals(click_count, 2, "Expected non-remote duplicate positions to both dispatch")
      end)
    end
  },
  {
    name = "tool_state click without cursor_position does not dispatch",
    run = function()
      with_tool_state(function(ctx)
        local click_count = 0
        ctx.tool_state.start(ctx.player, {
          name = "test-no-position",
          cursor_item = "emof-ping-tool",
          on_click = function()
            click_count = click_count + 1
            return "done"
          end
        })

        ctx.tool_state.handle_primary_input({ player_index = 1 })

        assert.equals(click_count, 0, "Expected click without cursor_position to be ignored")
        assert.equals(ctx.tool_state.get(ctx.player).name, "test-no-position")
      end)
    end
  },
  {
    name = "tool_state click without chart surface does not dispatch",
    run = function()
      with_tool_state(function(ctx)
        local click_count = 0
        ctx.player.surface = nil
        ctx.tool_state.start(ctx.player, {
          name = "test-no-surface",
          cursor_item = "emof-ping-tool",
          on_click = function()
            click_count = click_count + 1
            return "done"
          end
        })

        ctx.tool_state.handle_primary_input({ player_index = 1, cursor_position = { x = 1, y = 2 } })

        assert.equals(click_count, 0, "Expected click without chart surface to be ignored")
        assert.equals(ctx.tool_state.get(ctx.player).name, "test-no-surface")
      end)
    end
  },
  {
    name = "tool_state click payload includes selected entity",
    run = function()
      with_tool_state(function(ctx)
        local received = nil
        local clicked_entity = {
          valid = true,
          gps_tag = "Train GPS",
          unit_number = 42,
          surface = ctx.player.surface
        }
        ctx.player.selected = {
          valid = true,
          gps_tag = "Wrong GPS",
          unit_number = 99,
          surface = ctx.player.surface
        }
        ctx.player.clear_selected_entity = function()
          ctx.player.selected = nil
        end
        ctx.player.update_selected_entity = function()
          ctx.player.selected = clicked_entity
        end
        ctx.tool_state.start(ctx.player, {
          name = "test-selected-entity",
          cursor_item = "emof-ping-tool",
          on_click = function(_, payload)
            received = payload
            return "done"
          end
        })

        ctx.tool_state.handle_primary_input({ player_index = 1, cursor_position = { x = 1, y = 2 } })

        assert.truthy(received, "Expected click to dispatch")
        assert.truthy(received.entity, "Expected payload to include selected entity")
        assert.equals(received.entity.gps_tag, "Train GPS")
      end)
    end
  },
  {
    name = "tool_state.prune_registered removes handlers not in registry",
    run = function()
      with_tool_state(function(ctx)
        local saw_click = false

        ctx.tool_state.start(ctx.player, {
          name = "stale-tool",
          cursor_item = "emof-ping-tool",
          on_click = function()
            saw_click = true
            return "continue"
          end
        })

        ctx.tool_state.prune_registered(function(id)
          return id ~= "stale-tool"
        end)

        ctx.tool_state.handle_primary_input({ player_index = 1, cursor_position = { x = 1, y = 2 } })

        assert.falsy(saw_click, "expected pruned handler not to receive clicks")
        assert.falsy(ctx.tool_state.get(ctx.player), "expected missing handler to cancel active tool")
      end)
    end
  },
  {
    name = "tool_state.unregister removes a registered handler",
    run = function()
      with_tool_state(function(ctx)
        ctx.tool_state.register({
          name = "temporary-tool",
          cursor_item = "emof-ping-tool",
          on_click = function()
            return "continue"
          end
        })

        assert.truthy(ctx.tool_state.unregister("temporary-tool"))
        assert.falsy(ctx.tool_state.unregister("temporary-tool"), "expected second unregister to return false")

        ctx.tool_state.start(ctx.player, {
          name = "temporary-tool",
          cursor_item = "emof-ping-tool",
          on_click = function()
            return "continue"
          end
        })

        ctx.tool_state.unregister("temporary-tool")
        ctx.tool_state.handle_primary_input({ player_index = 1, cursor_position = { x = 1, y = 2 } })
        assert.falsy(ctx.tool_state.get(ctx.player), "expected click to cancel after handler unregister")
      end)
    end
  },
  {
    name = "tool_state.cancel_all_players clears active tools",
    run = function()
      with_tool_state(function(ctx)
        ctx.tool_state.start(ctx.player, {
          name = "test-cancel-all",
          cursor_item = "emof-ping-tool",
          on_click = function()
            return "continue"
          end
        })

        ctx.tool_state.cancel_all_players("configuration-changed")

        assert.falsy(ctx.tool_state.get(ctx.player), "expected active tool to be cleared")
        assert.falsy(ctx.player.cursor_stack.valid_for_read, "expected cursor to be cleared")
        assert.falsy(ctx.handlers[ctx.constants.CUSTOM_INPUT.map_click], "expected map click input to be unregistered")
      end)
    end
  },
  {
    name = "tool_state rebuilds click handlers from registry on load",
    run = function()
      test_env.with_factorio_stubs(function()
        _G.script.active_mods = {
          ["consumer-mod"] = true
        }

        local registered_handlers = {}
        script.on_event = function(event_name, handler)
          registered_handlers[event_name] = handler
        end

        local callbacks = require("scripts.api.callbacks")
        local constants = require("scripts.constants")
        local registry = require("scripts.api.registry")
        local emof_storage = require("scripts.emof_storage")
        local tool_state = require("scripts.tools.tool_state")

        emof_storage.ensure_storage()
        registry.register_tool({
          id = "saved-tool",
          owning_mod = "consumer-mod",
          order = "a",
          cursor_item = "emof-ping-tool",
          on_click = {
            interface = "consumer_iface",
            function_name = "on_click"
          }
        })

        local player = player_fixtures.make_player()
        local saw_click = false
        _G.remote.call = function(interface, function_name)
          if interface == "consumer_iface" and function_name == "on_click" then
            saw_click = true
            return "continue"
          end
        end

        callbacks.start_map_tool(player.index, "saved-tool", {})
        assert.equals(tool_state.get(player).name, "saved-tool", "expected active tool from storage registry")

        tool_state.handle_primary_input({ player_index = 1, cursor_position = { x = 1, y = 2 } })
        assert.falsy(saw_click, "expected click to fail before handler rebuild")
        assert.falsy(tool_state.get(player), "expected missing handler to cancel active tool")

        callbacks.start_map_tool(player.index, "saved-tool", {})
        callbacks.rebuild_registered_tools()
        tool_state.sync_input_handlers()

        tool_state.handle_primary_input({ player_index = 1, cursor_position = { x = 1, y = 2 } })

        assert.truthy(saw_click, "expected click to dispatch after handler rebuild")
        assert.equals(tool_state.get(player).name, "saved-tool", "expected tool to stay active after continue click")
        assert.truthy(registered_handlers[constants.CUSTOM_INPUT.map_click], "expected map click input to register after rebuild")
      end)
    end
  },
  {
    name = "tool_state.sync_input_handlers registers from storage when game is unavailable",
    run = function()
      with_tool_state(function(ctx)
        local registered_handlers = {}
        script.on_event = function(event_name, handler)
          registered_handlers[event_name] = handler
        end

        ctx.tool_state.start(ctx.player, {
          name = "test-on-load",
          cursor_item = "emof-ping-tool",
          on_click = function()
            return true
          end
        })

        local previous_game = _G.game
        _G.game = nil

        ctx.tool_state.sync_input_handlers()

        _G.game = previous_game

        assert.truthy(
          registered_handlers[ctx.constants.CUSTOM_INPUT.map_click],
          "Expected map click input to register during on_load"
        )
        assert.equals(
          ctx.tool_state.get(ctx.player).name,
          "test-on-load",
          "Expected active tool to remain in storage during on_load"
        )
      end)
    end
  }
}
