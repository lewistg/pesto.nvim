---@class rules_nvim_lua.AssertionError
---@field message string
---@field location {source: string, line: number}
local AssertionError = {}
AssertionError.__index = AssertionError

---@param opts {message: string, location: {source: string, line: number}}
function AssertionError.new(opts)
  local o = setmetatable({}, AssertionError)
  o.message = opts.message
  o.location = opts.location
  return o
end

return AssertionError
