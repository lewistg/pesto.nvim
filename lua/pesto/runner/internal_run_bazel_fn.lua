---@class pesto.InternalRunBazelFn
---@field private _internal_settings pesto.InternalSettings
---@field private _command_history pesto.BazelRunHistory
local InternalRunBazelFn = {}
InternalRunBazelFn.__index = InternalRunBazelFn

function InternalRunBazelFn:new(internal_settings, command_history)
  local o = setmetatable({}, InternalRunBazelFn)

  o._internal_settings = internal_settings
  o._command_history = command_history

  return o
end

---@param opts pesto.RunBazelOpts
function InternalRunBazelFn:execute(opts)
  -- Note: downstream runners may modify or inject additional options. It'll be
  -- their job to modify the history.
  self._command_history:push_run_opts(vim.deepcopy(opts))
  self._internal_settings:_get_bazel_runner()(opts)
end

---@param opts pesto.RunBazelOpts
function InternalRunBazelFn.__call(self, opts)
  self:execute(opts)
end

return InternalRunBazelFn
