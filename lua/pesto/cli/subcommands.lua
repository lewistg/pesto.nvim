local M = {}

---@class pesto.Subcommands
---@field SUBCOMMANDS_BY_NAME {[string]: pesto.Subcommand}
---@field SUBCOMMAND_NAMES string[]

---@class pesto.SubcommandCompleteOpts
---@field subcommand_line string
---@field cursor_pos number
---@field arg_lead string
---@field buf_nr number

---@alias pesto.SubcommandCompleteFn fun(opts: pesto.SubcommandCompleteOpts): string[]

---@class pesto.SubcommandExecuteOpts
---@field fargs string[]
---@field buf_nr number

---@alias pesto.SubcommandExecuteFn fun(opts: pesto.SubcommandExecuteOpts)

---@class pesto.SubcommandCompletion
---@field complete pesto.SubcommandCompleteFn?

---@class pesto.Subcommand: pesto.SubcommandCompletion
---@field name string
---@field complete pesto.SubcommandCompleteFn?
---@field execute pesto.SubcommandExecuteFn

---@param open_cmd "vsplit"|"split"
local function open_build_file(open_cmd)
	local bazel_repo = require("pesto.bazel.repo")
	local build_file_path = bazel_repo.find_build_file()
	if build_file_path == nil then
		vim.notify("Pesto: failed to find BUILD or BUILD.bazel file for current file", vim.log.levels.ERROR)
	else
		vim.cmd(string.format("%s %s", open_cmd, build_file_path))
	end
end

---@type pesto.SubcommandExecuteFn
local function execute_vs_build_subcommand()
	open_build_file("vsplit")
end

---@type pesto.SubcommandExecuteFn
local function execute_sp_build_subcommand()
	open_build_file("split")
end

---@type pesto.SubcommandExecuteFn
local function execute_yank_package_label_subcommand()
	local bazel_repo = require("pesto.bazel.repo")
	local package_label = bazel_repo.get_package_label()
	if package_label == nil then
		return
	end
	vim.fn.setreg("@", package_label .. "\n")
end

---@param run_bazel_fn RunBazelFn
---@param settings pesto.Settings
local function get_compile_one_dep_subcommand(run_bazel_fn, settings)
	---@type pesto.SubcommandExecuteFn
	local function execute()
		local runner = require("pesto.runner.runner")
		---@type RunBazelContext
		local context = runner.get_run_bazel_context()

		---@type string
		local filename = vim.api.nvim_buf_get_name(0)
		filename = vim.fs.relpath(context.package_dir or context.workspace_dir, filename) or filename

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
---@return pesto.Subcommands[]
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

	---@type {[string]: pesto.Subcommand}
	local SUBCOMMANDS_BY_NAME = {}
	for _, subcommand in ipairs(subcommands) do
		SUBCOMMANDS_BY_NAME[subcommand.name] = subcommand
	end

	---@type string[]
	local SUBCOMMAND_NAMES = vim.tbl_keys(SUBCOMMANDS_BY_NAME)

	return {
		SUBCOMMANDS_BY_NAME = SUBCOMMANDS_BY_NAME,
		SUBCOMMAND_NAMES = SUBCOMMAND_NAMES,
	}
end

return M
