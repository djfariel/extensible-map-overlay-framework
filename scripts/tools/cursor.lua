local emof_storage = require("scripts.emof_storage")

local M = {}

local function stack_matches(player, item_name)
  local stack = player.cursor_stack
  return stack and stack.valid_for_read and stack.name == item_name
end

local function apply_string_label(stack, text)
  if text and text ~= "" then
    stack.label = text
  end
end

local function request_label_translation(player, item_name, localised_label, label_color)
  if not (player and player.valid and player.request_translation) then
    return
  end

  local request_id = player.request_translation(localised_label)
  if not request_id then
    return
  end

  emof_storage.get_cursor_label_requests()[request_id] = {
    player_index = player.index,
    item_name = item_name
  }

  if label_color ~= nil then
    local stack = player.cursor_stack
    if stack and stack.valid_for_read and stack.name == item_name and stack.is_item_with_label then
      stack.label_color = label_color
    end
  end
end

function M.apply_label(stack, label_options, player, item_name)
  if not (stack and stack.valid_for_read and stack.is_item_with_label) then
    return false
  end

  if not label_options then
    return false
  end

  if label_options.label ~= nil then
    local label = label_options.label
    if type(label) == "string" then
      if label ~= "" then
        apply_string_label(stack, label)
      end
    elseif type(label) == "table" then
      request_label_translation(player, item_name, label, label_options.label_color)
    end
  end

  if label_options.label_color ~= nil and type(label_options.label) ~= "table" then
    stack.label_color = label_options.label_color
  end

  return true
end

function M.handle_string_translated(event)
  local requests = emof_storage.get_cursor_label_requests()
  local pending = requests[event.id]
  if not pending then
    return false
  end

  requests[event.id] = nil

  if not event.translated then
    return true
  end

  local player = game.get_player(pending.player_index)
  if not (player and player.valid) then
    return true
  end

  local stack = player.cursor_stack
  if stack and stack.valid_for_read and stack.name == pending.item_name and stack.is_item_with_label then
    apply_string_label(stack, event.result)
  end

  return true
end

function M.is_equipped(player, item_name)
  if not (player and player.valid and item_name) then
    return false
  end

  return stack_matches(player, item_name)
end

function M.equip(player, item_name, label_options)
  if not (player and player.valid and item_name) then
    return false
  end

  if M.is_equipped(player, item_name) then
    M.apply_label(player.cursor_stack, label_options, player, item_name)
    return true
  end

  local stack = player.cursor_stack
  if not (stack and stack.can_set_stack and stack.can_set_stack({ name = item_name, count = 1 })) then
    return false
  end

  stack.set_stack({ name = item_name, count = 1 })
  M.apply_label(stack, label_options, player, item_name)
  return M.is_equipped(player, item_name)
end

function M.clear(player, item_name)
  if M.is_equipped(player, item_name) then
    player.clear_cursor()
  end
end

return M
