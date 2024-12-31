local settings = {}

local terminal_runner = require('pesto.runner.terminal')

settings.run_bazel = terminal_runner.run

function settings.setup(opts)
    settings = opts.runner or settings.runner
end

return settings
