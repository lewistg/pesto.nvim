-- Note: This module contains the global set of components for the plugin. Because
-- users may not use certain plugin functionality, we try to avoid initializing
-- components until they are needed. To achieve this laziness, we do things
-- like wrapping component initialization in functions and inlining `require`
-- statements.

-- This plugin does manual dependency injection. This class contains the
-- plugin's global set of components.
---@class Components
---@field settings Settings
---@field logger Logger
---@field query_drawer_manager QueryDrawerManager

local _components = {}
local component_providers = {
    settings = function()
        return require('pesto.settings').settings
    end,
    logger = function()
        local logger_factory = require('pesto.logger')
        return logger_factory.get_logger(_components.settings.log_level)
    end,
    query_drawer_manager = function()
        local QueryDrawerManager = require('pesto.query_drawer.query_drawer_manager')
        return QueryDrawerManager:new(_components.logger, _components.settings)
    end
}

---@type Components
local components = setmetatable(_components, {
    -- We lazily create the components
    __index = function(_, key)
        -- Recall: The __index method is only called when the indexed value is
        -- not present in the table. We leverage this to lazily fill in the 
        if (component_providers[key] == nil) then
           error('No provider for component: ' .. key)
        elseif (type(component_providers[key]) == "function") then
            _components[key] = component_providers[key]()
        else
            _components[key] = component_providers[key]
        end
        return _components[key]
    end,
})

return components
