-- Note: This module contains the global set of components for the plugin. Because
-- users may not use certain plugin functionality, we try to avoid initializing
-- components until they are needed. To achieve this laziness, we do things
-- like wrapping component initialization in functions and inlining `require`
-- statements.

local LazyTable = require("pesto.util.lazy_table")

-- This plugin does manual dependency injection. This class contains the
-- plugin's global set of components.
---@class Components
---@field bazel_sub_command BazelSubcommand
---@field pesto_cli PestoCli
---@field settings Settings
---@field subcommands Subcommands
---@field query_drawer_manager QueryDrawerManager

---@type Components
local components = LazyTable:new() --[[@as Components]]

local function _bazel_sub_command()
	local BazelSubcommand = require("pesto.cli.bazel_subcommand")
	return BazelSubcommand:new(components.settings.bazel_runner)
end
components.bazel_sub_command = _bazel_sub_command --[[@as BazelSubcommand]]

local function _pesto_cli()
	return require("pesto.cli").make_cli(components.subcommands)
end
components.pesto_cli = _pesto_cli --[[@as PestoCli]]

local _settings = function()
	return require("pesto.settings").settings
end
components.settings = _settings --[[@as Settings ]]

---@return Subcommands
local _subcommands = function()
	return require("pesto.cli.subcommands").make_subcommands({
		bazel_sub_command = components.bazel_sub_command,
	})
end
components.subcommands = _subcommands --[[@as Subcommands]]

local _query_drawer_manager = function()
	local QueryDrawerManager = require("pesto.query_drawer.query_drawer_manager")
	local logger = require("lua.pesto.logger")
	return QueryDrawerManager:new(logger, components.settings)
end
components.query_drawer_manager = _query_drawer_manager --[[@as QueryDrawerManager ]]

return components
