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
---@field build_event_json_json_loader pesto.BuildEventJsonLoader
---@field build_event_file_loader pesto.BuildEventFileLoader
---@field build_terminal_manager pesto.BuildTerminalManager
---@field default_runner pesto.DefaultRunner
---@field open_build_term_subcommand pesto.OpenBuildTermSubcommand
---@field pesto_cli PestoCli
---@field settings pesto.Settings
---@field run_bazel_fn RunBazelFn
---@field subcommands Subcommands
---@field query_drawer_manager QueryDrawerManager
---@field open_build_events_summary_subcommand pesto.OpenBuildEventsSummarySubcommand

---@type Components
local components = LazyTable:new() --[[@as Components]]

---@return pesto.BuildEventJsonLoader
local function _build_event_json_loader()
	return require("pesto.bazel.build_event_json_loader"):new()
end
components.build_event_json_json_loader = _build_event_json_loader --[[@as pesto.BuildEventJsonLoader]]

---@return pesto.BuildEventFileLoader
local function _build_event_file_loader()
	return require("pesto.bazel.build_event_file_loader"):new()
end
components.build_event_file_loader = _build_event_file_loader --[[@as pesto.BuildEventFileLoader]]

---@return pesto.BuildTerminalManager
local function _build_terminal_manager()
	return require("pesto.runner.default.terminal_buffer_manager"):new()
end
components.build_terminal_manager = _build_terminal_manager --[[@as pesto.BuildTerminalManager]]

local function _bazel_sub_command()
	local BazelSubcommand = require("pesto.cli.bazel_subcommand")
	return BazelSubcommand:new(components.settings, components.run_bazel_fn)
end
components.bazel_sub_command = _bazel_sub_command --[[@as BazelSubcommand]]

---@return pesto.DefaultRunner
local function _default_runner()
	return require("pesto.runner.default.default_runner"):new(components.settings, components.build_terminal_manager)
end
components.default_runner = _default_runner --[[@as pesto.DefaultRunner]]

---@return pesto.OpenBuildTermSubcommand
local function _open_build_term_subcommand()
	return require("pesto.cli.open_build_term_subcommand"):new(components.build_terminal_manager)
end
components.open_build_term_subcommand = _open_build_term_subcommand --[[@as pesto.OpenBuildTermSubcommand]]

local function _pesto_cli()
	return require("pesto.cli").make_cli(components.subcommands)
end
components.pesto_cli = _pesto_cli --[[@as PestoCli]]

local _settings = function()
	return require("pesto.settings"):new()
end
components.settings = _settings --[[@as pesto.Settings ]]

---@return RunBazelFn
local _run_bazel_fn = function()
	---@params opts RunBazelOpts
	return function(opts)
		return components.settings:get_bazel_runner()(opts)
	end
end
components.run_bazel_fn = _run_bazel_fn --[[@as RunBazelFn ]]

---@return Subcommands
local _subcommands = function()
	return require("pesto.cli.subcommands").make_subcommands({
		bazel_sub_command = components.bazel_sub_command,
		open_build_events_summary_subcommand = components.open_build_events_summary_subcommand,
		run_bazel_fn = components.run_bazel_fn,
		open_build_term_subcommand = components.open_build_term_subcommand,
		settings = components.settings,
	})
end
components.subcommands = _subcommands --[[@as Subcommands]]

local _query_drawer_manager = function()
	local QueryDrawerManager = require("pesto.query_drawer.query_drawer_manager")
	local logger = require("lua.pesto.logger")
	return QueryDrawerManager:new(logger, components.settings)
end
components.query_drawer_manager = _query_drawer_manager --[[@as QueryDrawerManager ]]

---@return pesto.OpenBuildEventsSummarySubcommand
local _open_build_events_summary_subcommand = function()
	return require("pesto.cli.open_build_events_summary_subcommand"):new(
		components.build_event_json_json_loader,
		components.build_event_file_loader
	)
end
components.open_build_events_summary_subcommand = _open_build_events_summary_subcommand --[[@as pesto.OpenBuildEventsSummarySubcommand]]

return components
