local emof_cursor_item = require("prototypes.emof-cursor-item")

data:extend({
  emof_cursor_item.build({
    name = "emof-ping-tool",
    localised_name = { "item-name.emof-ping-tool" },
    icon = "__extensible-map-overlay-framework__/graphics/emof-ping-cursor.png",
    icon_size = 128,
    order = "e[emof]-a[ping-tool]"
  }),
  emof_cursor_item.build({
    name = "emof-tag-tool",
    localised_name = { "item-name.emof-tag-tool" },
    icon = "__extensible-map-overlay-framework__/graphics/custom-tag-in-map-view.png",
    icon_size = 64,
    order = "e[emof]-b[tag-tool]"
  })
})
