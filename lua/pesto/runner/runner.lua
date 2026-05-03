local M = {}

---@class pesto.RunBazelContext
---@field workspace_dir string
---@field package_dir string|nil
---@field package_label string|nil
---@field buf_nr number

---@class pesto.RunBazelOpts
---@field bazel_command string[]
---@field context pesto.RunBazelContext

---@alias pesto.RunBazelFn fun(opts: pesto.RunBazelOpts)

---@return pesto.RunBazelContext
function M.get_run_bazel_context()
  local bazel_repo = require('pesto.bazel.repo')
  local build_file = bazel_repo.find_build_file()
  local build_dir = vim.fs.dirname(build_file)

  local buf_nr = vim.api.nvim_get_current_buf()
  local package_label = bazel_repo.get_package_label(buf_nr)

  local workspace_marker_file = bazel_repo.find_project_root_marker_file()
  local workspace_dir = vim.fs.dirname(workspace_marker_file)

  return {
    workspace_dir = workspace_dir,
    package_dir = build_dir,
    package_label = package_label,
    buf_nr = buf_nr,
  }
end

return M
