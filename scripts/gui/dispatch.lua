local M = {}

local handlers = {}

function M.clear()
  handlers = {}
end

function M.register(handler)
  if type(handler) ~= "table" then
    error("Extensible Map Overlay Framework gui dispatch handler must be a table")
  end

  handlers[#handlers + 1] = handler
end

local function dispatch(method, event, player)
  for _, handler in ipairs(handlers) do
    local fn = handler[method]
    if fn then
      if player ~= nil then
        fn(event, player)
      else
        fn(event)
      end
    end
  end
end

function M.on_gui_click(event)
  dispatch("on_gui_click", event)
end

function M.on_gui_elem_changed(event, player)
  dispatch("on_gui_elem_changed", event, player)
end

function M.on_gui_text_changed(event, player)
  dispatch("on_gui_text_changed", event, player)
end

function M.on_gui_closed(event)
  dispatch("on_gui_closed", event)
end

return M
