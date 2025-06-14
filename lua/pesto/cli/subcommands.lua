local M = {}

local bazel = require("pesto.bazel")
local table_util = require("pesto.util.table_util")

---@class SubcommandCompleteOpts
---@field subcommand_line string
---@field cursor_pos number
---@field arg_lead string
---@field buf_nr number

---@alias SubcommandCompleteFn fun(opts: SubcommandCompleteOpts): string[]
---@alias SubcommandExecuteFn fun()

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

---@type Subcommand[]
local subcommands = {
	-- Please keep keys alphabetized
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
M.SUBCOMMANDS_BY_NAME = table_util.to_map(table_util.map(subcommands, function(subcommand)
	return { subcommand.name, subcommand }
end))

---@type string[]
M.SUBCOMMAND_NAMES = table_util.get_keys(M.SUBCOMMANDS_BY_NAME)

return M
