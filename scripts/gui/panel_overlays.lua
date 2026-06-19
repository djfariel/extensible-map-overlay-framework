local callbacks = require("scripts.api.callbacks")
local constants = require("scripts.constants")
local pollutant_display = require("scripts.map.pollutant_display")
local registry = require("scripts.api.registry")
local settings_writer = require("scripts.map.settings_writer")
local emof_storage = require("scripts.emof_storage")
local vanilla_overlays = require("scripts.map.vanilla_overlays")
local view_context = require("scripts.map.view_context")
local visibility = require("scripts.map.visibility")

local M = {}

local function overlay_visible(player, overlay)
  if overlay.dynamic_pollutant then
    return pollutant_display.resolve_cached(player) ~= nil
  end

  return true
end

local function each_visible_overlay(player, visit)
  for _, overlay in ipairs(vanilla_overlays.get_all()) do
    if overlay_visible(player, overlay) then
      visit("vanilla", overlay)
    end
  end

  for _, spec in ipairs(visibility.filter_visible_specs(player, registry.get_overlay_specs_sorted())) do
    visit("extension", spec)
  end
end

local function build_vanilla_entry(player, state, overlay)
  local entry = {
    id = overlay.id,
    selected = settings_writer.get_vanilla_toggle(state, overlay)
  }

  if overlay.dynamic_pollutant then
    local display = pollutant_display.resolve_cached(player)
    entry.sprite = display.sprite
    entry.tooltip = display.tooltip
    entry.caption = display.caption
    return entry, display.pollutant_name
  end

  entry.sprite = overlay.sprite
  entry.tooltip = overlay.tooltip
  entry.caption = overlay.caption
  return entry, false
end

local function collect_overlay_entries(player, state)
  local entries = {}
  local pollution_name = false

  each_visible_overlay(player, function(kind, item)
    if kind == "vanilla" then
      local entry, pollutant = build_vanilla_entry(player, state, item)
      if pollutant then
        pollution_name = pollutant
      end
      entries[#entries + 1] = entry
      return
    end

    entries[#entries + 1] = {
      id = item.id,
      caption = item.caption,
      tooltip = item.tooltip,
      sprite = item.sprite,
      selected = state.extension_toggles[item.id] == true
    }
  end)

  return entries, pollution_name
end

function M.structure_signature(player)
  local parts = {}
  each_visible_overlay(player, function(_, item)
    parts[#parts + 1] = item.id
  end)
  return table.concat(parts, "\0")
end

function M.sync_drawer(panel, player, state)
  local region = panel[constants.GUI.overlay_region]
  if not (region and region.valid) then
    return
  end

  local overlay_visible = view_context.is_overlay_drawer_visible(player)
  region.visible = overlay_visible
  state.overlay_drawer_visible = overlay_visible
  if not overlay_visible then
    return
  end

  local drawer = region[constants.GUI.overlay_drawer]
  if not (drawer and drawer.valid) then
    return
  end

  local entries, pollution_name = collect_overlay_entries(player, state)
  state.last_pollutant_name = pollution_name

  for _, entry in ipairs(entries) do
    local button = drawer[constants.GUI.toggle_button_prefix .. entry.id]
    if button and button.valid then
      button.toggled = entry.selected
      if entry.sprite then
        button.sprite = entry.sprite
      end
      if entry.tooltip then
        button.tooltip = entry.tooltip
      end
    end
  end
end

local function add_overlay_button(drawer, entry)
  local button = drawer.add({
    type = "sprite-button",
    name = constants.GUI.toggle_button_prefix .. entry.id,
    style = "slot_sized_button",
    sprite = entry.sprite or "utility/questionmark",
    tooltip = entry.tooltip or entry.caption
  })
  button.toggled = entry.selected
end

function M.render_region(panel, player, state)
  local region = panel[constants.GUI.overlay_region]
  if not (region and region.valid) then
    return
  end

  local overlay_is_visible = view_context.is_overlay_drawer_visible(player)
  state.overlay_drawer_visible = overlay_is_visible
  region.visible = overlay_is_visible
  if not overlay_is_visible then
    return
  end

  region.clear()

  local drawer = region.add({
    type = "table",
    name = constants.GUI.overlay_drawer,
    column_count = 6
  })
  drawer.style.horizontal_spacing = 0
  drawer.style.vertical_spacing = 0

  local entries, pollution_name = collect_overlay_entries(player, state)
  state.last_pollutant_name = pollution_name

  for _, entry in ipairs(entries) do
    add_overlay_button(drawer, entry)
  end

  local remaining = #entries % 6
  if remaining ~= 0 then
    for _ = 1, (6 - remaining) do
      local spacer = drawer.add({
        type = "sprite-button",
        style = "slot_sized_button"
      })
      spacer.visible = false
    end
  end
end

function M.on_toggle_clicked(player, id)
  local state = emof_storage.get_player_state(player.index)
  local vanilla = vanilla_overlays.get(id)
  if vanilla then
    -- Vanilla map layers: update player.map_view_settings only. Does not raise
    -- emof-on-map-overlay-toggled (extension overlays only; see example README).
    local enabled = not settings_writer.get_vanilla_toggle(state, vanilla)
    settings_writer.apply_vanilla_toggle(player, vanilla.map_key, enabled)
    return
  end

  local spec = registry.get_overlay(id)
  if not spec then
    return
  end

  local enabled = not (state.extension_toggles[id] == true)
  state.extension_toggles[id] = enabled
  callbacks.dispatch_overlay_toggle(player, spec, enabled)
end

return M
