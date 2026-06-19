local assert = require("scripts.test.assert")
local player_fixtures = require("scripts.test.fixtures.player")
local test_env = require("scripts.test.test_env")

local function register_test_tool(registry, on_click_name, on_cancel_name)
  local spec = {
    id = "test-tool",
    owning_mod = "test-mod",
    order = "a",
    cursor_item = "emof-ping-tool",
    on_click = {
      interface = "test_iface",
      function_name = on_click_name
    }
  }

  if on_cancel_name then
    spec.on_cancel = {
      interface = "test_iface",
      function_name = on_cancel_name
    }
  end

  registry.register_tool(spec)
end

local function click_payload()
  return {
    surface_index = 1,
    cursor_position = { x = 10, y = 20 },
    tick = 42
  }
end

local function active_tool()
  return {
    name = "test-tool",
    data = { session = true }
  }
end

return {
  {
    name = "dispatch_map_tool_click returns remote result on success",
    run = function()
      test_env.with_factorio_stubs(function()
        _G.remote.call = function(interface, function_name, payload)
          assert.equals(interface, "test_iface")
          assert.equals(function_name, "on_click")
          assert.equals(payload.id, "test-tool")
          return "continue"
        end

        local registry = require("scripts.api.registry")
        local callbacks = require("scripts.api.callbacks")

        registry.clear_buttons()
        register_test_tool(registry, "on_click")

        local player = { index = 1, valid = true }
        local result = callbacks.dispatch_map_tool_click(player, click_payload(), active_tool())
        assert.equals(result, "continue")
      end)
    end
  },
  {
    name = "dispatch_map_tool_click ends tool when remote callback errors",
    run = function()
      test_env.with_factorio_stubs(function()
        _G.remote.call = function()
          error("callback exploded")
        end

        local registry = require("scripts.api.registry")
        local callbacks = require("scripts.api.callbacks")

        registry.clear_buttons()
        register_test_tool(registry, "on_click")

        local player = { index = 1, valid = true }
        local result = callbacks.dispatch_map_tool_click(player, click_payload(), active_tool())
        assert.equals(result, "done")
      end)
    end
  },
  {
    name = "dispatch_map_tool_cancel swallows remote callback errors",
    run = function()
      test_env.with_factorio_stubs(function()
        _G.remote.call = function()
          error("cancel exploded")
        end

        local registry = require("scripts.api.registry")
        local callbacks = require("scripts.api.callbacks")

        registry.clear_buttons()
        register_test_tool(registry, "on_click", "on_cancel")

        local player = { index = 1, valid = true }
        callbacks.dispatch_map_tool_cancel(player, active_tool(), "cancel-input")
      end)
    end
  },
  {
    name = "set_player_toggle rejects invalid player indices without creating storage",
    run = function()
      test_env.with_factorio_stubs(function()
        local callbacks = require("scripts.api.callbacks")
        local registry = require("scripts.api.registry")
        local emof_storage = require("scripts.emof_storage")

        registry.clear_buttons()
        registry.register_overlay({
          id = "test-overlay",
          owning_mod = "test-mod",
          order = "a"
        })

        local ok, err = pcall(callbacks.set_player_toggle, 999, "test-overlay", true)
        assert.falsy(ok, "expected invalid player_index to error")
        assert.contains(tostring(err), "player_index")
        assert.falsy(emof_storage.get_all_players()[999], "expected no ghost player storage entry")

        _G.game.players[1] = { index = 1, valid = true }
        callbacks.set_player_toggle(1, "test-overlay", true)
        assert.equals(emof_storage.get_player_state(1).extension_toggles["test-overlay"], true)
      end)
    end
  },
  {
    name = "get_player_toggle rejects invalid player indices without creating storage",
    run = function()
      test_env.with_factorio_stubs(function()
        local callbacks = require("scripts.api.callbacks")
        local emof_storage = require("scripts.emof_storage")

        local ok, err = pcall(callbacks.get_player_toggle, 999, "test-overlay")
        assert.falsy(ok, "expected invalid player_index to error")
        assert.contains(tostring(err), "player_index")
        assert.falsy(emof_storage.get_all_players()[999], "expected no ghost player storage entry")
      end)
    end
  },
  {
    name = "register_map_tool rejects tools owned by inactive mods",
    run = function()
      test_env.with_factorio_stubs(function()
        _G.script.active_mods = {
          ["extensible-map-overlay-framework"] = true
        }

        local callbacks = require("scripts.api.callbacks")
        local registry = require("scripts.api.registry")

        registry.clear_buttons()

        local ok, err = pcall(callbacks.register_map_tool, {
          id = "ghost-tool",
          owning_mod = "removed-mod",
          order = "a",
          cursor_item = "emof-ping-tool",
          on_click = {
            interface = "test_iface",
            function_name = "on_click"
          }
        })

        assert.falsy(ok, "expected inactive tool owner to error on register")
        assert.contains(tostring(err), "not active")
        assert.falsy(registry.get_tool("ghost-tool"), "expected tool not to be registered")
      end)
    end
  },
  {
    name = "start_map_tool rejects tools owned by inactive mods",
    run = function()
      test_env.with_factorio_stubs(function()
        _G.script.active_mods = {
          ["extensible-map-overlay-framework"] = true
        }

        local callbacks = require("scripts.api.callbacks")
        local registry = require("scripts.api.registry")

        registry.clear_buttons()
        registry.register_tool({
          id = "ghost-tool",
          owning_mod = "removed-mod",
          order = "a",
          cursor_item = "emof-ping-tool",
          on_click = {
            interface = "test_iface",
            function_name = "on_click"
          }
        })

        _G.game.players[1] = { index = 1, valid = true }

        local ok, err = pcall(callbacks.start_map_tool, 1, "ghost-tool", {})
        assert.falsy(ok, "expected inactive tool owner to error")
        assert.contains(tostring(err), "not active")
      end)
    end
  },
  {
    name = "unregister clears tool handlers and cancels active tool",
    run = function()
      test_env.with_factorio_stubs(function()
        _G.script.active_mods = {
          ["consumer-mod"] = true
        }

        local saw_click = false
        _G.remote.call = function(interface, function_name)
          if interface == "consumer_iface" and function_name == "on_click" then
            saw_click = true
            return "continue"
          end
        end

        local callbacks = require("scripts.api.callbacks")
        local registry = require("scripts.api.registry")
        local emof_storage = require("scripts.emof_storage")
        local tool_state = require("scripts.tools.tool_state")

        registry.clear_buttons()
        callbacks.register_map_tool({
          id = "consumer-tool",
          owning_mod = "consumer-mod",
          order = "a",
          cursor_item = "emof-ping-tool",
          on_click = {
            interface = "consumer_iface",
            function_name = "on_click"
          }
        })

        local player = player_fixtures.make_player()
        callbacks.start_map_tool(player.index, "consumer-tool", {})
        assert.truthy(tool_state.get(player), "expected tool to be active before unregister")

        callbacks.unregister("consumer-mod", "consumer-tool", "tool")

        assert.falsy(registry.get_tool("consumer-tool"), "expected tool to be removed from registry")
        assert.falsy(tool_state.get(player), "expected active tool to be cancelled on unregister")

        emof_storage.get_player_state(player.index).active_tool = {
          name = "consumer-tool",
          cursor_item = "emof-ping-tool",
          data = {}
        }
        player.cursor_stack.set_stack({ name = "emof-ping-tool", count = 1 })

        tool_state.handle_primary_input({ player_index = 1, cursor_position = { x = 1, y = 2 } })

        assert.falsy(saw_click, "expected unregistered tool handler not to receive clicks")
        assert.falsy(tool_state.get(player), "expected stale active tool to be cleared on click")
      end)
    end
  },
  {
    name = "try_register_map_tool returns structured error without raising",
    run = function()
      test_env.with_factorio_stubs(function()
        local callbacks = require("scripts.api.callbacks")

        local result = callbacks.try_register_map_tool({
          id = "bad-tool",
          owning_mod = "consumer-mod",
          order = "a",
          cursor_item = "emof-ping-tool"
        })

        assert.truthy(result, "expected result table")
        assert.falsy(result.ok, "expected invalid spec to fail")
        assert.truthy(result.error, "expected error message")
      end)
    end
  },
  {
    name = "is_action_enabled uses remote callback result",
    run = function()
      test_env.with_factorio_stubs(function()
        local callbacks = require("scripts.api.callbacks")
        local registry = require("scripts.api.registry")

        _G.remote.call = function(interface, function_name, payload)
          if interface == "test_actions" and function_name == "is_enabled" then
            assert.equals("undo-action", payload.id)
            return payload.player_index == 1
          end
        end

        registry.clear_buttons()
        registry.register_action({
          id = "undo-action",
          owning_mod = "consumer-mod",
          order = "a",
          enabled = {
            interface = "test_actions",
            function_name = "is_enabled"
          }
        })

        assert.truthy(callbacks.is_action_enabled(1, "undo-action"))
        assert.falsy(callbacks.is_action_enabled(2, "undo-action"))
      end)
    end
  },
  {
    name = "is_action_enabled fails closed when remote callback errors",
    run = function()
      test_env.with_factorio_stubs(function()
        local callbacks = require("scripts.api.callbacks")
        local registry = require("scripts.api.registry")

        _G.remote.call = function()
          error("enabled callback exploded")
        end

        registry.clear_buttons()
        registry.register_action({
          id = "undo-action",
          owning_mod = "consumer-mod",
          order = "a",
          enabled = {
            interface = "test_actions",
            function_name = "is_enabled"
          }
        })

        assert.falsy(callbacks.is_action_enabled(1, "undo-action"))
      end)
    end
  },
  {
    name = "unregister rejects invalid kind",
    run = function()
      test_env.with_factorio_stubs(function()
        local callbacks = require("scripts.api.callbacks")

        local ok, err = pcall(callbacks.unregister, "consumer-mod", "some-id", "widget")
        assert.falsy(ok, "expected invalid kind to error")
        assert.contains(tostring(err), "kind")
      end)
    end
  }
}
