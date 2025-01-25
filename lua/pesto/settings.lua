local M = {}

local terminal_runner = require('pesto.runner.terminal')

M.bazel_command = 'bazel'
M.bazel_runner = terminal_runner.run
M.log_level = 'info'

function M.setup(opts)
    M.bazel_command = opts.bazel_command or M.bazel_command
    M.bazel_runner = opts.runner or M.bazel_runner
    M.log_level = opts.log_level or M.log_level
end

return M
