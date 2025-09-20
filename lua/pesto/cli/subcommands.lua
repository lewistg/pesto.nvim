local M = {}

local bazel = require("pesto.bazel")
local build_event_util = require("pesto.cli.bazel_build_event_util")
local runner = require("pesto.runner.runner")
local table_util = require("pesto.util.table_util")

---@class Subcommands
---@field SUBCOMMANDS_BY_NAME {[string]: Subcommand}
---@field SUBCOMMAND_NAMES string[]

---@class SubcommandCompleteOpts
---@field subcommand_line string
---@field cursor_pos number
---@field arg_lead string
---@field buf_nr number

---@alias SubcommandCompleteFn fun(opts: SubcommandCompleteOpts): string[]

---@class SubcommandExecuteOpts
---@field fargs string[]
---@field buf_nr number

---@alias SubcommandExecuteFn fun(opts: SubcommandExecuteOpts)

---@class Subcommand
---@field name string
---@field complete SubcommandCompleteFn?
---@field execute SubcommandExecuteFn

---@param open_cmd "vsplit"|"split"
local function open_build_file(open_cmd)
	local build_file_path = bazel.repo.find_build_file()
	if build_file_path == nil then
		vim.notify("Pesto: failed to find BUILD or BUILD.bazel file for current file", vim.log.levels.ERROR)
	else
		vim.cmd(string.format("%s %s", open_cmd, build_file_path))
	end
end

---@type SubcommandExecuteFn
local function execute_vs_build_subcommand()
	open_build_file("vsplit")
end

---@type SubcommandExecuteFn
local function execute_sp_build_subcommand()
	open_build_file("split")
end

---@type SubcommandExecuteFn
local function execute_yank_package_label_subcommand()
	local package_label = bazel.repo.get_package_label()
	vim.fn.setreg("@", package_label .. "\n")
end

---@param run_bazel_fn RunBazelFn
---@param settings pesto.Settings
local function get_compile_one_dep_subcommand(run_bazel_fn, settings)
	---@type SubcommandExecuteFn
	local function execute()
		---@type string
		local filename = vim.api.nvim_buf_get_name(0)
		filename = vim.fs.basename(filename)
		---@type RunBazelContext
		local context = runner.get_run_bazel_context()
		---@type string[]
		local bazel_command = { "bazel", "build", "--compile_one_dependency", filename }

		---@type RunBazelOpts
		local opts = {
			bazel_command = bazel_command,
			context = context,
		}
		run_bazel_fn(opts)
	end
	return {
		name = "compile-one-dep",
		execute = execute,
	}
end

---@class pesto.SubcommandDeps
---@field bazel_sub_command BazelSubcommand
---@field open_build_events_summary_subcommand pesto.OpenBuildEventsSummarySubcommand
---@field open_build_term_subcommand pesto.OpenBuildTermSubcommand
---@field run_bazel_fn RunBazelFn
---@field settings pesto.Settings

---@param deps pesto.SubcommandDeps
---@return Subcommands[]
function M.make_subcommands(deps)
	local subcommands = {
		-- Please keep keys alphabetized (by command name)
		deps.bazel_sub_command,
		get_compile_one_dep_subcommand(deps.run_bazel_fn, deps.settings),
		deps.open_build_term_subcommand,
		{
			name = "sp-build",
			execute = execute_sp_build_subcommand,
		},
		deps.open_build_events_summary_subcommand,
		{
			name = "vs-build",
			execute = execute_vs_build_subcommand,
		},
		{
			name = "yank-package-label",
			execute = execute_yank_package_label_subcommand,
		},
	}

	---@type {[string]: Subcommand}
	local SUBCOMMANDS_BY_NAME = table_util.to_map(table_util.map(subcommands, function(subcommand)
		return { subcommand.name, subcommand }
	end))

	---@type string[]
	local SUBCOMMAND_NAMES = table_util.get_keys(SUBCOMMANDS_BY_NAME)

	return {
		SUBCOMMANDS_BY_NAME = SUBCOMMANDS_BY_NAME,
		SUBCOMMAND_NAMES = SUBCOMMAND_NAMES,
	}
end

return M
