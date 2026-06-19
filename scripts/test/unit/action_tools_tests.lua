local assert = require("scripts.test.assert")
local player_fixtures = require("scripts.test.fixtures.player")
local test_env = require("scripts.test.test_env")

return {
  {
    name = "action_tools reports pressed when linked tool is active",
    run = function()
      test_env.with_factorio_stubs(function()
        local action_tools = require("scripts.gui.action_tools")
        local tool_state = require("scripts.tools.tool_state")

        local player = player_fixtures.make_player({ gui = true, capture_print = true })
        local spec = {
          id = "emof-add-ping",
          tool_id = "ping"
        }

        assert.falsy(action_tools.is_action_pressed(player, spec))

        tool_state.start(player, {
          name = "ping",
          cursor_item = "emof-ping-tool",
          on_click = function()
            return "continue"
          end
        })

        assert.truthy(action_tools.is_action_pressed(player, spec))
      end)
    end
  },
  {
    name = "action_tools cancels active tool on second click",
    run = function()
      test_env.with_factorio_stubs(function()
        local action_tools = require("scripts.gui.action_tools")
        local registry = require("scripts.api.registry")
        local tool_state = require("scripts.tools.tool_state")

        _G.remote.call = function(interface, function_name)
          if interface == "test_iface" and function_name == "on_click" then
            return "continue"
          end
        end

        local player = player_fixtures.make_player({ gui = true, capture_print = true })

        registry.clear_buttons()
        registry.register_tool({
          id = "consumer-tool",
          owning_mod = "consumer-mod",
          order = "a",
          cursor_item = "emof-ping-tool",
          on_click = {
            interface = "test_iface",
            function_name = "on_click"
          }
        })

        local spec = {
          id = "consumer-action",
          tool_id = "consumer-tool",
          tool_start = "immediate"
        }

        action_tools.activate_tool_action(player, spec)
        assert.truthy(tool_state.get(player), "expected tool to start")

        action_tools.handle_action_click(player, spec)
        assert.falsy(tool_state.get(player), "expected second click to cancel tool")
      end)
    end
  },
  {
    name = "action_tools reports missing tool to player",
    run = function()
      test_env.with_factorio_stubs(function()
        local action_tools = require("scripts.gui.action_tools")
        local registry = require("scripts.api.registry")

        local player = player_fixtures.make_player({ gui = true, capture_print = true })
        registry.clear_buttons()

        local spec = {
          id = "broken-action",
          tool_id = "missing-tool",
          tool_start = "immediate"
        }

        local handled = action_tools.handle_action_click(player, spec)

        assert.falsy(handled, "expected missing tool activation to fail")
        assert.equals(player.printed[1], "emof-framework.action-missing-tool")
        assert.equals(player.printed[2], "missing-tool")
      end)
    end
  },
  {
    name = "action_tools opens setup flow for tool_start setup",
    run = function()
      test_env.with_factorio_stubs(function()
        local action_tools = require("scripts.gui.action_tools")
        local bootstrap = require("scripts.bootstrap")
        local constants = require("scripts.constants")
        local dialog = require("scripts.builtin.tag.dialog")

        _G.script.active_mods = {
          ["extensible-map-overlay-framework"] = true
        }

        local interfaces = {}
        _G.remote.add_interface = function(name, funcs)
          interfaces[name] = funcs
        end
        _G.remote.call = function(name, fn, payload)
          local iface = interfaces[name]
          if iface and iface[fn] then
            return iface[fn](payload)
          end
        end

        bootstrap.register_remote_interface()
        bootstrap.on_init()

        local player = player_fixtures.make_player({ gui = true, capture_print = true })
        local spec = {
          id = "emof-add-tag",
          tool_id = constants.BUILTIN_TOOL.tag,
          tool_start = constants.TOOL_START.setup
        }

        local started = action_tools.activate_tool_action(player, spec)

        assert.truthy(started, "expected setup activation to succeed")
        assert.truthy(dialog.is_open(player), "expected setup dialog to open")
        assert.truthy(action_tools.is_action_pressed(player, spec), "expected setup button to show pressed")
      end)
    end
  },
  {
    name = "action_tools reports missing setup handlers to player",
    run = function()
      test_env.with_factorio_stubs(function()
        local action_tools = require("scripts.gui.action_tools")
        local constants = require("scripts.constants")
        local registry = require("scripts.api.registry")

        _G.remote.call = function(interface, function_name)
          if interface == "test_iface" and function_name == "on_click" then
            return "continue"
          end
        end

        local player = player_fixtures.make_player({ gui = true, capture_print = true })
        registry.clear_buttons()
        registry.register_tool({
          id = "no-setup-tool",
          owning_mod = "consumer-mod",
          order = "a",
          cursor_item = "emof-ping-tool",
          on_click = {
            interface = "test_iface",
            function_name = "on_click"
          }
        })

        local spec = {
          id = "setup-action",
          tool_id = "no-setup-tool",
          tool_start = constants.TOOL_START.setup
        }

        local handled = action_tools.handle_action_click(player, spec)

        assert.falsy(handled, "expected missing setup activation to fail")
        assert.equals(player.printed[1], "emof-framework.action-missing-setup")
        assert.equals(player.printed[2], "no-setup-tool")
      end)
    end
  }
}
