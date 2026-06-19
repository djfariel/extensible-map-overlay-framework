local M = {}

function M.event_id(event_name)
  local proto = prototypes.custom_event[event_name]
  if not (proto and proto.valid) then
    error("Extensible Map Overlay Framework missing custom event prototype: " .. event_name)
  end
  return proto.event_id
end

return M
