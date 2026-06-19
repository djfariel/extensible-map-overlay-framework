---@diagnostic disable: undefined-global

local function normalize(path)
  return (path:gsub("\\", "/"))
end

local function dirname(path)
  local normalized = normalize(path)
  return normalized:match("^(.*)/[^/]+$") or "."
end

local script_path = arg[0] or "tools/run-unit-tests.lua"
local tools_dir = dirname(script_path)
local root = dirname(tools_dir)

_G.__EMOF_TEST_ROOT = root

package.path = table.concat({
  root .. "/?.lua",
  root .. "/?/init.lua",
  package.path
}, ";")

local runner = require("scripts.test.test_runner")
local bootstrap_tests = require("scripts.test.unit.bootstrap_tests")
local load_smoke_tests = require("scripts.test.unit.load_smoke_tests")
local mod_data_loader_tests = require("scripts.test.unit.mod_data_loader_tests")
local registry_tests = require("scripts.test.unit.registry_tests")
local action_tools_tests = require("scripts.test.unit.action_tools_tests")
local callbacks_tests = require("scripts.test.unit.callbacks_tests")
local chart_watchers_tests = require("scripts.test.unit.chart_watchers_tests")
local click_payload_tests = require("scripts.test.unit.click_payload_tests")
local tag_logic_tests = require("scripts.test.unit.tag_logic_tests")
local tag_setup_tests = require("scripts.test.unit.tag_setup_tests")
local emof_cursor_item_tests = require("scripts.test.unit.emof_cursor_item_tests")
local quickbar_guard_tests = require("scripts.test.unit.quickbar_guard_tests")
local ping_logic_tests = require("scripts.test.unit.ping_logic_tests")
local tool_state_tests = require("scripts.test.unit.tool_state_tests")
local player_handler_tests = require("scripts.test.unit.player_handler_tests")
local player_iteration_tests = require("scripts.test.unit.player_iteration_tests")
local player_settings_tests = require("scripts.test.unit.player_settings_tests")
local settings_writer_tests = require("scripts.test.unit.settings_writer_tests")
local validation_tests = require("scripts.test.unit.validation_tests")
local pollutant_display_tests = require("scripts.test.unit.pollutant_display_tests")

local modules = {
  bootstrap_tests,
  load_smoke_tests,
  emof_cursor_item_tests,
  mod_data_loader_tests,
  registry_tests,
  callbacks_tests,
  chart_watchers_tests,
  click_payload_tests,
  action_tools_tests,
  tag_logic_tests,
  tag_setup_tests,
  quickbar_guard_tests,
  ping_logic_tests,
  tool_state_tests,
  player_handler_tests,
  player_iteration_tests,
  player_settings_tests,
  settings_writer_tests,
  validation_tests,
  pollutant_display_tests
}

local result = runner.run_modules("emof-unit", modules)

if result.failed > 0 then
  io.stderr:write("Unit tests failed.\n")
  for _, failure in ipairs(result.failures) do
    io.stderr:write(failure.name .. ": " .. failure.message .. "\n")
  end
  os.exit(1)
end

io.write("Unit tests passed: " .. tostring(result.passed) .. "\n")
