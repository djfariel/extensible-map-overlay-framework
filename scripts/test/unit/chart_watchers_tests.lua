local assert = require("scripts.test.assert")
local test_env = require("scripts.test.test_env")

return {
  {
    name = "chart_watchers only tracks panel-open players",
    run = function()
      test_env.with_factorio_stubs(function()
        local chart_watchers = require("scripts.map.chart_watchers")
        local emof_storage = require("scripts.emof_storage")

        emof_storage.ensure_storage()
        chart_watchers.track(1)
        chart_watchers.track(2)
        chart_watchers.untrack(2)

        local seen = {}
        chart_watchers.each_tracked(function(player)
          seen[#seen + 1] = player.index
        end)

        assert.equals(#seen, 0, "expected no callbacks without valid game players")
        assert.falsy(emof_storage.get_chart_watchers()[1], "expected stale watcher to be pruned")
        assert.falsy(emof_storage.get_chart_watchers()[2])
      end)
    end
  },
  {
    name = "sync_tracking mirrors panel open state",
    run = function()
      test_env.with_factorio_stubs(function()
        local chart_watchers = require("scripts.map.chart_watchers")
        local emof_storage = require("scripts.emof_storage")

        emof_storage.ensure_storage()
        chart_watchers.sync_tracking(3, true)
        chart_watchers.sync_tracking(4, false)

        assert.truthy(emof_storage.get_chart_watchers()[3])
        assert.falsy(emof_storage.get_chart_watchers()[4])
      end)
    end
  }
}
