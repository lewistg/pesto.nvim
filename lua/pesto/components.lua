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
---@field build_events_json_loader BuildEventJsonLoader
---@field pesto_cli PestoCli
---@field settings Settings
---@field subcommands Subcommands
---@field query_drawer_manager QueryDrawerManager
---@field view_build_events_summary_subcommand ViewBuildEventsSummarySubcommand

---@type Components
local components = LazyTable:new() --[[@as Components]]

local function _bazel_sub_command()
	local BazelSubcommand = require("pesto.cli.bazel_subcommand")
	return BazelSubcommand:new(components.settings.bazel_runner)
end
components.bazel_sub_command = _bazel_sub_command --[[@as BazelSubcommand]]

---@return BuildEventJsonLoader
local function _build_events_json_loader()
	local BuildEventJsonLoader = require("pesto.bazel.build_event_json_loader")
	return BuildEventJsonLoader:new()
end
components.build_events_json_loader = _build_events_json_loader --[[@as BuildEventJsonLoader]]

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
		run_bazel_fn = components.settings.bazel_runner,
		view_build_events_summary_subcommand = components.view_build_events_summary_subcommand,
	})
end
components.subcommands = _subcommands --[[@as Subcommands]]

local _query_drawer_manager = function()
	local QueryDrawerManager = require("pesto.query_drawer.query_drawer_manager")
	local logger = require("lua.pesto.logger")
	return QueryDrawerManager:new(logger, components.settings)
end
components.query_drawer_manager = _query_drawer_manager --[[@as QueryDrawerManager ]]

---@return ViewBuildEventsSummarySubcommand
local function _view_build_events_summary_subcommand()
	---@type ViewBuildEventsSummarySubcommand
	local ViewBuildEventsSummarySubcommand = require("pesto.cli.view_build_events_summary_subcommand")
	return ViewBuildEventsSummarySubcommand:new(components.build_events_json_loader)
end
components.view_build_events_summary_subcommand = _view_build_events_summary_subcommand --[[@as ViewBuildEventsSummarySubcommand]]

return components
