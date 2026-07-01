local assertions = require("assertions")
local describe = assertions.describe
local it = assertions.it
local assert = assertions.assert
local test_env = require("scripts.test.test_env")
local player_fixtures = require("scripts.test.fixtures.player")

describe("constants", function()
  it("exposes INTERFACE_NAME", function()
    test_env.with_factorio_stubs(function()
      local constants = require("scripts.constants")
      assert.equal("extensible_map_overlay_framework", constants.INTERFACE_NAME)
    end)
  end)

  it("exposes MOD_DATA_TYPE values", function()
    test_env.with_factorio_stubs(function()
      local constants = require("scripts.constants")
      assert.equal("emof.map-action-button", constants.MOD_DATA_TYPE.map_action_button)
      assert.equal("emof.map-overlay-toggle", constants.MOD_DATA_TYPE.map_overlay_toggle)
    end)
  end)

  it("exposes PUBLIC_EVENT names", function()
    test_env.with_factorio_stubs(function()
      local constants = require("scripts.constants")
      assert.equal("emof-on-map-action-clicked", constants.PUBLIC_EVENT.map_action_clicked)
      assert.equal("emof-on-map-overlay-toggled", constants.PUBLIC_EVENT.map_overlay_toggled)
      assert.equal("emof-on-tool-state-changed", constants.PUBLIC_EVENT.tool_state_changed)
    end)
  end)

  it("exposes CUSTOM_INPUT names", function()
    test_env.with_factorio_stubs(function()
      local constants = require("scripts.constants")
      assert.equal("emof-map-click", constants.CUSTOM_INPUT.map_click)
      assert.equal("emof-cancel", constants.CUSTOM_INPUT.cancel)
      assert.equal("emof-toggle-chart-controls", constants.CUSTOM_INPUT.toggle_panel)
    end)
  end)

  it("exposes CURSOR_TOOL names", function()
    test_env.with_factorio_stubs(function()
      local constants = require("scripts.constants")
      assert.equal("emof-ping-tool", constants.CURSOR_TOOL.ping)
      assert.equal("emof-tag-tool", constants.CURSOR_TOOL.tag)
    end)
  end)

  it("exposes REGISTRATION_KIND values", function()
    test_env.with_factorio_stubs(function()
      local constants = require("scripts.constants")
      assert.equal("overlay", constants.REGISTRATION_KIND.overlay)
      assert.equal("action", constants.REGISTRATION_KIND.action)
      assert.equal("tool", constants.REGISTRATION_KIND.tool)
    end)
  end)

  it("exposes GUI constants", function()
    test_env.with_factorio_stubs(function()
      local constants = require("scripts.constants")
      assert.equal("emof_map_panel", constants.GUI.map_panel)
      assert.equal("emof_actions_inset", constants.GUI.actions_inset)
      assert.equal("emof_overlay_region", constants.GUI.overlay_region)
    end)
  end)

  it("exposes BUILTIN_TOOL names", function()
    test_env.with_factorio_stubs(function()
      local constants = require("scripts.constants")
      assert.equal("ping", constants.BUILTIN_TOOL.ping)
      assert.equal("tag", constants.BUILTIN_TOOL.tag)
    end)
  end)

  it("OWNING_MOD matches expected mod id", function()
    test_env.with_factorio_stubs(function()
      local constants = require("scripts.constants")
      assert.equal("extensible-map-overlay-framework", constants.OWNING_MOD)
    end)
  end)
end)

describe("emof_storage", function()
  it("ensure_storage initializes all storage sections", function()
    test_env.with_factorio_stubs(function()
      local emof_storage = require("scripts.emof_storage")
      emof_storage.ensure_storage()
      assert.is_not_nil(storage.emof.registry)
      assert.is_not_nil(storage.emof.players)
      assert.is_not_nil(storage.emof.builtin_tag_setup)
      assert.is_not_nil(storage.emof.cursor_label_requests)
      assert.is_not_nil(storage.emof.chart_watchers)
    end)
  end)

  it("get_registry returns the registry table", function()
    test_env.with_factorio_stubs(function()
      local emof_storage = require("scripts.emof_storage")
      emof_storage.ensure_storage()
      local registry = emof_storage.get_registry()
      assert.is_type("table", registry)
      assert.is_type("table", registry.overlay_specs)
      assert.is_type("table", registry.action_specs)
      assert.is_type("table", registry.tool_specs)
    end)
  end)

  it("get_all_players returns the players table", function()
    test_env.with_factorio_stubs(function()
      local emof_storage = require("scripts.emof_storage")
      emof_storage.ensure_storage()
      local players = emof_storage.get_all_players()
      assert.is_type("table", players)
    end)
  end)

  it("get_player_state creates a player state with defaults", function()
    test_env.with_factorio_stubs(function()
      local emof_storage = require("scripts.emof_storage")
      emof_storage.ensure_storage()
      local state = emof_storage.get_player_state(1)
      assert.is_false(state.panel_visible)
      assert.is_true(state.panel_open)
      assert.is_false(state.overlay_drawer_visible)
      assert.is_nil(state.last_pollutant_name)
      assert.is_false(state.initialized_map_settings)
      assert.is_type("table", state.vanilla_toggles)
      assert.is_type("table", state.extension_toggles)
      assert.is_nil(state.active_tool)
    end)
  end)

  it("get_player_state returns existing state for same player", function()
    test_env.with_factorio_stubs(function()
      local emof_storage = require("scripts.emof_storage")
      emof_storage.ensure_storage()
      local state1 = emof_storage.get_player_state(1)
      state1.panel_open = false
      local state2 = emof_storage.get_player_state(1)
      assert.is_false(state2.panel_open)
    end)
  end)

  it("get_player_state normalizes panel_open to true when nil", function()
    test_env.with_factorio_stubs(function()
      local emof_storage = require("scripts.emof_storage")
      emof_storage.ensure_storage()
      local state = emof_storage.get_player_state(2)
      state.panel_open = nil
      local normalized = emof_storage.get_player_state(2)
      assert.is_true(normalized.panel_open)
    end)
  end)

  it("remove_player removes player state and chart watchers", function()
    test_env.with_factorio_stubs(function()
      local emof_storage = require("scripts.emof_storage")
      emof_storage.ensure_storage()
      emof_storage.get_player_state(3)
      emof_storage.get_chart_watchers()[3] = { data = true }
      emof_storage.remove_player(3)
      assert.is_nil(emof_storage.get_all_players()[3])
      assert.is_nil(emof_storage.get_chart_watchers()[3])
    end)
  end)

  it("get_tag_setup_state creates default state", function()
    test_env.with_factorio_stubs(function()
      local emof_storage = require("scripts.emof_storage")
      emof_storage.ensure_storage()
      local state = emof_storage.get_tag_setup_state(1)
      assert.is_nil(state.icon)
      assert.equal("", state.text)
    end)
  end)

  it("clear_tag_setup_state removes player tag setup", function()
    test_env.with_factorio_stubs(function()
      local emof_storage = require("scripts.emof_storage")
      emof_storage.ensure_storage()
      emof_storage.get_tag_setup_state(1)
      emof_storage.clear_tag_setup_state(1)
      local state = emof_storage.get_tag_setup_state(1)
      assert.is_nil(state.icon)
      assert.equal("", state.text)
    end)
  end)

  it("consume_action_tool_validation_pending returns false when not pending", function()
    test_env.with_factorio_stubs(function()
      local emof_storage = require("scripts.emof_storage")
      emof_storage.ensure_storage()
      local consumed = emof_storage.consume_action_tool_validation_pending()
      assert.is_false(consumed)
    end)
  end)

  it("schedule and consume action tool validation", function()
    test_env.with_factorio_stubs(function()
      local emof_storage = require("scripts.emof_storage")
      emof_storage.ensure_storage()
      emof_storage.schedule_action_tool_validation()
      assert.is_true(storage.emof.validate_action_tools_pending)
      local consumed = emof_storage.consume_action_tool_validation_pending()
      assert.is_true(consumed)
      assert.is_false(storage.emof.validate_action_tools_pending)
    end)
  end)
end)

describe("player_resolution", function()
  it("from_index returns nil for nil index", function()
    test_env.with_factorio_stubs(function()
      local player_resolution = require("scripts.player_resolution")
      assert.is_nil(player_resolution.from_index(nil))
    end)
  end)

  it("from_index returns nil for invalid player", function()
    test_env.with_factorio_stubs(function()
      local player_resolution = require("scripts.player_resolution")
      assert.is_nil(player_resolution.from_index(999))
    end)
  end)

  it("from_index returns player for valid index", function()
    test_env.with_factorio_stubs(function()
      local player_resolution = require("scripts.player_resolution")
      local player = player_fixtures.make_player()
      local resolved = player_resolution.from_index(player.index)
      assert.is_true(resolved == player)
    end)
  end)

  it("from_event returns nil for nil event", function()
    test_env.with_factorio_stubs(function()
      local player_resolution = require("scripts.player_resolution")
      assert.is_nil(player_resolution.from_event(nil))
    end)
  end)

  it("from_event returns nil for event with no valid player", function()
    test_env.with_factorio_stubs(function()
      local player_resolution = require("scripts.player_resolution")
      assert.is_nil(player_resolution.from_event({ player_index = 999 }))
    end)
  end)

  it("from_event returns player for valid event", function()
    test_env.with_factorio_stubs(function()
      local player_resolution = require("scripts.player_resolution")
      local player = player_fixtures.make_player()
      local resolved = player_resolution.from_event({ player_index = player.index })
      assert.is_true(resolved == player)
    end)
  end)

  it("require_index errors for nil player_index", function()
    test_env.with_factorio_stubs(function()
      local player_resolution = require("scripts.player_resolution")
      local ok, err = pcall(player_resolution.require_index, nil)
      assert.is_false(ok)
      assert.matches("player_index", tostring(err))
    end)
  end)

  it("require_index errors for invalid player index", function()
    test_env.with_factorio_stubs(function()
      local player_resolution = require("scripts.player_resolution")
      local ok, err = pcall(player_resolution.require_index, 999)
      assert.is_false(ok)
      assert.matches("no valid player", tostring(err))
    end)
  end)

  it("require_index returns player for valid index", function()
    test_env.with_factorio_stubs(function()
      local player_resolution = require("scripts.player_resolution")
      local player = player_fixtures.make_player()
      local resolved = player_resolution.require_index(player.index)
      assert.is_true(resolved == player)
    end)
  end)
end)

describe("view_context", function()
  it("chart_surface returns nil for nil player", function()
    test_env.with_factorio_stubs(function()
      local view_context = require("scripts.map.view_context")
      assert.is_nil(view_context.chart_surface(nil))
    end)
  end)

  it("chart_surface returns player surface when valid", function()
    test_env.with_factorio_stubs(function()
      local view_context = require("scripts.map.view_context")
      local player = player_fixtures.make_player()
      local surface = view_context.chart_surface(player)
      assert.is_true(surface == player.surface)
    end)
  end)

  it("chart_surface falls back to physical_surface", function()
    test_env.with_factorio_stubs(function()
      local view_context = require("scripts.map.view_context")
      local player = player_fixtures.make_player()
      player.surface = { valid = false }
      player.physical_surface = { valid = true, index = 2, name = "test-surface" }
      local surface = view_context.chart_surface(player)
      assert.is_true(surface == player.physical_surface)
    end)
  end)

  it("is_chart_view returns false for nil player", function()
    test_env.with_factorio_stubs(function()
      local view_context = require("scripts.map.view_context")
      assert.is_false(view_context.is_chart_view(nil))
    end)
  end)

  it("is_chart_view returns true for chart render mode", function()
    test_env.with_factorio_stubs(function()
      local view_context = require("scripts.map.view_context")
      local player = player_fixtures.make_player()
      player.render_mode = 1
      assert.is_true(view_context.is_chart_view(player))
    end)
  end)

  it("is_chart_view returns true for remote controller", function()
    test_env.with_factorio_stubs(function()
      local view_context = require("scripts.map.view_context")
      local player = player_fixtures.make_player()
      player.render_mode = nil
      player.controller_type = 1
      assert.is_true(view_context.is_chart_view(player))
    end)
  end)

  it("is_chart_view returns false for non-chart view", function()
    test_env.with_factorio_stubs(function()
      local view_context = require("scripts.map.view_context")
      local player = player_fixtures.make_player()
      player.render_mode = nil
      player.controller_type = nil
      assert.is_false(view_context.is_chart_view(player))
    end)
  end)

  it("surface_index returns nil when no chart surface", function()
    test_env.with_factorio_stubs(function()
      local view_context = require("scripts.map.view_context")
      local player = player_fixtures.make_player()
      player.surface = { valid = false }
      player.physical_surface = nil
      assert.is_nil(view_context.surface_index(player))
    end)
  end)

  it("surface_index returns surface index when available", function()
    test_env.with_factorio_stubs(function()
      local view_context = require("scripts.map.view_context")
      local player = player_fixtures.make_player()
      local idx = view_context.surface_index(player)
      assert.is_type("number", idx)
      assert.equal(1, idx)
    end)
  end)

  it("is_overlay_drawer_visible returns false for non-chart view", function()
    test_env.with_factorio_stubs(function()
      local view_context = require("scripts.map.view_context")
      local player = player_fixtures.make_player()
      player.render_mode = nil
      player.controller_type = nil
      assert.is_false(view_context.is_overlay_drawer_visible(player))
    end)
  end)
end)

describe("public_events", function()
  it("event_id returns the correct event id for map_action_clicked", function()
    test_env.with_factorio_stubs(function()
      local public_events = require("scripts.api.public_events")
      local id = public_events.event_id("emof-on-map-action-clicked")
      assert.is_type("number", id)
      assert.equal(3001, id)
    end)
  end)

  it("event_id returns the correct event id for map_overlay_toggled", function()
    test_env.with_factorio_stubs(function()
      local public_events = require("scripts.api.public_events")
      local id = public_events.event_id("emof-on-map-overlay-toggled")
      assert.equal(3002, id)
    end)
  end)

  it("event_id returns the correct event id for tool_state_changed", function()
    test_env.with_factorio_stubs(function()
      local public_events = require("scripts.api.public_events")
      local id = public_events.event_id("emof-on-tool-state-changed")
      assert.equal(3003, id)
    end)
  end)

  it("event_id errors for missing custom event prototype", function()
    test_env.with_factorio_stubs(function()
      local public_events = require("scripts.api.public_events")
      local ok, err = pcall(public_events.event_id, "nonexistent-event")
      assert.is_false(ok)
      assert.matches("missing custom event prototype", tostring(err))
    end)
  end)
end)

describe("cursor tool", function()
  it("is_equipped returns false for nil player", function()
    test_env.with_factorio_stubs(function()
      local cursor = require("scripts.tools.cursor")
      assert.is_false(cursor.is_equipped(nil, "emof-ping-tool"))
    end)
  end)

  it("is_equipped returns false for nil item_name", function()
    test_env.with_factorio_stubs(function()
      local cursor = require("scripts.tools.cursor")
      local player = player_fixtures.make_player()
      assert.is_false(cursor.is_equipped(player, nil))
    end)
  end)

  it("is_equipped returns false when cursor stack is invalid", function()
    test_env.with_factorio_stubs(function()
      local cursor = require("scripts.tools.cursor")
      local player = player_fixtures.make_player()
      player.cursor_stack.valid_for_read = false
      assert.is_false(cursor.is_equipped(player, "emof-ping-tool"))
    end)
  end)

  it("is_equipped returns true when cursor matches item_name", function()
    test_env.with_factorio_stubs(function()
      local cursor = require("scripts.tools.cursor")
      local player = player_fixtures.make_player()
      player.cursor_stack.valid_for_read = true
      player.cursor_stack.name = "emof-ping-tool"
      assert.is_true(cursor.is_equipped(player, "emof-ping-tool"))
    end)
  end)

  it("is_equipped returns false when cursor has different item", function()
    test_env.with_factorio_stubs(function()
      local cursor = require("scripts.tools.cursor")
      local player = player_fixtures.make_player()
      player.cursor_stack.valid_for_read = true
      player.cursor_stack.name = "emof-tag-tool"
      assert.is_false(cursor.is_equipped(player, "emof-ping-tool"))
    end)
  end)

  it("equip returns false for nil player", function()
    test_env.with_factorio_stubs(function()
      local cursor = require("scripts.tools.cursor")
      assert.is_false(cursor.equip(nil, "emof-ping-tool"))
    end)
  end)

  it("equip returns false when cursor cannot set stack", function()
    test_env.with_factorio_stubs(function()
      local cursor = require("scripts.tools.cursor")
      local player = player_fixtures.make_player()
      player.cursor_stack.can_set_stack = function() return false end
      assert.is_false(cursor.equip(player, "emof-ping-tool"))
    end)
  end)

  it("equip sets cursor stack and returns true", function()
    test_env.with_factorio_stubs(function()
      local cursor = require("scripts.tools.cursor")
      local player = player_fixtures.make_player()
      local result = cursor.equip(player, "emof-ping-tool")
      assert.is_true(result)
      assert.equal("emof-ping-tool", player.cursor_stack.name)
      assert.is_true(player.cursor_stack.valid_for_read)
    end)
  end)

  it("equip applies label to cursor stack", function()
    test_env.with_factorio_stubs(function()
      local cursor = require("scripts.tools.cursor")
      local player = player_fixtures.make_player()
      cursor.equip(player, "emof-ping-tool", { label = "My Ping Tool" })
      assert.equal("My Ping Tool", player.cursor_stack.label)
    end)
  end)

  it("equip skips empty label", function()
    test_env.with_factorio_stubs(function()
      local cursor = require("scripts.tools.cursor")
      local player = player_fixtures.make_player()
      cursor.equip(player, "emof-ping-tool", { label = "" })
      assert.is_nil(player.cursor_stack.label)
    end)
  end)

  it("apply_label returns false for invalid stack", function()
    test_env.with_factorio_stubs(function()
      local cursor = require("scripts.tools.cursor")
      local player = player_fixtures.make_player()
      player.cursor_stack.valid_for_read = false
      local result = cursor.apply_label(player.cursor_stack, { label = "Test" }, player, "emof-ping-tool")
      assert.is_false(result)
    end)
  end)

  it("apply_label returns false for nil label_options", function()
    test_env.with_factorio_stubs(function()
      local cursor = require("scripts.tools.cursor")
      local player = player_fixtures.make_player()
      local result = cursor.apply_label(player.cursor_stack, nil, player, "emof-ping-tool")
      assert.is_false(result)
    end)
  end)

  it("apply_label handles localised label table", function()
    test_env.with_factorio_stubs(function()
      local cursor = require("scripts.tools.cursor")
      local player = player_fixtures.make_player()
      player.cursor_stack.valid_for_read = true
      local request_id = nil
      function player.request_translation(localised)
        request_id = 42
        return request_id
      end
      cursor.apply_label(player.cursor_stack, {
        label = { "item-name.emof-ping-tool" },
        label_color = { r = 1, g = 0, b = 0 }
      }, player, "emof-ping-tool")
      assert.equal(42, request_id)
    end)
  end)

  it("apply_label sets label_color for string labels", function()
    test_env.with_factorio_stubs(function()
      local cursor = require("scripts.tools.cursor")
      local player = player_fixtures.make_player()
      player.cursor_stack.valid_for_read = true
      cursor.apply_label(player.cursor_stack, {
        label = "Red Tool",
        label_color = { r = 1, g = 0, b = 0 }
      }, player, "emof-ping-tool")
      assert.equal("Red Tool", player.cursor_stack.label)
      assert.is_type("table", player.cursor_stack.label_color)
    end)
  end)

  it("clear removes cursor when equipped", function()
    test_env.with_factorio_stubs(function()
      local cursor = require("scripts.tools.cursor")
      local player = player_fixtures.make_player()
      cursor.equip(player, "emof-ping-tool")
      cursor.clear(player, "emof-ping-tool")
      assert.is_false(player.cursor_stack.valid_for_read)
    end)
  end)

  it("clear does nothing when cursor is not equipped", function()
    test_env.with_factorio_stubs(function()
      local cursor = require("scripts.tools.cursor")
      local player = player_fixtures.make_player()
      player.cursor_stack.valid_for_read = true
      player.cursor_stack.name = "iron-plate"
      cursor.clear(player, "emof-ping-tool")
      assert.equal("iron-plate", player.cursor_stack.name)
    end)
  end)
end)

describe("tool_notify", function()
  it("raise raises tool_state_changed and action_state_changed events", function()
    test_env.with_factorio_stubs(function()
      local tool_notify = require("scripts.tools.tool_notify")
      local raised_events = {}
      script.raise_event = function(event_id, payload)
        raised_events[#raised_events + 1] = { event_id = event_id, payload = payload }
      end

      tool_notify.raise(1, {
        active_tool_id = "ping",
        cancelled_tool_id = nil,
        reason = "done"
      })

      assert.equal(2, #raised_events)
      assert.equal(1, raised_events[1].payload.player_index)
      assert.equal("ping", raised_events[1].payload.active_tool_id)
      assert.equal("done", raised_events[1].payload.reason)
    end)
  end)

  it("raise with nil detail sends nil values", function()
    test_env.with_factorio_stubs(function()
      local tool_notify = require("scripts.tools.tool_notify")
      local raised_events = {}
      script.raise_event = function(event_id, payload)
        raised_events[#raised_events + 1] = { event_id = event_id, payload = payload }
      end

      tool_notify.raise(1, nil)

      assert.equal(2, #raised_events)
      assert.is_nil(raised_events[1].payload.active_tool_id)
      assert.is_nil(raised_events[1].payload.cancelled_tool_id)
      assert.is_nil(raised_events[1].payload.reason)
    end)
  end)
end)

describe("callbacks API", function()
  it("register_overlay_toggle validates and registers overlay", function()
    test_env.with_factorio_stubs(function()
      local callbacks = require("scripts.api.callbacks")
      local registry = require("scripts.api.registry")
      registry.clear_buttons()

      callbacks.register_overlay_toggle({
        id = "test-overlay",
        owning_mod = "test-mod",
        order = "a"
      })

      local overlay = registry.get_overlay("test-overlay")
      assert.is_not_nil(overlay)
      assert.equal("test-overlay", overlay.id)
      assert.equal("test-mod", overlay.owning_mod)
    end)
  end)

  it("set_player_toggle validates boolean value", function()
    test_env.with_factorio_stubs(function()
      local callbacks = require("scripts.api.callbacks")
      local registry = require("scripts.api.registry")
      registry.clear_buttons()
      registry.register_overlay({
        id = "test-overlay",
        owning_mod = "test-mod",
        order = "a"
      })
      local player = player_fixtures.make_player()

      local ok, err = pcall(callbacks.set_player_toggle, player.index, "test-overlay", "not-a-boolean")
      assert.is_false(ok)
      assert.matches("expected boolean", tostring(err))
    end)
  end)

  it("set_player_toggle errors for unknown overlay id", function()
    test_env.with_factorio_stubs(function()
      local callbacks = require("scripts.api.callbacks")
      local player = player_fixtures.make_player()

      local ok, err = pcall(callbacks.set_player_toggle, player.index, "unknown-overlay", true)
      assert.is_false(ok)
      assert.matches("unknown overlay id", tostring(err))
    end)
  end)

  it("get_player_toggle returns the stored toggle value", function()
    test_env.with_factorio_stubs(function()
      local callbacks = require("scripts.api.callbacks")
      local registry = require("scripts.api.registry")
      registry.clear_buttons()
      registry.register_overlay({
        id = "test-overlay",
        owning_mod = "test-mod",
        order = "a"
      })
      local player = player_fixtures.make_player()

      callbacks.set_player_toggle(player.index, "test-overlay", true)
      assert.is_true(callbacks.get_player_toggle(player.index, "test-overlay"))

      callbacks.set_player_toggle(player.index, "test-overlay", false)
      assert.is_false(callbacks.get_player_toggle(player.index, "test-overlay"))
    end)
  end)

  it("unregister errors for invalid mod_name", function()
    test_env.with_factorio_stubs(function()
      local callbacks = require("scripts.api.callbacks")
      local ok, err = pcall(callbacks.unregister, "", "test", "overlay")
      assert.is_false(ok)
      assert.matches("mod_name", tostring(err))
    end)
  end)

  it("unregister errors for invalid kind", function()
    test_env.with_factorio_stubs(function()
      local callbacks = require("scripts.api.callbacks")
      local ok, err = pcall(callbacks.unregister, "test-mod", "test", "invalid-kind")
      assert.is_false(ok)
      assert.matches("kind", tostring(err))
    end)
  end)

  it("try_register_map_tool returns ok=true on success", function()
    test_env.with_factorio_stubs(function()
      local callbacks = require("scripts.api.callbacks")
      local result = callbacks.try_register_map_tool({
        id = "test-tool",
        owning_mod = "test-mod",
        order = "a",
        cursor_item = "emof-ping-tool",
        on_click = { interface = "test_iface", function_name = "on_click" }
      })
      assert.is_true(result.ok)
    end)
  end)

  it("try_register_map_tool returns ok=false on failure", function()
    test_env.with_factorio_stubs(function()
      local callbacks = require("scripts.api.callbacks")
      local result = callbacks.try_register_map_tool({
        id = "test-tool",
        owning_mod = "nonexistent-mod",
        order = "a",
        cursor_item = "emof-ping-tool",
        on_click = { interface = "test_iface", function_name = "on_click" }
      })
      assert.is_false(result.ok)
      assert.matches("not active", result.error)
    end)
  end)

  it("is_action_enabled returns true when spec has no enabled field", function()
    test_env.with_factorio_stubs(function()
      local callbacks = require("scripts.api.callbacks")
      local registry = require("scripts.api.registry")
      registry.clear_buttons()
      registry.register_action({
        id = "simple-action",
        owning_mod = "test-mod",
        order = "a"
      })
      local player = player_fixtures.make_player()
      assert.is_true(callbacks.is_action_enabled(player.index, "simple-action"))
    end)
  end)

  it("is_action_enabled calls remote callback when enabled field exists", function()
    test_env.with_factorio_stubs(function()
      local callbacks = require("scripts.api.callbacks")
      local registry = require("scripts.api.registry")
      registry.clear_buttons()
      registry.register_action({
        id = "conditional-action",
        owning_mod = "test-mod",
        order = "a",
        enabled = {
          interface = "test_iface",
          function_name = "is_enabled"
        }
      })

      _G.remote.call = function(interface, fn, payload)
        if interface == "test_iface" and fn == "is_enabled" then
          return false
        end
        return true
      end

      local player = player_fixtures.make_player()
      assert.is_false(callbacks.is_action_enabled(player.index, "conditional-action"))
    end)
  end)

  it("start_map_tool errors for unknown tool id", function()
    test_env.with_factorio_stubs(function()
      local callbacks = require("scripts.api.callbacks")
      local player = player_fixtures.make_player()
      local ok, err = pcall(callbacks.start_map_tool, player.index, "unknown-tool", {})
      assert.is_false(ok)
      assert.matches("unknown map tool id", tostring(err))
    end)
  end)

  it("start_map_tool returns false for invalid player", function()
    test_env.with_factorio_stubs(function()
      local callbacks = require("scripts.api.callbacks")
      local ok = callbacks.start_map_tool(999, "test-tool", {})
      assert.is_false(ok)
    end)
  end)

  it("cancel_map_tool returns false for invalid player", function()
    test_env.with_factorio_stubs(function()
      local callbacks = require("scripts.api.callbacks")
      local ok = callbacks.cancel_map_tool(999, "test-reason")
      assert.is_false(ok)
    end)
  end)
end)

describe("validation API", function()
  it("validate_overlay_toggle_spec requires id and owning_mod", function()
    test_env.with_factorio_stubs(function()
      local validation = require("scripts.api.validation")
      local ok, err = pcall(validation.validate_overlay_toggle_spec, { owning_mod = "test-mod" })
      assert.is_false(ok)
      assert.matches("id", tostring(err))
    end)
  end)

  it("validate_action_button_spec requires id and owning_mod", function()
    test_env.with_factorio_stubs(function()
      local validation = require("scripts.api.validation")
      local ok, err = pcall(validation.validate_action_button_spec, { owning_mod = "test-mod" })
      assert.is_false(ok)
      assert.matches("id", tostring(err))
    end)
  end)

  it("validate_map_tool requires id, owning_mod, cursor_item, and on_click", function()
    test_env.with_factorio_stubs(function()
      local validation = require("scripts.api.validation")
      local ok, err = pcall(validation.validate_map_tool, { id = "test", owning_mod = "test-mod" })
      assert.is_false(ok)
      assert.matches("cursor_item", tostring(err))
    end)
  end)
end)
