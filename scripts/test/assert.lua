local M = {}

function M.truthy(value, message)
  if not value then
    error(message or "Expected value to be truthy")
  end
end

function M.falsy(value, message)
  if value then
    error(message or "Expected value to be falsy")
  end
end

function M.equals(actual, expected, message)
  if actual ~= expected then
    error(message or ("Expected '" .. tostring(expected) .. "' but got '" .. tostring(actual) .. "'"))
  end
end

function M.contains(haystack, needle, message)
  if type(haystack) ~= "string" or string.find(haystack, needle, 1, true) == nil then
    error(message or ("Expected string to contain '" .. tostring(needle) .. "'"))
  end
end

return M
