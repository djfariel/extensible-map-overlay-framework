local assert = require("scripts.test.assert")
local emof_cursor_item = require("prototypes.emof-cursor-item")

return {
  {
    name = "emof_cursor_item.build applies EMOF defaults",
    run = function()
      local item = emof_cursor_item.build({
        name = "test-cursor-item",
        icon = "__test__/icon.png",
        order = "a[test]"
      })

      assert.equals(item.type, "item-with-label")
      assert.equals(item.name, "test-cursor-item")
      assert.equals(item.icon, "__test__/icon.png")
      assert.equals(item.icon_size, 64)
      assert.equals(item.draw_label_for_cursor_render, true)
      assert.equals(item.auto_recycle, false)
      assert.equals(item.hidden, true)
      assert.equals(item.stack_size, 1)
      assert.equals(item.subgroup, "tool")
      assert.equals(item.order, "a[test]")
      assert.equals(#item.flags, 3)
      assert.equals(item.flags[1], "only-in-cursor")
      assert.equals(item.flags[2], "not-stackable")
      assert.equals(item.flags[3], "spawnable")
      assert.falsy(item.inventory_move_sound)
      assert.falsy(item.pick_sound)
      assert.falsy(item.drop_sound)
    end
  },
  {
    name = "emof_cursor_item.build requires name and icon",
    run = function()
      local ok_name = pcall(emof_cursor_item.build, { icon = "__test__/icon.png" })
      assert.falsy(ok_name, "Expected missing name to error")

      local ok_icon = pcall(emof_cursor_item.build, { name = "test-item" })
      assert.falsy(ok_icon, "Expected missing icon to error")
    end
  }
}
