local pesto = {}

function pesto.setup(settings_override)
    local settings = require('pesto.settings')
    settings.setup(settings_override)

    local components = require('pesto.components')
    local commands = require('pesto.commands')
    commands.create_commands(components)
end

return pesto
