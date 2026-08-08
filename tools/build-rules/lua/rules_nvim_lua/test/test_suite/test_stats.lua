---@class rules_nvim_lua.TestStats
---@field successes number
---@field failures number
---@field errors number
local TestStats = {}
TestStats.__index = TestStats

---@param stats {successes: number, failures: number, errors: number}|nil
function TestStats.new(stats)
  local o = setmetatable({}, TestStats)

  if stats ~= nil then
    o.successes = stats.successes
    o.failures = stats.failures
    o.errors = stats.errors
  else
    o.successes = 0
    o.failures = 0
    o.errors = 0
  end

  return o
end

function TestStats:inc_successes()
  self.successes = self.successes + 1
end

function TestStats:inc_failures()
  self.failures = self.failures + 1
end

function TestStats:inc_errors()
  self.errors = self.errors + 1
end

function TestStats:add(other)
  return TestStats.new({
    successes = self.successes + other.successes,
    failures = self.failures + other.failures,
    errors = self.errors + other.errors,
  })
end

return TestStats
