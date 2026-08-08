local M = {}

---@class rules_nvim_lua.TestSuiteExample
---@field description string
---@field test function
M.TestSuiteExample = {}
M.TestSuiteExample.__index = M.TestSuiteExample

function M.TestSuiteExample.new(description, test)
  local o = setmetatable({}, M.TestSuiteExample)
  o.description = description
  o.test = test
  return o
end

---@class rules_nvim_lua.TestSuite
---@field description string
---@field examples (rules_nvim_lua.TestSuiteExample|rules_nvim_lua.TestSuite)[]
M.TestSuite = {}
M.TestSuite.__index = M.TestSuite

function M.TestSuite.new(description, examples)
  local o = setmetatable({}, M.TestSuite)
  o.description = description
  o.examples = examples or {}
  return o
end

--- Top-level test suites
---@type rules_nvim_lua.TestSuite[]
M.top_level_test_suites = {}

---@type rules_nvim_lua.TestSuite[]
M.test_suite_stack = {}

---@return rules_nvim_lua.TestSuite|nil
local function get_current_test_suite()
  return M.test_suite_stack[#M.test_suite_stack]
end

---@param description string
---@param set_up_suite function
function M.describe(description, set_up_suite)
  table.insert(M.test_suite_stack, M.TestSuite.new(description, {}))
  set_up_suite()
  local test_suite = table.remove(M.test_suite_stack)

  local parent_test_suite = get_current_test_suite()
  if parent_test_suite ~= nil then
    table.insert(parent_test_suite.examples, test_suite)
  else
    table.insert(M.top_level_test_suites, test_suite)
  end
end

function M.it(description, test_fn)
  local test_example = M.TestSuiteExample.new(description, test_fn)
  local parent_test_suite = get_current_test_suite()
  if parent_test_suite ~= nil then
    table.insert(parent_test_suite.examples, test_example)
  else
    error('it must be called within a describe callback')
  end
end

return M
