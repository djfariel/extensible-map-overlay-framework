# EMOF Consumer API

Runnable reference buttons live in the companion mod **[EMOF Examples](https://mods.factorio.com/mod/emof-examples)** ([source](../emof-examples/)).

## Table of Contents

- [What It Is](#what-it-is)
- [How It Works](#how-it-works)
- [Quickstarts](#quickstarts)
  - [Overlay Toggle](#quickstart-overlay-toggle)
  - [Action Button](#quickstart-action-button)
  - [Tool: Immediate Start](#quickstart-tool-immediate-start)
  - [Tool: Setup Dialog](#quickstart-tool-setup-dialog)
  - [Extension Slot](#quickstart-extension-slot)
- [Comprehensive Details](#comprehensive-details)
  - [Overlay Toggle](#details-overlay-toggle)
  - [Action Buttons](#details-action-buttons)
  - [Tools](#details-tools)
  - [Tool Setup Dialog](#details-tool-setup-dialog)
  - [Extension Slot](#details-extension-slot)
- [Potential Mistakes](#potential-mistakes)
- [EMOF Events](#emof-events)
- [EMOF Errors](#emof-errors)

## What It Is

**Extensible Map Overlay Framework (EMOF)** extends Factorio's Chart Controls panel so mods can add overlay toggles, action buttons, and map-placement tools without reimplementing panel layout or cursor management.

As a consumer mod you:

1. Declare **mod-data** prototypes (or call remote registration) for buttons and overlays.
2. Subscribe to **custom events** for button clicks and extension overlay toggles.
3. Optionally register **map tools** via remote API for cursor-based chart interaction.

Add `extensible-map-overlay-framework` to your mod dependencies.

## How It Works

EMOF splits integration across two stages:

| Stage | What you do | EMOF handles |
|---|---|---|
| **Data** (`data.lua`) | Declare `emof.map-overlay-toggle` and `emof.map-action-button` mod-data prototypes; build cursor items with `emof-cursor-item` | Loads specs into the registry |
| **Control** (`control.lua`) | Subscribe to custom events; call `register_map_tool` / `register_action_button` / `unregister` | Panel rendering, toggle state, cursor equip/cancel, tool dispatch |

**Clicks and extension toggles** dispatch through custom events (`emof-on-map-action-clicked`, `emof-on-map-overlay-toggled`). Do not put `on_click` or `on_toggle` in registration specs.

**Map tools** use remote callbacks (`on_click`, `on_cancel`, optional `setup.*`) because click handlers return `"continue"` or `"done"`. Link an action button with `tool_id` and `tool_start` to let EMOF start and cancel the tool from the panel toggle.

**Id namespaces** are separate per kind: the same string may be an overlay id, action id, and tool id without conflict. Within one kind, ids must be unique across mods.

**Overlay buttons** come in two kinds (see [Details: Overlay Toggle](#details-overlay-toggle)): extension toggles owned by your mod, and vanilla Chart Controls layers re-hosted by EMOF.

## Quickstarts

Minimal end-to-end paths. See [Comprehensive Details](#comprehensive-details) for behaviour edge cases.

### Quickstart: Overlay Toggle

**Data stage** - prototype `name` is the global button id and the `id` field in event payloads:

```lua
data:extend({
  {
    type = "mod-data",
    name = "my-mod-route-overlay",
    data_type = "emof.map-overlay-toggle",
    order = "a[my-mod]-b",
    localised_name = {"my-mod.overlay-caption"},
    localised_description = {"my-mod.overlay-tooltip"},
    data = {
      sprite = "utility/map"
    }
  }
})
```

**Control stage** - subscribe once and filter on `e.id`:

```lua
script.on_event("emof-on-map-overlay-toggled", function(e)
  if e.id ~= "my-mod-route-overlay" then return end
  if e.enabled then
    -- overlay turned on
  end
end)
```

Extension toggles default to off until clicked. Optionally seed state with `set_player_toggle` in `on_player_created` / `on_configuration_changed`.

### Quickstart: Action Button

Use for shortcut actions that do **not** equip a cursor tool - omit `tool_id` from the prototype. Clicks dispatch through `emof-on-map-action-clicked` and your handler runs the action (open a panel, toggle a mode, undo, etc.). To equip a map tool from Chart Controls, use [Tool (Immediate Start)](#quickstart-tool-immediate-start) or [Tool (Setup Dialog)](#quickstart-tool-setup-dialog) instead.

**Data stage:**

```lua
data:extend({
  {
    type = "mod-data",
    name = "my-mod-show-routes",
    data_type = "emof.map-action-button",
    order = "a[my-mod]-a",
    localised_name = {"my-mod.action-caption"},
    localised_description = {"my-mod.action-tooltip"},
    data = {
      size = "half", -- "half" or "full"
      sprite = "utility/map",
      visible_when = {
        surfaces = {"nauvis"},
        remote_view_only = true
      }
    }
  }
})
```

**Control stage:**

```lua
script.on_event("emof-on-map-action-clicked", function(e)
  if e.id ~= "my-mod-show-routes" then return end
  -- handle click
end)
```

### Quickstart: Tool (Immediate Start)

Use when the player should equip the cursor tool on the first button click (no pre-placement dialog).

**1. Cursor item** (`data.lua`):

```lua
local emof_cursor_item = require("__extensible-map-overlay-framework__/prototypes/emof-cursor-item")

data:extend({
  emof_cursor_item.build({
    name = "my-mod-map-tool",
    localised_name = {"item-name.my-mod-map-tool"},
    icon = "__my-mod__/graphics/map-tool.png",
    icon_size = 64,
    order = "a[my-mod]-a[map-tool]"
  })
})
```

**2. Remote interface and map tool** (`control.lua` - register the interface before `register_map_tool`; run tool registration from `on_init` and `on_configuration_changed`, wrapped in `pcall`):

```lua
remote.add_interface("my_mod_api", {
  on_tool_click = function(payload)
    return "continue" -- or "done" to end the tool after this click
  end,
  on_tool_cancel = function(payload) end -- optional; prefer emof-on-tool-state-changed for UI teardown
})

remote.call("extensible_map_overlay_framework", "register_map_tool", {
  id = "my-tool-id",
  owning_mod = "my-mod",
  cursor_item = "my-mod-map-tool",
  cursor_label = "My Tool",
  on_click = {
    interface = "my_mod_api",
    function_name = "on_tool_click"
  },
  on_cancel = {
    interface = "my_mod_api",
    function_name = "on_tool_cancel"
  }
})
```

**3. Linked action button** (`data.lua`) - action button `name` is the click event id; `tool_id` links to the map tool registered above:

```lua
data:extend({
  {
    type = "mod-data",
    name = "my-mod-tool-action",
    data_type = "emof.map-action-button",
    order = "a[my-mod]-c",
    localised_name = {"my-mod.tool-action-caption"},
    localised_description = {"my-mod.tool-action-tooltip"},
    data = {
      size = "half",
      sprite = "utility/map",
      tool_id = "my-tool-id",
      tool_start = "immediate"
    }
  }
})
```

**4. Tool state handler** (`control.lua`) - tear down tool UI when the tool ends by any path:

```lua
script.on_event("emof-on-tool-state-changed", function(e)
  if e.cancelled_tool_id == "my-tool-id" then
    -- destroy extension-slot UI, clear mod state, etc.
  end
end)
```

EMOF equips the cursor on click, raises `emof-on-map-action-clicked` (`event.id` = `"my-mod-tool-action"`) for activate-side logic, and cancels on toggle-off. Your remote `on_tool_click` handler returns `"continue"` or `"done"`.

### Quickstart: Tool (Setup Dialog)

Use when the player must configure something before the cursor activates (icon picker, text field, mode selection). Built-in tag placement is the reference implementation.

**1. Cursor item** (`data.lua`) - same as [Immediate Start](#quickstart-tool-immediate-start) step 1.

**2. Remote interface and map tool** (`control.lua`) - add `setup` handlers to the same `my_mod_api` interface, then pass a `setup` block inside the `register_map_tool` spec (sibling to `on_click` / `on_cancel`):

```lua
remote.add_interface("my_mod_api", {
  on_tool_click = function(payload)
    return "done"
  end,
  on_tool_cancel = function(payload) end,
  open_tool_setup = function(payload)
    local player = game.get_player(payload.player_index)
    -- show your dialog or extension-slot UI
  end,
  cancel_tool_setup = function(payload)
    local player = game.get_player(payload.player_index)
    -- destroy setup UI
  end,
  is_tool_setup_open = function(payload)
    -- return true while setup UI is visible
    return false
  end
})

remote.call("extensible_map_overlay_framework", "register_map_tool", {
  id = "my-tool-id",
  owning_mod = "my-mod",
  cursor_item = "my-mod-map-tool",
  cursor_label = "My Tool",
  on_click = {
    interface = "my_mod_api",
    function_name = "on_tool_click"
  },
  on_cancel = {
    interface = "my_mod_api",
    function_name = "on_tool_cancel"
  },
  setup = {
    open = {
      interface = "my_mod_api",
      function_name = "open_tool_setup"
    },
    cancel = {
      interface = "my_mod_api",
      function_name = "cancel_tool_setup"
    },
    is_open = {
      interface = "my_mod_api",
      function_name = "is_tool_setup_open"
    }
  }
})
```

`setup.open` and `setup.cancel` are required when using `tool_start = "setup"` on the linked action button; `setup.is_open` is optional but recommended because EMOF uses it to show the button as pressed while setup is open, cancel setup on a second click, and tear down your dialog when the player switches tools.

**3. Linked action button** (`data.lua`):

```lua
data:extend({
  {
    type = "mod-data",
    name = "my-mod-tool-action",
    data_type = "emof.map-action-button",
    order = "a[my-mod]-c",
    localised_name = {"my-mod.tool-action-caption"},
    localised_description = {"my-mod.tool-action-tooltip"},
    data = {
      size = "half",
      sprite = "utility/map",
      tool_id = "my-tool-id",
      tool_start = "setup"
    }
  }
})
```

**4. On confirm**, call `start_map_tool` with session data:

```lua
remote.call("extensible_map_overlay_framework", "start_map_tool", player.index, "my-tool-id", {
  cursor_label = "Confirmed label",
  -- arbitrary fields passed through to on_click as payload.data
})
```

Wire `on_gui_click` (and related GUI events) in your mod for your dialog elements. EMOF does not route GUI events for consumer setup dialogs.

### Quickstart: Extension Slot

Add tool UI inside the Chart Controls panel so it moves with the panel without manual re-anchoring:

```lua
local PANEL_NAME = "emof_map_panel"
local SLOT_NAME = "emof_extension_slot"

local function get_extension_slot(player)
  local panel = player.gui.screen[PANEL_NAME]
  if not (panel and panel.valid) then
    return nil
  end

  local slot = panel[SLOT_NAME]
  if slot and slot.valid then
    return slot
  end

  return nil
end

-- When your map tool opens:
local slot = get_extension_slot(player)
if slot then
  slot.visible = true
  local toolbar = slot.add({
    type = "flow",
    name = "my-mod-toolbar",
    direction = "vertical"
  })
  -- add buttons directly to toolbar...
end

-- When your map tool closes:
local slot = get_extension_slot(player)
if slot then
  local toolbar = slot.my_mod_toolbar
  if toolbar then
    toolbar.destroy()
  end
  slot.visible = #slot.children > 0
end
```

EMOF never clears `emof_extension_slot`; consumers own the children they add. Be considerate to players and other modders - destroy your GUI when your tool or setup flow ends so the slot stays usable.

## Comprehensive Details

### Details: Overlay Toggle

Chart Controls shows two kinds of overlay toggle:

| Kind | Examples | State stored in | `emof-on-map-overlay-toggled` |
|---|---|---|---|
| **Extension** | Your mod-data prototype name | `storage` via `extension_toggles` | **Yes** - `event.id` is your prototype name |
| **Vanilla** | `show-pollution`, `show-logistic-network`, train names, … | `player.map_view_settings` + EMOF `vanilla_toggles` mirror | **No** |

Extension toggles default to off until clicked. Vanilla layers use Factorio defaults (mostly on) and write directly to map view settings.

If your mod must react to vanilla layer visibility, read `player.map_view_settings["show-pollution"]` (etc.) when your logic runs - do not wait for `emof-on-map-overlay-toggled`. Likewise, `set_player_toggle` / `get_player_toggle` apply to extension ids only.

#### Pollution button

`show-pollution` is a vanilla overlay with `dynamic_pollutant = true`. Unlike fixed vanilla layers:

- **Caption, sprite, and tooltip** are resolved at runtime from the active pollutant display (via EMOF's pollutant cache). The button reflects whichever pollutant type is relevant for the current chart context.
- **Visibility** - the pollution toggle appears only when a pollutant display resolves for the player. If no pollutant applies, the button is omitted from the overlay drawer.
- **State** - toggling updates `player.map_view_settings["show-pollution"]` and EMOF's `vanilla_toggles` mirror. No `emof-on-map-overlay-toggled` event fires.

The pollutant display cache is module-local and is empty after save load until rebuilt; it is also cleared on `on_player_left_game`.

#### set/get toggle

- `set_player_toggle(player_index, name, value)` updates an extension toggle state without raising the overlay event
- `get_player_toggle(player_index, id)` returns the stored boolean, or `nil` if the player has never toggled that overlay

Extension toggles default to **off** in the Chart Controls panel when unset. In Lua, `nil` is falsy, so `if not remote.call(..., "get_player_toggle", ...)` treats unset the same as explicitly off - which matches the UI - but the distinction matters if your mod cares whether the player has ever chosen a state.

**Recommended checks:**

```lua
-- Enabled (explicit on only)
if remote.call("extensible_map_overlay_framework", "get_player_toggle", player.index, overlay_id) == true then
  -- overlay is on
end

-- Disabled or unset (matches default-off UI)
if remote.call("extensible_map_overlay_framework", "get_player_toggle", player.index, overlay_id) ~= true then
  -- overlay is off or never toggled
end
```

Use `set_player_toggle` in `on_player_created` / `on_configuration_changed` when your mod needs opt-in defaults other than off.

Do **not** rely on truthiness alone (`if get_player_toggle(...) then`) unless you intentionally treat only explicit `true` as on - that works, but `== true` makes the contract obvious to readers.

#### Visibility

Visibility is set by the **mod author** in mod-data, not by players. Omit `visible_when` entirely to show the overlay or action button on any chart surface and in any controller mode (the default). Add restrictions only when it should not appear everywhere:

```lua
visible_when = {
  surfaces = {"nauvis"},   -- omit surfaces to allow any surface
  remote_view_only = true  -- omit or set false to allow non-remote view too
}
```

EMOF evaluates this when rendering Chart Controls; there is no in-game player setting for it.

### Details: Action Buttons

#### Sizes and event-only buttons

`size` is `"half"` or `"full"`. Event-only actions omit `tool_id` and behave as plain shortcut buttons - no cursor tool is equipped and EMOF does not manage a pressed/toggled state for a tool. Handle the click in `emof-on-map-action-clicked` and run your mod logic there.

#### Tool-linked action (toggle button)

Link an action button to a registered map tool. The button stays pressed while the tool is active; click again to cancel. Inside a mod-data prototype's `data` table:

```lua
data = {
  size = "half",
  tool_id = "my-tool-id",      -- id passed to register_map_tool
  tool_start = "immediate"     -- or "setup" to open a registered setup dialog first
}
```

With `tool_start = "immediate"`, the first click equips the cursor, shows the button as pressed, and raises `emof-on-map-action-clicked` so you can run activate-side logic (e.g. open extension-slot UI). A second click cancels the tool and clears the cursor. EMOF handles equip and cancel for you - do not call `start_map_tool` or `cancel_map_tool` from that action-clicked handler.

With `tool_start = "setup"`, the first click opens your tool's setup dialog instead of equipping the cursor. The button stays pressed while setup is open (when you register `setup.is_open`) or while the tool is active. Click again to cancel setup or the tool. See [Details: Tool Setup Dialog](#details-tool-setup-dialog).

#### Dynamic button metadata (remote)

For buttons that cannot be declared in the data stage, register UI metadata at runtime. No callback fields are accepted; clicks still dispatch via custom events.

```lua
remote.call("extensible_map_overlay_framework", "register_action_button", {
  id = "my-dynamic-action",
  owning_mod = "my-mod",
  order = "a-010",
  size = "half",
  caption = {"my-mod.action-caption"},
  tooltip = {"my-mod.action-tooltip"},
  tool_id = "my-tool-id",
  tool_start = "immediate"
})
```

Register from `on_init` and `on_configuration_changed`. List EMOF as a dependency so your registration runs after EMOF reloads its registry.

Built-in ping and tag tools use this same path: `register_map_tool` in bootstrap, click handling via `emof_builtin_map_tools`, and `start_map_tool` / `cancel_map_tool` at runtime. The built-in tag button uses `tool_start = "setup"` and registers setup callbacks on the tag tool; its confirm dialog calls `start_map_tool` after the player confirms.

#### Action button enabled state

Grey out action buttons when your mod state makes them unavailable (undo/redo, gated actions, etc.). Register an optional remote callback inside the mod-data `data` table:

```lua
data = {
  size = "half",
  sprite = "utility/undo",
  enabled = {
    interface = "my_mod_actions",
    function_name = "is_undo_enabled"
  }
}
```

Callback payload: `player_index`, `id` (action button prototype name). Return `true` when clickable, `false` when disabled. When the callback is missing or errors, EMOF defaults to **disabled** (fail closed).

After your mod changes eligibility (undo stack push/pop, etc.), call:

```lua
remote.call("extensible_map_overlay_framework", "sync_chart_controls", player.index)
```

This re-syncs action button `enabled` and `toggled` states for the open Chart Controls panel. Safe to call after undo/redo or other eligibility changes; if the player is invalid, disconnected, or not viewing the chart with the panel open, the call is a silent no-op (never raises).

#### Visibility

Action button specs support the same `visible_when` block as overlays (see [Visibility](#visibility) under overlay details).

### Details: Tools

#### Cursor item (data stage)

Map tools need a cursor-only item prototype. Use the EMOF builder from your mod's `data.lua`:

```lua
local emof_cursor_item = require("__extensible-map-overlay-framework__/prototypes/emof-cursor-item")

data:extend({
  emof_cursor_item.build({
    name = "my-mod-map-tool",
    localised_name = {"item-name.my-mod-map-tool"},
    icon = "__my-mod__/graphics/map-tool.png",
    icon_size = 64,
    order = "a[my-mod]-a[map-tool]"
  })
})
```

Defaults applied by `build()`:

- `type = "item-with-label"` with `draw_label_for_cursor_render = true`
- `auto_recycle = false`, `hidden = true`, `stack_size = 1`
- `flags = {"only-in-cursor", "not-stackable", "spawnable"}`
- `subgroup = "tool"`

Optional fields: `default_label_color`, `subgroup`, `stack_size`, `draw_label_for_cursor_render` (defaults to `true`).

#### Map tool spec (remote)

Map tools use the remote API because click handlers can return `"done"` or `"continue"`:

```lua
remote.call("extensible_map_overlay_framework", "register_map_tool", {
  id = "my-tool-id",
  owning_mod = "my-mod",
  cursor_item = "my-mod-map-tool",
  cursor_label = "My Tool",
  on_click = {
    interface = "my_mod_api",
    function_name = "on_tool_click"
  },
  on_cancel = {
    interface = "my_mod_api",
    function_name = "on_tool_cancel"
  },
  setup = {
    open = {
      interface = "my_mod_api",
      function_name = "open_tool_setup"
    },
    cancel = {
      interface = "my_mod_api",
      function_name = "cancel_tool_setup"
    },
    is_open = {
      interface = "my_mod_api",
      function_name = "is_tool_setup_open"
    }
  }
})
```

The optional `setup` block registers a pre-placement dialog flow. Required when an action button uses `tool_start = "setup"`:

- **`setup.open`** - EMOF calls this when the player clicks the linked action button. Show your dialog or extension-slot UI here. EMOF cancels any active map tool before calling `open`.
- **`setup.cancel`** - Called when the player toggles the action off, starts another immediate tool, disconnects, or EMOF otherwise needs to tear down setup.
- **`setup.is_open`** (optional but recommended) - Return `true` while your setup UI is visible; EMOF uses this to show the action button as pressed, cancel setup on toggle-off, and auto-close your dialog when the player switches tools.

#### Programmatic start and cancel

Call `start_map_tool` / `cancel_map_tool` when your mod equips or ends a cursor tool **outside** EMOF's tool-linked button toggle - for example after a setup dialog confirms, from extension-slot UI, or from another custom entry point:

```lua
remote.call("extensible_map_overlay_framework", "start_map_tool", player_index, "my-tool-id", {
  cursor_label = "Dynamic label for this session"
})
remote.call("extensible_map_overlay_framework", "cancel_map_tool", player_index, "done")
```

For Chart Controls buttons, prefer linking `tool_id` with `tool_start` so EMOF handles equip, cancel, and pressed state. When a button declares `tool_id`, do not call `start_map_tool` again from `emof-on-map-action-clicked` - use that event for activate-side logic only.

#### Map tool callback contract

- Map tool click payload: `player_index`, `surface_index`, `id`, `cursor_position`, `tick`, `selected_entity` (optional `{ unit_number, surface_index }`), `data`
- Map tool cancel payload: `player_index`, `surface_index`, `id`, `reason`, `data`
- Tool setup callbacks payload: `player_index` only; `setup.is_open` should return boolean
- Click handler must return `"continue"` to keep the tool active, or `"done"` to end it
- Invalid clicks (no cursor position or chart surface) are ignored; the tool stays active

Per-session `data.cursor_label` overrides the registered default. Optional `cursor_label_color` uses the same `{r, g, b}` or `{r, g, b, a}` table as other Factorio color fields. `cursor_label` may be a plain string or a Factorio localised string table (for example `{ "item-name.emof-ping-tool" }`); EMOF resolves localised values to the player's locale when applying the cursor label.

#### Tool cancel contract

EMOF clears the active tool and cursor **before** invoking your remote `on_cancel` handler. If `on_cancel` errors, the tool remains off and `emof-on-tool-state-changed` still fires with `cancelled_tool_id` set. Use that event (not only `on_cancel`) to tear down extension UI reliably.

Setup dialogs follow the same rule: closing setup invokes your `setup.cancel` callback (use this for setup UI teardown). EMOF also raises `emof-on-tool-state-changed` and `action_state_changed` so the toolbar button unpresses.

#### Save load and module state

EMOF keeps registration metadata in **`storage`** (overlay/action/tool specs, per-player toggles, active tools). Some runtime structures are **module-local** and are empty after a save load until rebuilt:

| Module-local state | Rebuilt on save load |
|---|---|
| `tool_state.registered_specs` (click/cancel dispatch) | `bootstrap.on_load` → `callbacks.rebuild_registered_tools()` |
| Map-tool custom input handler registration flags | `bootstrap.on_load` → `tool_state.sync_input_handlers()` |
| `pollutant_display` per-tick cache | Empty after reload; also cleared on `on_player_left_game` |

`on_configuration_changed` runs a full registry reload (`mod_data_loader.load_all`, tool prune, etc.) and does not rely on `on_load`.

If you add new module-level mutable state to EMOF, either keep it derivable from `storage` or hook it into `bootstrap.on_load`.

### Details: Tool Setup Dialog

Use this when the player must configure something before the cursor tool activates.

1. Register the map tool with `setup.open`, `setup.cancel`, and preferably `setup.is_open` (so EMOF can track open setup for button state, toggle-cancel, and auto-teardown).
2. Declare the action button with `tool_id` and `tool_start = "setup"`.
3. Build GUI in your mod (floating frame, or the [extension slot](#details-extension-slot)).
4. Wire `script.on_event(defines.events.on_gui_click, ...)` (and related GUI events) in your mod for your element names.
5. On confirm, call `start_map_tool`; on cancel, destroy your GUI (EMOF also calls `setup.cancel` when appropriate).

EMOF does not route GUI events for consumer setup dialogs - only the remote setup callbacks for toolbar lifecycle.

Your mod owns all GUI elements and `on_gui_*` handlers. On confirm, call `start_map_tool` with any session data the click handler needs:

```lua
remote.call("extensible_map_overlay_framework", "start_map_tool", player.index, "my-tool-id", {
  cursor_label = "Confirmed label",
  -- arbitrary fields passed through to on_click as payload.data
})
```

### Details: Extension Slot

When the Chart Controls panel is open, EMOF reserves a child frame named `emof_extension_slot` at the bottom of `emof_map_panel`. It uses the same `deep_frame_in_shallow_frame` inset style as the action-button region. Add your tool UI there so it moves with the panel without manual re-anchoring or adding another inset.

The slot starts hidden and stays hidden until a consumer sets `visible = true` or adds children.

Remote helpers return the stable element names:

- `get_map_panel_name()` -> `"emof_map_panel"`
- `get_extension_slot_name()` -> `"emof_extension_slot"`

See [Quickstart: Extension Slot](#quickstart-extension-slot) for the open/close pattern.

## Potential Mistakes

1. **Registration during reload** - `register_*` and `unregister` raise on bad input. Fix bad specs before release; during development, wrap registration in `pcall` (or use `try_register_map_tool`) so one failed call does not abort the rest of your `on_init` / `on_configuration_changed` handler.
2. **Overlay toggle event** - `emof-on-map-overlay-toggled` fires for **extension** overlays only (your mod-data / `register_overlay_toggle` ids). Vanilla Chart Controls layers (`show-pollution`, logistics, etc.) update `player.map_view_settings` and do **not** raise this event.
3. **Toggle state** - `get_player_toggle` returns `nil` until set. Use `== true` for on, `~= true` for off or unset (see [set/get toggle](#setget-toggle)).
4. **Tool UI teardown** - subscribe to `emof-on-tool-state-changed` with `cancelled_tool_id` for map-tool UI; use `setup.cancel` for setup-dialog UI. Do not rely on `on_cancel` alone (errors are logged, tool still ends; `"done"` clicks skip `on_cancel` entirely).

## EMOF Events

Subscribe once from `control.lua` (or a module required by it). `event.name` is always the numeric custom-event type id assigned by Factorio. Filter on `event.id` for the button or overlay prototype name.

### `emof-on-map-action-clicked`

Raised when the player clicks an action button (including after EMOF starts an immediate tool).

```lua
script.on_event("emof-on-map-action-clicked", function(e)
  if e.id ~= "my-mod-show-routes" then return end
  -- handle click
end)

-- Payload {
--   player_index: number,
--   id: string,
--   surface_index?: number
-- }
```

### `emof-on-map-overlay-toggled`

Raised for **extension** overlay toggles only. Vanilla Chart Controls layers (pollution, logistics, …) do not raise this event.

```lua
script.on_event("emof-on-map-overlay-toggled", function(e)
  if e.id ~= "my-mod-route-overlay" then return end
  if e.enabled then
    -- overlay turned on
  end
end)

-- Payload {
--   player_index: number,
--   id: string,
--   enabled: boolean,
--   surface_index?: number
-- }
```

### `emof-on-tool-state-changed`

Raised whenever the active map tool changes, including when a tool is cancelled by any path (toolbar toggle, Esc, cursor clear, panel close, unregister, disconnect, etc.).

```lua
script.on_event("emof-on-tool-state-changed", function(e)
  if e.cancelled_tool_id == "my-tool-id" then
    -- tool ended
  end
end)

-- Payload {
--   player_index: number,
--   active_tool_id: string | nil,
--   cancelled_tool_id?: string,
--   reason?: string
-- }
```

`remote.call("extensible_map_overlay_framework", "get_tool_state_changed_event")` returns the stable prototype name (`"emof-on-tool-state-changed"`).

## EMOF Errors

Interface name: `extensible_map_overlay_framework`.

**Quick rule:** wrap **`register_*`**, **`unregister`**, and **`set_player_toggle` / `get_player_toggle`** in `pcall` during bootstrap/reload. Runtime **`start_map_tool`** may raise on programmer error (unknown tool id); **`cancel_map_tool`** and **`sync_chart_controls`** never raise. Prefer **`try_register_map_tool`** when registration failure should not abort reload.

### Failure styles

EMOF uses three failure styles:

- **`error(...)`** - invalid arguments, unknown ids, duplicate names, or mod incompatibilities. Wrap in `pcall` during `on_init` / `on_configuration_changed` so a bad registration does not abort your handler mid-reload.
- **Return `false`** - operation could not run, but the call itself was valid (e.g. player disconnected, cursor could not be equipped, nothing to unregister).
- **Silent no-op** - valid call, nothing to do (e.g. `sync_chart_controls` when the player is invalid, disconnected, or the Chart Controls panel is not open in chart view).

### Remote API reference

| Function | On success | Returns `false` when | Raises `error` when |
|---|---|---|---|
| `register_overlay_toggle(spec)` | nothing | - | Invalid `spec`; duplicate overlay `id` (same kind, another mod owns the name) |
| `register_action_button(spec)` | nothing | - | Invalid `spec`; duplicate action `id` |
| `register_map_tool(spec)` | nothing | - | Invalid `spec` (missing `cursor_item`, bad `on_click`, bad `setup`, etc.); duplicate tool `id`; tool owner mod not active |
| `try_register_map_tool(spec)` | `{ ok = true }` or `{ ok = false, error = "..." }` | - | Never raises; use for bootstrap registration that should not abort reload |
| `sync_chart_controls(player_index)` | nothing | - | - |
| `get_tool_state_changed_event()` | string | - | - |
| `unregister(mod_name, id, kind)` | `true` / `false` | Name unknown for that kind, or `mod_name` does not own the entry | `mod_name`, `id`, or `kind` missing / invalid |
| `set_player_toggle(player_index, id, value)` | boolean (`value`) | - | `value` not boolean; unknown overlay `id`; invalid `player_index` |
| `get_player_toggle(player_index, id)` | boolean or `nil` | - | Invalid `player_index` |
| `start_map_tool(player_index, id, data?)` | boolean | Player invalid / disconnected; cursor item could not be equipped | Unknown tool `id`; tool owner mod not active |
| `cancel_map_tool(player_index, reason?)` | boolean | Player invalid / disconnected; no active tool for that player | - |
| `get_map_panel_name()` | string | - | - |
| `get_extension_slot_name()` | string | - | - |

**`start_map_tool` vs `cancel_map_tool`:** only `start_map_tool` hard-errors on bad tool ids. `cancel_map_tool` always fails softly (`false`) when there is nothing to cancel.

**`sync_chart_controls`:** never raises and never returns a value. Invalid or disconnected players, a closed panel, or a player not in chart view all no-op silently.

**`unregister` vs registration calls:** bad arguments to `unregister` error; a name that simply is not registered returns `false` (safe to call while clearing stale entries before re-registering).

### Recommended reload pattern

```lua
local EMOF = "extensible_map_overlay_framework"

local function emof_call(function_name, ...)
  local ok, result = pcall(remote.call, EMOF, function_name, ...)
  if not ok then
    log("[my-mod] EMOF " .. function_name .. " failed: " .. tostring(result))
    return nil
  end
  return result
end

script.on_configuration_changed(function()
  emof_call("unregister", "my-mod", "my-tool-id", "tool")
  emof_call("register_map_tool", {
    id = "my-tool-id",
    owning_mod = "my-mod",
    cursor_item = "my-mod-map-tool",
    on_click = { interface = "my_mod_api", function_name = "on_tool_click" }
  })
end)
```

Runtime calls (e.g. `start_map_tool` after a setup dialog confirms) can usually skip `pcall` once registration has succeeded - an error there indicates a logic bug worth surfacing during development.

### unregister

Call `unregister(mod_name, name, kind)` to remove a runtime registration you added earlier.
`kind` is one of `"overlay"`, `"action"`, or `"tool"` and must match how the entry was registered.
`mod_name` must match the `owning_mod` used when the entry was registered; other mods cannot remove it.
Returns `true` when an owned entry of that kind was removed, `false` when the name is unknown for that kind or owned by another mod.
Useful for clearing dynamic registrations before re-registering on `on_configuration_changed`.

Because overlay, action, and tool ids are namespaced separately, the same string may be registered in more than one kind; pass the matching `kind` for the entry you intend to remove.

### Duplicate names

Overlay toggles, action buttons, and map tools each have their own id namespace. The same string may be used as an overlay id, action id, and tool id without conflict.

Within one kind, ids must be unique across mods. If another mod claims an existing name in that kind, EMOF raises a hard incompatibility error with both owners.

### What not to do

- Do not require internal `scripts/api/*` modules from EMOF.
- Do not mutate EMOF storage directly.
- Do not reuse names owned by other mods within the same registration kind (overlay, action, or tool).
- Do not put `on_click` or `on_toggle` in button registration specs; use events instead.
