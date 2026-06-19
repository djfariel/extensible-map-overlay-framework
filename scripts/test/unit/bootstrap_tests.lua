local assert = require("scripts.test.assert")
local test_env = require("scripts.test.test_env")

local root = _G.__EMOF_TEST_ROOT or "."

local function no_runtime_require_lines(file_text)
  local line_number = 0
  local in_function = false
  local violations = {}

  for line in file_text:gmatch("[^\r\n]+") do
    line_number = line_number + 1

    if line:match("^%s*function%s+") or line:match("^%s*local%s+function%s+") then
      in_function = true
    end

    if in_function and line:match("require%s*%(") then
      violations[#violations + 1] = line_number
    end
  end

  return violations
end

local function assert_no_runtime_require(relative_path)
  local file_text = test_env.read_file(root .. "/" .. relative_path)
  local violations = no_runtime_require_lines(file_text)
  assert.equals(
    #violations,
    0,
    "Found runtime require() in " .. relative_path .. " at lines: " .. table.concat(violations, ", ")
  )
end

return {
  {
    name = "bootstrap has no runtime require calls",
    run = function()
      assert_no_runtime_require("scripts/bootstrap.lua")
    end
  },
  {
    name = "runtime modules have top-level require only",
    run = function()
      local module_files = {
        "scripts/events.lua",
        "scripts/api/validation.lua",
        "scripts/api/registry.lua",
        "scripts/api/mod_data_loader.lua",
        "scripts/api/builtin_tools.lua",
        "scripts/api/callbacks.lua",
        "scripts/api/public_events.lua",
        "scripts/api/remote_interface.lua",
        "scripts/map/vanilla_overlays.lua",
        "scripts/map/view_context.lua",
        "scripts/map/pollutant_display.lua",
        "scripts/map/settings_writer.lua",
        "scripts/map/player_settings.lua",
        "scripts/map/player_iteration.lua",
        "scripts/map/chart_watchers.lua",
        "scripts/player_resolution.lua",
        "scripts/map/visibility.lua",
        "scripts/gui/panel.lua",
        "scripts/gui/panel_layout.lua",
        "scripts/gui/panel_actions.lua",
        "scripts/gui/panel_overlays.lua",
        "scripts/gui/element_tree.lua",
        "scripts/gui/dispatch.lua",
        "scripts/gui/action_tools.lua",
        "scripts/builtin/init.lua",
        "scripts/tools/setup_dispatch.lua",
        "scripts/builtin/tag/dialog.lua",
        "scripts/builtin/tag/setup.lua",
        "scripts/builtin/tag/gui_handlers.lua",
        "scripts/tools/cursor.lua",
        "scripts/tools/quickbar_guard.lua",
        "scripts/tools/tool_notify.lua",
        "scripts/tools/tool_state.lua",
        "scripts/placement/ping.lua",
        "scripts/placement/tag.lua",
        "scripts/handlers/gui.lua",
        "scripts/handlers/player.lua"
      }

      for _, relative_path in ipairs(module_files) do
        assert_no_runtime_require(relative_path)
      end
    end
  },
  {
    name = "bootstrap lifecycle callbacks execute with stubs",
    run = function()
      test_env.with_factorio_stubs(function()
        local bootstrap = require("scripts.bootstrap")
        bootstrap.on_init()
        bootstrap.on_configuration_changed()
        bootstrap.on_load()
      end)
    end
  },
  {
    name = "configuration reload clears runtime-registered map tools",
    run = function()
      test_env.with_factorio_stubs(function()
        _G.script.active_mods = {
          ["extensible-map-overlay-framework"] = true,
          ["removed-mod"] = true
        }

        local bootstrap = require("scripts.bootstrap")
        local callbacks = require("scripts.api.callbacks")
        local registry = require("scripts.api.registry")
        local emof_storage = require("scripts.emof_storage")

        emof_storage.ensure_storage()
        bootstrap.on_init()

        callbacks.register_map_tool({
          id = "removed-mod-tool",
          owning_mod = "removed-mod",
          order = "z",
          cursor_item = "emof-ping-tool",
          on_click = {
            interface = "removed_iface",
            function_name = "on_click"
          }
        })

        assert.truthy(registry.get_tool("removed-mod-tool"), "expected tool to register before reload")

        bootstrap.on_configuration_changed()

        assert.falsy(registry.get_tool("removed-mod-tool"), "expected stale tool to be cleared on reload")

        _G.game.players[1] = { index = 1, valid = true }
        local ok, err = pcall(callbacks.start_map_tool, 1, "removed-mod-tool", {})
        assert.falsy(ok, "expected start_map_tool to fail for cleared tool")
        assert.contains(tostring(err), "unknown map tool")
      end)
    end
  }
}
