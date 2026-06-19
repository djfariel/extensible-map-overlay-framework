local gui_dispatch = require("scripts.gui.dispatch")
local gui_handlers = require("scripts.builtin.tag.gui_handlers")

local M = {}

function M.register()
  gui_dispatch.clear()
  gui_dispatch.register(gui_handlers)
end

return M
