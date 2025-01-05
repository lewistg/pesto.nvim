local settings = {}

local terminal_runner = require('pesto.runner.terminal')

settings.bazel_command = 'bazel'
settings.bazel_runner = terminal_runner.run

function settings.setup(opts)
    settings.bazel_command = opts.bazel_command or settings.bazel_command
    settings.bazel_runner = opts.runner or settings.bazel_runner
end

return settings
