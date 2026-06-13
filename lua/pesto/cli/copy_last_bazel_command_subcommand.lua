--- Subcommand to copy the last bazel command that was run
---@class pesto.CopyLastBazelCommandSubcommand: pesto.Subcommand
---@field private _bazel_run_history pesto.BazelRunHistory
local CopyLastBazelCommandSubcommand = {}
CopyLastBazelCommandSubcommand.__index = CopyLastBazelCommandSubcommand

CopyLastBazelCommandSubcommand.name = 'copy-last-bazel-command'

---@param bazel_command_history pesto.BazelRunHistory
function CopyLastBazelCommandSubcommand:new(bazel_command_history)
  local o = setmetatable({}, CopyLastBazelCommandSubcommand)

  o._bazel_run_history = bazel_command_history

  o.execute = function(opts)
    o:_execute(opts)
  end

  return o
end

---@param opts pesto.SubcommandExecuteOpts
function CopyLastBazelCommandSubcommand:_execute(opts)
  local run_opts = self._bazel_run_history:get_last_run_opts()
  if run_opts == nil then
    vim.notify('Pesto: no previous command to copy', vim.log.levels.ERROR)
    return
  end
  local shell_command = table.concat(run_opts.bazel_command, ' ')
  local full_shell_command =
    string.format('(cd %s && %s)', run_opts.context.package_dir or '.', shell_command)

  vim.fn.setreg('+', full_shell_command)
  vim.fn.setreg('"', full_shell_command .. '\n')

  vim.notify('Pesto: Yanked and copied last Bazel command', vim.log.levels.INFO)
end

return CopyLastBazelCommandSubcommand
