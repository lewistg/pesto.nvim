local M = {}

local bazel = require("pesto.bazel")
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

---@type SubcommandExecuteFn
local function execute_vs_build_subcommand()
	local build_file_path = bazel.repo.find_build_file()
	vim.cmd.vsplit(build_file_path)
end

---@type SubcommandExecuteFn
local function execute_sp_build_subcommand()
	local build_file_path = bazel.repo.find_build_file()
	vim.cmd.split(build_file_path)
end

---@type SubcommandExecuteFn
local function execute_yank_package_label_subcommand()
	local package_label = bazel.repo.get_package_label()
	vim.fn.setreg("@", package_label .. "\n")
end

---@param run_bazel_fn RunBazelFn
local function get_compile_one_dep_subcommand(run_bazel_fn)
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

---@param deps {bazel_sub_command: BazelSubcommand, run_bazel_fn: RunBazelFn}
---@return Subcommand[]
function M.make_subcommands(deps)
	local subcommands = {
		-- Please keep keys alphabetized
		deps.bazel_sub_command,
		get_compile_one_dep_subcommand(deps.run_bazel_fn),
		{
			name = "sp-build",
			execute = execute_sp_build_subcommand,
		},
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
