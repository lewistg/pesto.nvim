local pesto = {}

local settings = require('pesto.settings')
local commands = require('pesto.commands')

function pesto.setup(opts)
    settings.setup(opts)
    commands.create_commands()
end

return pesto
