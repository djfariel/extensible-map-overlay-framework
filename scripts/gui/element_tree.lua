local M = {}

function M.find_descendant(element, name)
  if not (element and element.valid) then
    return nil
  end

  if element.name == name then
    return element
  end

  for _, child in pairs(element.children) do
    local found = M.find_descendant(child, name)
    if found then
      return found
    end
  end

  return nil
end

return M
