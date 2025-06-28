local M = {}

local bazel_repo = require("pesto.bazel").repo

---@class RunBazelContext
---@field workspace_dir string
---@field package_dir string|nil

---@class RunBazelOpts
---@field bazel_command string[]
---@field context RunBazelContext

---@alias RunBazelFn fun(RunBazelOpts)

---@return RunBazelContext
function M.get_run_bazel_context()
	local build_file = bazel_repo.find_build_file()
	local build_dir = vim.fs.dirname(build_file)

	local workspace_marker_file = bazel_repo.find_project_root_marker_file()
	local workspace_dir = vim.fs.dirname(workspace_marker_file)

	return {
		workspace_dir = workspace_dir,
		package_dir = build_dir,
	}
end

return M
