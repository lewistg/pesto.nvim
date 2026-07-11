--- Subcommand invoked from a BUILD file. Infers the rule target underneath the
--- cursor and triggers a build for it.
---
---@class pesto.BuildUnderCursorSubcommand: pesto.Subcommand
---@field private _internal_config pesto.InternalConfig
---@field private _internal_run_bazel_fn pesto.InternalRunBazelFn
local BuildUnderCursorSubcommand = {}
BuildUnderCursorSubcommand.__index = BuildUnderCursorSubcommand

BuildUnderCursorSubcommand.name = 'build-under-cursor'

BuildUnderCursorSubcommand._phrases = {
  no_rule_under_cursor = 'Pesto: did not detect rule under cursor',
}

---@param internal_config pesto.InternalConfig
---@param internal_run_bazel pesto.InternalRunBazelFn
---@return pesto.BuildUnderCursorSubcommand
function BuildUnderCursorSubcommand.new(internal_config, internal_run_bazel)
  local o = setmetatable({}, BuildUnderCursorSubcommand)

  o._internal_config = internal_config
  o._internal_run_bazel_fn = internal_run_bazel

  o.complete = function(opts)
    return {}
  end

  o.execute = function(opts)
    o:_execute(opts)
  end

  return o
end

---@param opts pesto.SubcommandExecuteOpts
function BuildUnderCursorSubcommand:_execute(opts)
  -- Side effect: calling parse ensures the tree is up to date (see :help vim.treesitter.get_node()
  local tree = vim.treesitter.get_parser(0):parse()[1]

  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  cursor_pos = { cursor_pos[1] - 1, cursor_pos[2] }

  local bazel_package = require('pesto.bazel.package')
  local rule_target = bazel_package.infer_rule_target_name_by_ts_query(nil, cursor_pos)[1]

  if rule_target == nil then
    vim.notify(BuildUnderCursorSubcommand._phrases.no_rule_under_cursor, vim.log.levels.WARN)
    return
  end

  local runner = require('pesto.runner.runner')
  local bazel_command = {
    self._internal_config:get_bazel_executable(),
    'build',
    ':' .. rule_target.name,
  }
  local context = runner.get_run_bazel_context()

  self._internal_run_bazel_fn({
    bazel_command = bazel_command,
    context = context,
  })
end

return BuildUnderCursorSubcommand
