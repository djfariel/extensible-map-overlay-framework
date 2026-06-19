local M = {}

local function default_result(suite)
  return {
    suite = suite,
    passed = 0,
    failed = 0,
    failures = {}
  }
end

function M.run_modules(suite, modules)
  local result = default_result(suite)

  for _, tests in ipairs(modules) do
    for _, test_case in ipairs(tests) do
      local ok, err = pcall(test_case.run)
      if ok then
        result.passed = result.passed + 1
      else
        result.failed = result.failed + 1
        result.failures[#result.failures + 1] = {
          name = test_case.name,
          message = tostring(err)
        }
      end
    end
  end

  return result
end

return M
