---@class pesto.InternalRunBazelFn
---@field private _internal_config pesto.InternalConfig
---@field private _default_run_bazel_fn pesto.RunBazelFn
---@field private _command_history pesto.BazelRunHistory
local InternalRunBazelFn = {}
InternalRunBazelFn.__index = InternalRunBazelFn

---@param internal_config pesto.InternalConfig
---@param default_run_bazel_fn pesto.RunBazelFn
---@param command_history pesto.BazelRunHistory
function InternalRunBazelFn:new(internal_config, default_run_bazel_fn, command_history)
  local o = setmetatable({}, InternalRunBazelFn)

  o._internal_config = internal_config
  o._default_run_bazel_fn = default_run_bazel_fn
  o._command_history = command_history

  return o
end

---@param opts pesto.RunBazelOpts
function InternalRunBazelFn:execute(opts)
  -- Note: downstream runners may modify or inject additional options. It'll be
  -- their job to modify the history.
  self._command_history:push_run_opts(vim.deepcopy(opts))

  local runner = self._internal_config:_get_bazel_runner() or self._default_run_bazel_fn
  runner(opts)
end

---@param opts pesto.RunBazelOpts
function InternalRunBazelFn.__call(self, opts)
  self:execute(opts)
end

return InternalRunBazelFn
