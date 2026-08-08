--- Default runner

---@type string[]
local spec_files = arg

local test_suite = require('rules_nvim_lua.test.test_suite')

local function get_env()
  local env = {
    describe = test_suite.describe,
    it = test_suite.it,
    assert = require('rules_nvim_lua.test.test_suite.assert'),
  }
  return setmetatable(env, { __index = _G })
end

for _, file in ipairs(spec_files) do
  local set_up_spec = assert(loadfile(file))
  setfenv(set_up_spec, get_env())
  set_up_spec()
end

local INDENT_PER_LEVEL = 2

---@param example_or_suite rules_nvim_lua.TestSuite|rules_nvim_lua.TestSuiteExample
---@param level number
local function get_description(example_or_suite, level)
  ---@type string
  local marker
  if getmetatable(example_or_suite) == test_suite.TestSuite then
    marker = '+'
  elseif getmetatable(example_or_suite) == test_suite.TestSuiteExample then
    marker = '-'
  end
  return string.rep(' ', level * INDENT_PER_LEVEL) .. marker .. ' ' .. example_or_suite.description
end

---@param test rules_nvim_lua.TestSuite
---@return rules_nvim_lua.TestStats
local function run_test_suite(test, level)
  local TestStats = require('rules_nvim_lua.test.test_suite.test_stats')

  ---@type rules_nvim_lua.TestStats
  local test_stats = TestStats.new()

  local AssertionError = require('rules_nvim_lua.test.test_suite.assertion_error')
  vim.print(get_description(test, level))
  for _, example in ipairs(test.examples) do
    if getmetatable(example) == test_suite.TestSuite then
      run_test_suite(example, level + 1)
    elseif getmetatable(example) == test_suite.TestSuiteExample then
      vim.print(get_description(example, level + 1))
      local result = xpcall(example.test, function(error)
        ---@type string
        local message
        if getmetatable(error) == AssertionError then
          message = error.message
        else
          message = string.format('Unknown error: %s', tostring(error))
        end
        vim.print(string.format('FAILURE:\n%s', message))
      end)
      if result then
        test_stats:inc_successes()
      else
        test_stats:inc_failures()
      end
    end
  end

  return test_stats
end

local TestStats = require('rules_nvim_lua.test.test_suite.test_stats')
local total_stats = vim
  .iter(test_suite.top_level_test_suites)
  :fold(TestStats.new(), function(acc_test_stats, test)
    local test_stats = run_test_suite(test, 0)
    return acc_test_stats:add(test_stats)
  end)

vim.print(
  string.format(
    '\n %d successes / %d failures / %d errors',
    total_stats.successes,
    total_stats.failures,
    total_stats.errors
  )
)

if total_stats.failures > 0 or total_stats.errors > 0 then
  os.exit(1)
end
