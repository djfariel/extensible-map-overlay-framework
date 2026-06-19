local assert = require("scripts.test.assert")
local test_env = require("scripts.test.test_env")

return {
  {
    name = "tag setup requires an icon or text before confirm",
    run = function()
      test_env.with_factorio_stubs(function()
        local tag = require("scripts.placement.tag")

        assert.falsy(tag.setup_has_content(nil, ""), "Expected empty setup to be rejected")
        assert.falsy(tag.setup_has_content(nil, "   "), "Expected whitespace-only text to be rejected")
        assert.truthy(tag.setup_has_content(nil, "Outpost"), "Expected text-only setup to be allowed")
        assert.truthy(tag.setup_has_content({ type = "virtual", name = "signal-iron-plate" }, ""), "Expected icon-only setup to be allowed")
      end)
    end
  },
  {
    name = "tag icon defaults to signal-map-marker when icon and text are empty",
    run = function()
      test_env.with_factorio_stubs(function()
        local constants = require("scripts.constants")
        local tag = require("scripts.placement.tag")

        local icon = tag.resolve_chart_tag_icon(nil, "")
        assert.equals("virtual", icon.type)
        assert.equals(constants.DEFAULT_TAG_ICON.name, icon.name)
      end)
    end
  },
  {
    name = "tag icon stays unset for text-only tags",
    run = function()
      test_env.with_factorio_stubs(function()
        local tag = require("scripts.placement.tag")

        assert.falsy(tag.resolve_chart_tag_icon(nil, "Outpost"), "Expected text-only tag to omit icon")
      end)
    end
  }
}
