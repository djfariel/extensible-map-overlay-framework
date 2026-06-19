local assert = require("scripts.test.assert")
local test_env = require("scripts.test.test_env")

return {
  {
    name = "mod_data_loader registers action buttons by data_type",
    run = function()
      test_env.with_factorio_stubs(function()
        _G.prototypes.mod_data = {
          ["test-action"] = {
            valid = true,
            name = "test-action",
            data_type = "emof.map-action-button",
            order = "a-010",
            localised_name = { "test.caption" },
            data = {
              size = "full",
              sprite = "utility/map"
            }
          }
        }

        local mod_data_loader = require("scripts.api.mod_data_loader")
        local registry = require("scripts.api.registry")

        registry.clear_buttons()
        mod_data_loader.load_all()

        local spec = registry.get_action("test-action")
        assert.truthy(spec, "expected action spec to be registered")
        assert.equals("full", spec.size)
        assert.equals("test-mod", spec.owning_mod)
        assert.equals("utility/map", spec.sprite)
      end)
    end
  },
  {
    name = "mod_data_loader registers overlay toggles by data_type",
    run = function()
      test_env.with_factorio_stubs(function()
        _G.prototypes.mod_data = {
          ["test-overlay"] = {
            valid = true,
            name = "test-overlay",
            data_type = "emof.map-overlay-toggle",
            order = "a-020",
            data = {
              sprite = "utility/map",
              visible_when = {
                remote_view_only = true
              }
            }
          }
        }

        local mod_data_loader = require("scripts.api.mod_data_loader")
        local registry = require("scripts.api.registry")

        registry.clear_buttons()
        mod_data_loader.load_all()

        local spec = registry.get_overlay("test-overlay")
        assert.truthy(spec, "expected overlay spec to be registered")
        assert.equals(true, spec.visible_when.remote_view_only)
      end)
    end
  },
  {
    name = "mod_data_loader rejects duplicate ids within the same kind",
    run = function()
      test_env.with_factorio_stubs(function()
        _G.prototypes.mod_data = {
          ["dup-id-a"] = {
            valid = true,
            name = "dup-id",
            data_type = "emof.map-action-button",
            data = {}
          },
          ["dup-id-b"] = {
            valid = true,
            name = "dup-id",
            data_type = "emof.map-action-button",
            data = {}
          }
        }

        local mod_data_loader = require("scripts.api.mod_data_loader")
        local registry = require("scripts.api.registry")

        registry.clear_buttons()
        local ok, err = pcall(mod_data_loader.load_all)
        assert.falsy(ok, "expected duplicate id within the same kind to raise an error")
        assert.contains(tostring(err), "action button")
      end)
    end
  },
  {
    name = "mod_data_loader registers tool-linked action buttons",
    run = function()
      test_env.with_factorio_stubs(function()
        _G.prototypes.mod_data = {
          ["test-tool-action"] = {
            valid = true,
            name = "test-tool-action",
            data_type = "emof.map-action-button",
            order = "a-015",
            data = {
              size = "half",
              tool_id = "my-tool",
              tool_start = "immediate"
            }
          }
        }

        local mod_data_loader = require("scripts.api.mod_data_loader")
        local registry = require("scripts.api.registry")

        registry.clear_buttons()
        mod_data_loader.load_all()

        local spec = registry.get_action("test-tool-action")
        assert.truthy(spec, "expected action spec to be registered")
        assert.equals("my-tool", spec.tool_id)
        assert.equals("immediate", spec.tool_start)
      end)
    end
  },
  {
    name = "mod_data_loader rejects invalid action size",
    run = function()
      test_env.with_factorio_stubs(function()
        _G.prototypes.mod_data = {
          ["bad-size"] = {
            valid = true,
            name = "bad-size",
            data_type = "emof.map-action-button",
            data = {
              size = "wide"
            }
          }
        }

        local mod_data_loader = require("scripts.api.mod_data_loader")
        local registry = require("scripts.api.registry")

        registry.clear_buttons()
        local ok = pcall(mod_data_loader.load_all)
        assert.falsy(ok, "expected invalid size to raise an error")
      end)
    end
  },
  {
    name = "mod_data_loader rejects tool_start without tool_id",
    run = function()
      test_env.with_factorio_stubs(function()
        _G.prototypes.mod_data = {
          ["bad-tool-start"] = {
            valid = true,
            name = "bad-tool-start",
            data_type = "emof.map-action-button",
            data = {
              tool_start = "immediate"
            }
          }
        }

        local mod_data_loader = require("scripts.api.mod_data_loader")
        local registry = require("scripts.api.registry")

        registry.clear_buttons()
        local ok = pcall(mod_data_loader.load_all)
        assert.falsy(ok, "expected tool_start without tool_id to raise an error")
      end)
    end
  },
  {
    name = "mod_data_loader registers setup tool_start on action buttons",
    run = function()
      test_env.with_factorio_stubs(function()
        _G.prototypes.mod_data = {
          ["test-setup-action"] = {
            valid = true,
            name = "test-setup-action",
            data_type = "emof.map-action-button",
            order = "a-016",
            data = {
              size = "half",
              tool_id = "my-tool",
              tool_start = "setup"
            }
          }
        }

        local mod_data_loader = require("scripts.api.mod_data_loader")
        local registry = require("scripts.api.registry")

        registry.clear_buttons()
        mod_data_loader.load_all()

        local spec = registry.get_action("test-setup-action")
        assert.truthy(spec, "expected action spec to be registered")
        assert.equals("setup", spec.tool_start)
      end)
    end
  },
  {
    name = "mod_data_loader rejects legacy tag_dialog tool_start",
    run = function()
      test_env.with_factorio_stubs(function()
        _G.prototypes.mod_data = {
          ["legacy-tag-action"] = {
            valid = true,
            name = "legacy-tag-action",
            data_type = "emof.map-action-button",
            data = {
              tool_id = "tag",
              tool_start = "tag_dialog"
            }
          }
        }

        local mod_data_loader = require("scripts.api.mod_data_loader")
        local registry = require("scripts.api.registry")

        registry.clear_buttons()
        local ok = pcall(mod_data_loader.load_all)
        assert.falsy(ok, "expected legacy tag_dialog tool_start to raise an error")
      end)
    end
  }
}
