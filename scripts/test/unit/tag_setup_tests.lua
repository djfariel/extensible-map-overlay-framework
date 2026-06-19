local assert = require("scripts.test.assert")
local player_fixtures = require("scripts.test.fixtures.player")
local test_env = require("scripts.test.test_env")

local function find_named(element, name)
  if not (element and element.valid) then
    return nil
  end

  if element.name == name then
    return element
  end

  for _, child in pairs(element.children) do
    local found = find_named(child, name)
    if found then
      return found
    end
  end

  return nil
end

return {
  {
    name = "tag setup confirm starts built-in tag tool through remote API",
    run = function()
      test_env.with_factorio_stubs(function()
        _G.script.active_mods = {
          ["extensible-map-overlay-framework"] = true
        }

        local constants = require("scripts.constants")
        local dialog = require("scripts.builtin.tag.dialog")
        local registry = require("scripts.api.registry")
        local tag_setup = require("scripts.builtin.tag.setup")
        local tool_state = require("scripts.tools.tool_state")
        local bootstrap = require("scripts.bootstrap")

        bootstrap.on_init()

        local player = player_fixtures.make_player({ gui = true })
        tag_setup.start_setup(player)

        local frame = player.gui.screen[dialog.GUI.dialog]
        assert.truthy(frame and frame.valid, "expected tag dialog to open")

        local text_field = find_named(frame, dialog.GUI.text)
        assert.truthy(text_field, "expected tag text field in dialog")
        text_field.text = "Outpost"

        local started = tag_setup.confirm_setup(player)

        assert.truthy(started, "expected tag tool to start")
        assert.falsy(dialog.is_open(player), "expected tag dialog to close")
        assert.truthy(tool_state.get(player), "expected active tag tool")
        assert.equals(tool_state.get(player).name, constants.BUILTIN_TOOL.tag)
        assert.equals(tool_state.get(player).data.text, "Outpost")
        assert.truthy(registry.get_tool(constants.BUILTIN_TOOL.tag), "expected tag tool in registry")
      end)
    end
  },
  {
    name = "tag setup cancel through dispatch refreshes toolbar state",
    run = function()
      test_env.with_factorio_stubs(function()
        _G.script.active_mods = {
          ["extensible-map-overlay-framework"] = true
        }

        local constants = require("scripts.constants")
        local dialog = require("scripts.builtin.tag.dialog")
        local setup_dispatch = require("scripts.tools.setup_dispatch")
        local bootstrap = require("scripts.bootstrap")

        local raised = 0
        _G.script.raise_event = function()
          raised = raised + 1
        end

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

        local player = player_fixtures.make_player({ gui = true })
        setup_dispatch.open(player, constants.BUILTIN_TOOL.tag)
        assert.truthy(dialog.is_open(player), "expected tag dialog to open")

        setup_dispatch.cancel(player, constants.BUILTIN_TOOL.tag)

        assert.falsy(dialog.is_open(player), "expected tag dialog to close")
        assert.truthy(raised > 0, "expected setup cancel to raise toolbar refresh event")
      end)
    end
  }
}
