local M = {}

local overlays = {
  {
    id = "show-logistic-network",
    map_key = "show-logistic-network",
    default_value = true,
    caption = { "gui-map-view-settings.show-logistic-network" },
    tooltip = { "gui-map-view-settings.show-logistic-network" },
    sprite = "utility/show_logistics_network_in_map_view"
  },
  {
    id = "show-electric-network",
    map_key = "show-electric-network",
    default_value = true,
    caption = { "gui-map-view-settings.show-electric-network" },
    tooltip = { "gui-map-view-settings.show-electric-network" },
    sprite = "utility/show_electric_network_in_map_view"
  },
  {
    id = "show-turret-range",
    map_key = "show-turret-range",
    default_value = true,
    caption = { "gui-map-view-settings.show-turret-range" },
    tooltip = { "gui-map-view-settings.show-turret-range" },
    sprite = "utility/show_turret_range_in_map_view"
  },
  {
    id = "show-pollution",
    map_key = "show-pollution",
    default_value = true,
    dynamic_pollutant = true
  },
  {
    id = "show-train-station-names",
    map_key = "show-train-station-names",
    default_value = true,
    caption = { "gui-map-view-settings.show-map-stop" },
    tooltip = { "gui-map-view-settings.show-map-stop" },
    sprite = "utility/show_train_station_names_in_map_view"
  },
  {
    id = "show-player-names",
    map_key = "show-player-names",
    default_value = true,
    caption = { "gui-map-view-settings.show-player-names" },
    tooltip = { "gui-map-view-settings.show-player-names" },
    sprite = "utility/show_player_names_in_map_view"
  },
  {
    id = "show-tags",
    map_key = "show-tags",
    default_value = true,
    caption = { "gui-map-view-settings.show-tags" },
    tooltip = { "gui-map-view-settings.show-tags" },
    sprite = "utility/show_tags_in_map_view"
  },
  {
    id = "show-worker-robots",
    map_key = "show-worker-robots",
    default_value = true,
    caption = { "gui-map-view-settings.show-worker-robots" },
    tooltip = { "gui-map-view-settings.show-worker-robots" },
    sprite = "utility/show_worker_robots_in_map_view"
  },
  {
    id = "show-rail-signal-states",
    map_key = "show-rail-signal-states",
    default_value = true,
    caption = { "gui-map-view-settings.show-rail-signal-states" },
    tooltip = { "gui-map-view-settings.show-rail-signal-states" },
    sprite = "utility/show_rail_signal_states_in_map_view"
  },
  {
    id = "show-recipe-icons",
    map_key = "show-recipe-icons",
    default_value = true,
    caption = { "gui-map-view-settings.show-recipe-icons" },
    tooltip = { "gui-map-view-settings.show-recipe-icons" },
    sprite = "utility/show_recipe_icons_in_map_view"
  },
  {
    id = "show-pipelines",
    map_key = "show-pipelines",
    default_value = true,
    caption = { "gui-map-view-settings.show-pipelines" },
    tooltip = { "gui-map-view-settings.show-pipelines" },
    sprite = "utility/show_pipelines_in_map_view"
  }
}

local overlays_by_id = {}
for _, overlay in ipairs(overlays) do
  overlays_by_id[overlay.id] = overlay
end

function M.get_all()
  return overlays
end

function M.get(id)
  return overlays_by_id[id]
end

return M
