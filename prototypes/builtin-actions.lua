data:extend({
  {
    type = "mod-data",
    name = "emof-add-tag",
    data_type = "emof.map-action-button",
    order = "0000",
    localised_name = { "gui-map-view-settings.add-tag" },
    localised_description = { "gui-map-view-settings.add-tag" },
    data = {
      owning_mod = "extensible-map-overlay-framework",
      size = "half",
      tool_id = "tag",
      tool_start = "setup"
    }
  },
  {
    type = "mod-data",
    name = "emof-add-ping",
    data_type = "emof.map-action-button",
    order = "0001",
    localised_name = { "gui-map-view-settings.add-ping" },
    localised_description = { "gui-map-view-settings.add-ping-tooltip", { "emof-framework.control-place-ping" } },
    data = {
      owning_mod = "extensible-map-overlay-framework",
      size = "half",
      tool_id = "ping",
      tool_start = "immediate"
    }
  }
})
