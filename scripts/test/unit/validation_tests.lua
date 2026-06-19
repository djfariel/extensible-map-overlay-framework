local assert = require("scripts.test.assert")
local test_env = require("scripts.test.test_env")

return {
  {
    name = "register_action_button rejects unregistered tool_id",
    run = function()
      test_env.with_factorio_stubs(function()
        local callbacks = require("scripts.api.callbacks")
        local registry = require("scripts.api.registry")

        registry.clear_buttons()

        local ok, err = pcall(callbacks.register_action_button, {
          id = "broken-action",
          owning_mod = "consumer-mod",
          order = "a",
          tool_id = "missing-tool",
          tool_start = "immediate"
        })

        assert.falsy(ok, "expected unregistered tool_id to raise")
        assert.contains(tostring(err), "unregistered tool_id")
        assert.contains(tostring(err), "missing-tool")
      end)
    end
  },
  {
    name = "register_action_button rejects setup tool_start without setup handlers",
    run = function()
      test_env.with_factorio_stubs(function()
        local callbacks = require("scripts.api.callbacks")
        local constants = require("scripts.constants")
        local registry = require("scripts.api.registry")

        _G.remote.call = function(interface, function_name)
          if interface == "test_iface" and function_name == "on_click" then
            return "continue"
          end
        end

        registry.clear_buttons()
        callbacks.register_map_tool({
          id = "no-setup-tool",
          owning_mod = "consumer-mod",
          order = "a",
          cursor_item = constants.CURSOR_TOOL.ping,
          on_click = {
            interface = "test_iface",
            function_name = "on_click"
          }
        })

        local ok, err = pcall(callbacks.register_action_button, {
          id = "setup-action",
          owning_mod = "consumer-mod",
          order = "b",
          tool_id = "no-setup-tool",
          tool_start = constants.TOOL_START.setup
        })

        assert.falsy(ok, "expected missing setup handlers to raise")
        assert.contains(tostring(err), "requires setup handlers")
      end)
    end
  },
  {
    name = "validate_all_action_tool_references rejects mod-data actions before tools register",
    run = function()
      test_env.with_factorio_stubs(function()
        _G.prototypes.mod_data = {
          ["test-tool-action"] = {
            valid = true,
            name = "test-tool-action",
            data_type = "emof.map-action-button",
            data = {
              tool_id = "missing-tool",
              tool_start = "immediate"
            }
          }
        }

        local mod_data_loader = require("scripts.api.mod_data_loader")
        local registry = require("scripts.api.registry")
        local validation = require("scripts.api.validation")

        registry.clear_buttons()
        mod_data_loader.load_all()

        local ok, err = pcall(validation.validate_all_action_tool_references)
        assert.falsy(ok, "expected deferred validation to fail for missing tool")
        assert.contains(tostring(err), "missing-tool")
      end)
    end
  },
  {
    name = "run_pending_action_tool_validation consumes bootstrap flag once",
    run = function()
      test_env.with_factorio_stubs(function()
        local emof_storage = require("scripts.emof_storage")
        local validation = require("scripts.api.validation")

        emof_storage.schedule_action_tool_validation()
        validation.run_pending_action_tool_validation()
        validation.run_pending_action_tool_validation()
      end)
    end
  }
}
