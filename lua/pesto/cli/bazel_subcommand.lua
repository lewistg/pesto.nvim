---@class BazelSubcommand: Subcommand
---@field private _settings pesto.Settings
---@field private _basic_completion pesto.BazelBasicCompletion
---@field private _run_bazel_fn RunBazelFn
local BazelSubcommand = {}
BazelSubcommand.__index = BazelSubcommand

BazelSubcommand.name = "bazel"

---@param settings pesto.Settings
---@param bazel_basic_completion pesto.BazelBasicCompletion
---@param run_bazel_fn RunBazelFn
function BazelSubcommand:new(settings, bazel_basic_completion, run_bazel_fn)
	local o = setmetatable({}, BazelSubcommand)

	o._settings = settings

	o._basic_completion = bazel_basic_completion

	o._run_bazel_fn = run_bazel_fn

	o.complete = function(opts)
		return o:_complete(opts)
	end
	o.execute = function(opts)
		o:_execute(opts)
	end

	return o
end

---@param opts SubcommandCompleteOpts
---@return string[]
function BazelSubcommand:_complete(opts)
	return self._basic_completion:complete(opts)
end

---@param opts SubcommandExecuteOpts
function BazelSubcommand:_execute(opts)
	-- There should be at least one farg value (the name of the subcommand)
	assert(#opts.fargs >= 1)

	local runner = require("pesto.runner.runner")
	local context = runner.get_run_bazel_context()
	local bazel_command = vim.deepcopy(opts.fargs)
	if self._settings:get_enable_bep_integration() then
		local bazel_build_event_util = require("pesto.cli.bazel_build_event_util")
		bazel_build_event_util.inject_bep_option(bazel_command, self._settings)
	end
	table.insert(bazel_command, 1, "bazel")

	self._run_bazel_fn({
		bazel_command = bazel_command,
		context = context,
	})
end

return BazelSubcommand
