-- Note: This module contains the global set of components for the plugin. Because
-- users may not use certain plugin functionality, we try to avoid initializing
-- components until they are needed. To achieve this laziness, we do things
-- like wrapping component initialization in functions and inlining `require`
-- statements.

local LazyTable = require("pesto.util.lazy_table")

-- This plugin does manual dependency injection. This class contains the
-- plugin's global set of components.
---@class Components
---@field bazel_sub_command pesto.BazelSubcommand
---@field bazel_bash_completion pesto.BazelBashCompletion
---@field bazel_bash_completion_client pesto.BazelBashCompletionClient
---@field bazel_basic_completion pesto.BazelBasicCompletion
---@field build_event_json_loader pesto.BuildEventJsonLoader
---@field build_event_file_loader pesto.BuildEventFileLoader
---@field build_window_manager pesto.BuildWindowManager
---@field byte_stream_client pesto.ByteStreamClient
---@field default_runner pesto.DefaultRunner
---@field functional_test_hooks pesto.FunctionalTestHooks
---@field install_remote_apis_helpers_subcommand pesto.InstallRemoteApisHelpersSubcommand
---@field open_build_term_subcommand pesto.OpenBuildTermSubcommand
---@field pesto_cli PestoCli
---@field quick_fix_loader pesto.QuickfixLoader
---@field remote_apis_helpers_command_builder pesto.RemoteApisHelpersCommandBuilder
---@field run_bazel_fn RunBazelFn
---@field settings pesto.InternalSettings
---@field subcommands pesto.Subcommands
---@field open_build_events_summary_subcommand pesto.OpenBuildEventsSummarySubcommand

---@type Components
local components = LazyTable:new() --[[@as Components]]

---@return pesto.BazelBashCompletion
local function _bazel_bash_completion()
	return require("pesto.cli.bazel_bash_completion.bazel_bash_completion"):new(
		components.bazel_bash_completion_client,
		components.settings
	)
end
components.bazel_bash_completion = _bazel_bash_completion --[[@as pesto.BazelBashCompletion]]

---@return pesto.BazelBasicCompletion
local function _bazel_basic_completion()
	return require("pesto.cli.bazel_basic_completion"):new()
end
components.bazel_basic_completion = _bazel_basic_completion --[[@as pesto.BazelBasicCompletion]]

---@return pesto.BazelBashCompletionClient
local function _bazel_bash_completion_client()
	return require("pesto.cli.bazel_bash_completion.bazel_bash_completion_client"):new(components.settings)
end
components.bazel_bash_completion_client = _bazel_bash_completion_client --[[@as pesto.BazelBashCompletionClient]]

---@return pesto.BuildEventJsonLoader
local function _build_event_json_loader()
	return require("pesto.bazel.build_event_json_loader"):new()
end
components.build_event_json_loader = _build_event_json_loader --[[@as pesto.BuildEventJsonLoader]]

---@return pesto.BuildEventFileLoader
local function _build_event_file_loader()
	return require("pesto.bazel.build_event_file_loader"):new(components.byte_stream_client)
end
components.build_event_file_loader = _build_event_file_loader --[[@as pesto.BuildEventFileLoader]]

---@return pesto.BuildWindowManager
local function _build_window_manager()
	return require("pesto.runner.default.build_window_manager"):new(components.build_event_file_loader)
end
components.build_window_manager = _build_window_manager --[[@as pesto.BuildWindowManager]]

---@return pesto.BazelSubcommand
local function _bazel_sub_command()
	local BazelSubcommand = require("pesto.cli.bazel_subcommand")
	return BazelSubcommand:new(
		components.settings,
		components.bazel_basic_completion,
		components.bazel_bash_completion,
		components.run_bazel_fn
	)
end
components.bazel_sub_command = _bazel_sub_command --[[@as BazelSubcommand]]

---@return pesto.ByteStreamClient
local function _byte_stream_client()
	local ByteStreamClient = require("pesto.bazel.byte_stream_client")
	return ByteStreamClient:new(components.remote_apis_helpers_command_builder)
end
components.byte_stream_client = _byte_stream_client --[[@as pesto.ByteStreamClient]]

---@return pesto.DefaultRunner
local function _default_runner()
	return require("pesto.runner.default.default_runner"):new(
		components.settings,
		components.build_window_manager,
		components.build_event_json_loader,
		components.quick_fix_loader
	)
end
components.default_runner = _default_runner --[[@as pesto.DefaultRunner]]

---@return pesto.FunctionalTestHooks
local function _functional_test_hooks()
	return require("pesto.test.functional_test_hooks"):new(
		components.build_window_manager,
		components.remote_apis_helpers_command_builder
	)
end
components.functional_test_hooks = _functional_test_hooks --[[@as pesto.FunctionalTestHooks]]

---@return pesto.InstallRemoteApisHelpersSubcommand
local function _install_remote_apis_helpers_subcommand()
	return require("pesto.cli.install_remote_apis_helpers_subcommand"):new(
		components.remote_apis_helpers_command_builder
	)
end
components.install_remote_apis_helpers_subcommand = _install_remote_apis_helpers_subcommand --[[@as pesto.InstallRemoteApisHelpersSubcommand]]

---@return pesto.OpenBuildTermSubcommand
local function _open_build_term_subcommand()
	return require("pesto.cli.open_build_term_subcommand"):new(components.build_window_manager)
end
components.open_build_term_subcommand = _open_build_term_subcommand --[[@as pesto.OpenBuildTermSubcommand]]

local function _pesto_cli()
	return require("pesto.cli").make_cli(components.subcommands)
end
components.pesto_cli = _pesto_cli --[[@as PestoCli]]

local _settings = function()
	return require("pesto.settings"):new()
end
components.settings = _settings --[[@as pesto.InternalSettings ]]

local _quick_fix_loader = function()
	return require("pesto.runner.default.quickfix_loader"):new(components.build_event_file_loader, components.settings)
end
components.quick_fix_loader = _quick_fix_loader --[[ @as pesto.QuickfixLoader ]]

---@return pesto.RemoteApisHelpersCommandBuilder
local _remote_apis_helpers_command_builder = function()
	return require("pesto.bazel.remote_apis_helpers_command_builder"):new()
end
components.remote_apis_helpers_command_builder = _remote_apis_helpers_command_builder --[[ @as pesto.RemoteApisHelpersCommandBuilder ]]

---@return RunBazelFn
local _run_bazel_fn = function()
	---@params opts RunBazelOpts
	return function(opts)
		return components.settings:get_bazel_runner()(opts)
	end
end
components.run_bazel_fn = _run_bazel_fn --[[@as RunBazelFn ]]

---@return pesto.Subcommands
local _subcommands = function()
	return require("pesto.cli.subcommands").make_subcommands({
		bazel_sub_command = components.bazel_sub_command,
		install_remote_apis_helpers_subcommand = components.install_remote_apis_helpers_subcommand,
		open_build_events_summary_subcommand = components.open_build_events_summary_subcommand,
		run_bazel_fn = components.run_bazel_fn,
		open_build_term_subcommand = components.open_build_term_subcommand,
		settings = components.settings,
	})
end
components.subcommands = _subcommands --[[@as pesto.Subcommands]]

---@return pesto.OpenBuildEventsSummarySubcommand
local _open_build_events_summary_subcommand = function()
	return require("pesto.cli.open_build_events_summary_subcommand"):new(components.build_window_manager)
end
components.open_build_events_summary_subcommand = _open_build_events_summary_subcommand --[[@as pesto.OpenBuildEventsSummarySubcommand]]

return components
