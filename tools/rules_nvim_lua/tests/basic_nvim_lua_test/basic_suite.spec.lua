--- This module also serves to test the basic builtin test framework

local function fib(n)
  if n == 0 or n == 1 then
    return 1
  end
  local fib_window = { 1, 1 }
  local i = 2
  while i <= n do
    local next = fib_window[1] + fib_window[2]
    fib_window[1] = fib_window[2]
    fib_window[2] = next
    i = i + 1
  end
  return fib_window[2]
end

describe('fib', function()
  it('gets the nth fibonacci number', function()
    assert.equal(1, fib(0))
    assert.equal(1, fib(1))
    assert.equal(2, fib(2))
    assert.equal(3, fib(3))
    assert.equal(5, fib(4))
    assert.equal(8, fib(5))
  end)
end)

describe('truthy/falsey', function()
  it('truthy value', function()
    assert.truthy(true)
  end)
  it('falsey value', function()
    assert.falsey(false)
    assert.falsey(nil)
  end)
  it('truthy can be negated', function()
    assert.is_not.truthy(nil)
  end)
  it('falsey can be negated', function()
    assert.is_not.falsey(true)
  end)
end)

describe('nesting', function()
  describe('nested', function()
    assert.truthy(true)
  end)
end)
