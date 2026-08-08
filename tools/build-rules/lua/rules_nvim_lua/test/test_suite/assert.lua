---@type rules_nvim_lua.GlobalAssert
local global_assert

if global_assert ~= nil then
  return global_assert
end

---@class rules_nvim_lua.Assert
---@field is_true fun(v: boolean)
---@field is_false fun(v: boolean)
---@field falsey fun(v: boolean)
---@field same fun(...)
---@field equal fun(...)

---@class rules_nvim_lua.GlobalAssert: rules_nvim_lua.Assert
---@field are rules_nvim_lua.Assert
---@field is rules_nvim_lua.Assert
---@field are_not rules_nvim_lua.Assert

---@param negate boolean
---@return rules_nvim_lua.Assert
local function make_assert(negate)
  local function get_failure_location(level)
    -- Add a level to account for this function
    local info = debug.getinfo(level + 1, 'Sl')
    return {
      source = info.source,
      line = info.currentline,
    }
  end

  ---@generic T
  ---@param expected_value T
  ---@param actual_values T[]
  ---@param check_fn fun(T, T): boolean
  ---@param failure_descriptions {failure: string, negated_failure: string}
  local function test_values_by(
    expected_value,
    actual_values,
    check_fn,
    failure_descriptions,
    level
  )
    if #actual_values == 0 then
      return
    end
    local failing_value = vim.iter(actual_values):find(function(v)
      if negate then
        return check_fn(expected_value, v)
      else
        return not check_fn(expected_value, v)
      end
    end)
    if failing_value == nil then
      return
    end
    local location = get_failure_location(level + 1)

    local description
    local expect_description
    if negate then
      description = failure_descriptions.negated_failure
      expect_description = 'Did not expect'
    else
      description = failure_descriptions.failure
      expect_description = 'Expected'
    end

    local message = string.format(
      [[%s:%d: %s 
Passed in:
(%s) %s
%s:
(%s) %s
]],
      location.source,
      location.line,
      description,
      type(failing_value),
      tostring(failing_value),
      expect_description,
      type(expected_value),
      tostring(expected_value)
    )

    local AssertionError = require('rules_nvim_lua.test.test_suite.assertion_error')
    local assertion_error = AssertionError.new({
      message = message,
      location = location,
    })
    error(assertion_error)
  end

  ---@generic T
  ---@param ... T
  local function same(...)
    local args = { ... }
    test_values_by(args[1], vim.iter(args):skip(1):totable(), vim.deep_equal, {
      failure = 'Expected objects to be the same.',
      negated_failure = 'Did not expect objects to be the same.',
    }, 2)
  end

  local function equal(...)
    local args = { ... }
    local function eq(a, b)
      return a == b
    end
    test_values_by(args[1], vim.iter(args):skip(1):totable(), eq, {
      failure = 'Expected objects to be the same.',
      negated_failure = 'Did not expect objects to be the same.',
    }, 2)
  end

  local function is_true(value)
    test_values_by(true, { value }, vim.deep_equal, {
      failure = 'Expected objects to be the same.',
      negated_failure = 'Did not expect objects to be the same.',
    }, 2)
  end

  local function is_false(value)
    test_values_by(false, { value }, vim.deep_equal, {
      failure = 'Expected objects to be the same.',
      negated_failure = 'Did not expect objects to be the same.',
    }, 2)
  end

  return {
    same = same,
    equal = equal,
    is_true = is_true,
    is_false = is_false,
  }
end

local _assert = make_assert(false)
local _negated_assert = make_assert(true)

global_assert = {
  assert = _assert,
  is = _assert,
  are = _assert,
  is_not = _negated_assert,
  are_not = _negated_assert,
  is_true = _assert.is_true,
  is_false = _assert.is_false,
  falsey = _assert.falsey,
  same = _assert.same,
  equal = _assert.equal,
}

return global_assert
