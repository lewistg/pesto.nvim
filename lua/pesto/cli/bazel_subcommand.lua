---@class pesto.BazelSubcommand: pesto.Subcommand
---@field private _settings pesto.InternalSettings
---@field private _completion pesto.SubcommandCompletion|nil
---@field private _basic_completion pesto.BazelBasicCompletion
---@field private _bash_completion pesto.BazelBashCompletion
---@field private _internal_run_bazel_fn pesto.InternalRunBazelFn
local BazelSubcommand = {}
BazelSubcommand.__index = BazelSubcommand

BazelSubcommand.name = 'bazel'

---@param settings pesto.InternalSettings
---@param bazel_basic_completion pesto.BazelBasicCompletion
---@param bazel_bash_completion pesto.BazelBashCompletion
---@param internal_run_bazel_fn pesto.InternalRunBazelFn
function BazelSubcommand:new(
  settings,
  bazel_basic_completion,
  bazel_bash_completion,
  internal_run_bazel_fn
)
  local o = setmetatable({}, BazelSubcommand)

  o._settings = settings

  o._basic_completion = bazel_basic_completion
  o._bash_completion = bazel_bash_completion

  o._internal_run_bazel_fn = internal_run_bazel_fn

  o.complete = function(opts)
    return o:_complete(opts)
  end
  o.execute = function(opts)
    o:_execute(opts)
  end

  return o
end

---@param opts pesto.SubcommandCompleteOpts
---@return string[]
function BazelSubcommand:_complete(opts)
  return self:_get_completion():complete(opts)
end

---@return pesto.SubcommandCompletion
function BazelSubcommand:_get_completion()
  if self._completion ~= nil then
    return self._completion
  end

  local logger = require('pesto.logger')

  ---@return pesto.SubcommandCompletion
  local function resolve_automatic_completion()
    local completion
    ---@type pesto.CliCompletionMode
    local mode
    if self._bash_completion:is_available() then
      mode = 'bash'
      completion = self._bash_completion
    else
      mode = 'lua'
      completion = self._basic_completion
    end
    logger.debug(string.format('automatically resolved completion strategy: %s', mode))
    return completion
  end

  ---@type pesto.SubcommandCompletion
  local completion
  local mode = self._settings:get_cli_completion_settings().mode

  if mode == 'lua' then
    completion = self._basic_completion
  elseif mode == 'bash' then
    completion = self._bash_completion
  elseif mode == 'automatic' then
    completion = resolve_automatic_completion()
  else
    logger.warn(
      string.format('unrecognized completion mode "%s", falling back to "automatic" mode', mode)
    )
    completion = resolve_automatic_completion()
  end

  self._completion = completion
  return self._completion
end

---@param opts pesto.SubcommandExecuteOpts
function BazelSubcommand:_execute(opts)
  local runner = require('pesto.runner.runner')
  local context = runner.get_run_bazel_context()
  local bazel_command = vim.deepcopy(opts.fargs)

  table.insert(bazel_command, 1, self._settings:get_bazel_executable())

  self._internal_run_bazel_fn({
    bazel_command = bazel_command,
    context = context,
  })
end

return BazelSubcommand
