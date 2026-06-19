local assert = require("scripts.test.assert")
local test_env = require("scripts.test.test_env")

local root = _G.__EMOF_TEST_ROOT or "."

return {
  {
    name = "control.lua parses with factorio stubs",
    run = function()
      test_env.with_factorio_stubs(function()
        local ok, err = pcall(dofile, root .. "/control.lua")
        assert.truthy(ok, "control.lua failed to parse: " .. tostring(err))
      end)
    end
  },
  {
    name = "events.register wires handlers with stubs",
    run = function()
      test_env.with_factorio_stubs(function()
        local events = require("scripts.events")
        local ok, err = pcall(events.register)
        assert.truthy(ok, "events.register failed: " .. tostring(err))
      end)
    end
  },
  {
    name = "all runtime modules load with stubs",
    run = function()
      test_env.with_factorio_stubs(function()
        local module_names = {
          "scripts.constants",
          "scripts.emof_storage",
          "scripts.bootstrap",
          "scripts.events",
          "scripts.api.validation",
          "scripts.api.registry",
          "scripts.api.mod_data_loader",
          "scripts.api.builtin_tools",
          "scripts.api.callbacks",
          "scripts.api.public_events",
          "scripts.api.remote_interface",
          "scripts.api.validation",
          "scripts.map.vanilla_overlays",
          "scripts.map.view_context",
          "scripts.map.pollutant_display",
          "scripts.map.settings_writer",
          "scripts.map.player_settings",
          "scripts.map.player_iteration",
          "scripts.map.chart_watchers",
          "scripts.player_resolution",
          "scripts.map.visibility",
          "scripts.gui.panel",
          "scripts.gui.panel_layout",
          "scripts.gui.panel_actions",
          "scripts.gui.panel_overlays",
          "scripts.gui.element_tree",
          "scripts.gui.dispatch",
          "scripts.gui.action_tools",
          "scripts.builtin.init",
          "scripts.tools.setup_dispatch",
          "scripts.builtin.tag.dialog",
          "scripts.builtin.tag.setup",
          "scripts.builtin.tag.gui_handlers",
          "scripts.tools.cursor",
          "scripts.tools.quickbar_guard",
          "scripts.tools.tool_notify",
          "scripts.tools.tool_state",
          "scripts.placement.ping",
          "scripts.placement.tag",
          "scripts.handlers.gui",
          "scripts.handlers.player"
        }

        for _, module_name in ipairs(module_names) do
          local ok, err = pcall(require, module_name)
          assert.truthy(ok, "Failed loading module " .. module_name .. ": " .. tostring(err))
        end
      end)
    end
  }
}
