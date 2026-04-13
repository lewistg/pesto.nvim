local M = {}

---@class pesto.RunBazelContext
---@field workspace_dir string
---@field package_dir string|nil

---@class pesto.RunBazelOpts
---@field bazel_command string[]
---@field context pesto.RunBazelContext

---@alias pesto.RunBazelFn fun(opts: pesto.RunBazelOpts)

---@return pesto.RunBazelContext
function M.get_run_bazel_context()
	local bazel_repo = require("pesto.bazel.repo")
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
