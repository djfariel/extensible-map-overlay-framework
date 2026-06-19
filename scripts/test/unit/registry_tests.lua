local assert = require("scripts.test.assert")
local test_env = require("scripts.test.test_env")

return {
  {
    name = "unregister rejects another mod's button",
    run = function()
      test_env.with_factorio_stubs(function()
        local registry = require("scripts.api.registry")

        registry.clear_buttons()
        registry.register_action({
          id = "other-mod-button",
          owning_mod = "other-mod",
          order = "a"
        })

        local removed = registry.unregister("compatibility-mod", "other-mod-button", "action")
        assert.falsy(removed, "expected unregister to fail for a different mod_name")
        assert.truthy(registry.get_action("other-mod-button"), "expected action to remain registered")
      end)
    end
  },
  {
    name = "unregister removes owned button",
    run = function()
      test_env.with_factorio_stubs(function()
        local registry = require("scripts.api.registry")

        registry.clear_buttons()
        registry.register_action({
          id = "owned-button",
          owning_mod = "owner-mod",
          order = "a"
        })

        local removed = registry.unregister("owner-mod", "owned-button", "action")
        assert.truthy(removed, "expected unregister to succeed for the owning mod")
        assert.falsy(registry.get_action("owned-button"), "expected action to be removed")
      end)
    end
  },
  {
    name = "clear_buttons allows re-registering map tools",
    run = function()
      test_env.with_factorio_stubs(function()
        local registry = require("scripts.api.registry")

        registry.clear_buttons()
        registry.register_tool({
          id = "consumer-tool",
          owning_mod = "consumer-mod",
          order = "a",
          cursor_item = "emof-ping-tool",
          on_click = {
            interface = "consumer",
            function_name = "on_click"
          }
        })

        registry.clear_buttons()

        local ok, err = pcall(registry.register_tool, {
          id = "consumer-tool",
          owning_mod = "consumer-mod",
          order = "a",
          cursor_item = "emof-ping-tool",
          on_click = {
            interface = "consumer",
            function_name = "on_click"
          }
        })

        assert.truthy(ok, "expected map tool re-registration after clear_buttons, got: " .. tostring(err))
        assert.truthy(registry.get_tool("consumer-tool"), "expected tool to be registered")
      end)
    end
  },
  {
    name = "duplicate id error includes both owning mods within the same kind",
    run = function()
      test_env.with_factorio_stubs(function()
        local registry = require("scripts.api.registry")

        registry.clear_buttons()
        registry.register_action({
          id = "shared-name",
          owning_mod = "first-mod",
          order = "a"
        })

        local ok, err = pcall(registry.register_action, {
          id = "shared-name",
          owning_mod = "second-mod",
          order = "b"
        })

        assert.falsy(ok, "expected duplicate registration to fail")
        assert.contains(tostring(err), "first-mod")
        assert.contains(tostring(err), "second-mod")
        assert.contains(tostring(err), "action button")
      end)
    end
  },
  {
    name = "unregister requires kind and only removes matching registration",
    run = function()
      test_env.with_factorio_stubs(function()
        local registry = require("scripts.api.registry")

        registry.clear_buttons()
        registry.register_action({
          id = "shared-name",
          owning_mod = "owner-mod",
          order = "a"
        })
        registry.register_tool({
          id = "shared-name",
          owning_mod = "owner-mod",
          order = "b",
          cursor_item = "emof-ping-tool",
          on_click = {
            interface = "consumer",
            function_name = "on_click"
          }
        })

        local removed_action = registry.unregister("owner-mod", "shared-name", "action")
        assert.truthy(removed_action)
        assert.falsy(registry.get_action("shared-name"))
        assert.truthy(registry.get_tool("shared-name"))

        local removed_tool = registry.unregister("owner-mod", "shared-name", "tool")
        assert.truthy(removed_tool)
        assert.falsy(registry.get_tool("shared-name"))
      end)
    end
  },
  {
    name = "same id may be registered across overlay action and tool kinds",
    run = function()
      test_env.with_factorio_stubs(function()
        local registry = require("scripts.api.registry")

        registry.clear_buttons()
        registry.register_overlay({
          id = "shared-name",
          owning_mod = "first-mod",
          order = "a"
        })
        registry.register_action({
          id = "shared-name",
          owning_mod = "second-mod",
          order = "b"
        })
        registry.register_tool({
          id = "shared-name",
          owning_mod = "third-mod",
          order = "c",
          cursor_item = "emof-ping-tool",
          on_click = {
            interface = "consumer",
            function_name = "on_click"
          }
        })

        assert.truthy(registry.get_overlay("shared-name"))
        assert.truthy(registry.get_action("shared-name"))
        assert.truthy(registry.get_tool("shared-name"))
      end)
    end
  },
  {
    name = "prune_extension_toggles removes stale overlay keys after reload",
    run = function()
      test_env.with_factorio_stubs(function()
        local registry = require("scripts.api.registry")
        local emof_storage = require("scripts.emof_storage")

        registry.clear_buttons()
        registry.register_overlay({
          id = "keep-overlay",
          owning_mod = "owner-mod",
          order = "a"
        })
        registry.register_overlay({
          id = "remove-overlay",
          owning_mod = "owner-mod",
          order = "b"
        })

        local state = emof_storage.get_player_state(1)
        state.extension_toggles["keep-overlay"] = true
        state.extension_toggles["remove-overlay"] = true

        registry.clear_buttons()
        registry.register_overlay({
          id = "keep-overlay",
          owning_mod = "owner-mod",
          order = "a"
        })
        registry.prune_extension_toggles()

        assert.equals(state.extension_toggles["keep-overlay"], true)
        assert.falsy(state.extension_toggles["remove-overlay"])
      end)
    end
  }
}
