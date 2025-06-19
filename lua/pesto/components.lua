-- Note: This module contains the global set of components for the plugin. Because
-- users may not use certain plugin functionality, we try to avoid initializing
-- components until they are needed. To achieve this laziness, we do things
-- like wrapping component initialization in functions and inlining `require`
-- statements.

local LazyTable = require("pesto.util.lazy_table")
local BazelSubcommand = require("pesto.cli.bazel_subcommand")

-- This plugin does manual dependency injection. This class contains the
-- plugin's global set of components.
---@class Components
---@field bazel_sub_command BazelSubcommand
---@field settings Settings
---@field query_drawer_manager QueryDrawerManager

---@type Components
local components = LazyTable:new() --[[@as Components]]

local function _bazel_sub_command()
	return BazelSubcommand:new(components.settings.bazel_runner)
end
components.bazel_sub_command = _bazel_sub_command --[[@as BazelSubcommand]]

local _settings = function()
	return require("pesto.settings").settings
end
components.settings = _settings --[[@as Settings ]]

local _query_drawer_manager = function()
	local QueryDrawerManager = require("pesto.query_drawer.query_drawer_manager")
	local logger = require("lua.pesto.logger")
	return QueryDrawerManager:new(logger, components.settings)
end
components.query_drawer_manager = _query_drawer_manager --[[@as QueryDrawerManager ]]

return components
