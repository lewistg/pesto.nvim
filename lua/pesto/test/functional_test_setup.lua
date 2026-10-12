local M = {}

local TEST_TMPDIR = os.getenv('TEST_TMPDIR')
--local TEST_TMPDIR = "/tmp/foo"

---@class pesto.XdgDirs
---@field xdg_config string
---@field xdg_state string
---@field xdg_home string

function M.set_up_repo_fixture(repo_runfile_path)
  local run_files = require('rules_nvim_lua.runfiles')
  local bazel_repo_dir = run_files.rlocation(repo_runfile_path)

  local fs_util = require('pesto.util.fs_util')
  fs_util.copy_dir(bazel_repo_dir, TEST_TMPDIR)

  return vim.fs.joinpath(TEST_TMPDIR, vim.fs.basename(bazel_repo_dir))
end

function M.set_up_plugin()
  local run_files = require('rules_nvim_lua.runfiles')
  local xdg = run_files.rlocation('xdg')

  local fs_util = require('pesto.util.fs_util')
  fs_util.copy_dir(xdg, TEST_TMPDIR)

  local xdg_config = vim.fs.joinpath(TEST_TMPDIR, 'xdg/local/config')
  local xdg_state = vim.fs.joinpath(TEST_TMPDIR, 'xdg/local/state')
  local xdg_home = vim.fs.joinpath(TEST_TMPDIR, 'xdg/local/share')

  return {
    xdg_config = xdg_config,
    xdg_state = xdg_state,
    xdg_home = xdg_home,
  }
end

return M
