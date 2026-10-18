describe('default runner loader', function()
  local nvim_chan

  ---@type pesto.FunctionalTestHelper
  local functional_test_helper

  local TEST_TMPDIR = '/tmp/foo' -- os.getenv('TEST_TMPDIR')

  local function setup_test_repo()
    local run_files = require('rules_nvim_lua.runfiles')
    local bazel_repo_dir = run_files.rlocation('_main/test/spec/functional/bazel_repo_fixture')

    local fs_util = require('pesto.util.fs_util')
    fs_util.copy_dir(bazel_repo_dir, TEST_TMPDIR)

    return vim.fs.joinpath(TEST_TMPDIR, vim.fs.basename(bazel_repo_dir))
  end

  local function set_up_plugin()
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

  setup(function()
    local xdg_home_dirs = set_up_plugin()

    local test_repo_dir = setup_test_repo()

    local job_opts = {
      rpc = true,
      cwd = test_repo_dir,
      env = {
        XDG_CONFIG_HOME = xdg_home_dirs.xdg_config,
        XDG_STATE_HOME = xdg_home_dirs.xdg_state,
        XDG_DATA_HOME = xdg_home_dirs.xdg_home,
      },
    }

    local run_files = require('rules_nvim_lua.runfiles')
    local NVIM_BIN = run_files.rlocation('nvim/bin/nvim')
    nvim_chan = vim.fn.jobstart({ NVIM_BIN, '--embed', '--headless' }, job_opts)

    functional_test_helper = require('pesto.test.functional_test_helper'):new(nvim_chan)
  end)

  teardown(function()
    vim.fn.jobstop(nvim_chan)
  end)

  it('installs the Bazel remote APIs helpers', function()
    assert.is_false(functional_test_helper:are_remote_apis_helpers_installed())
    vim.rpcrequest(nvim_chan, 'nvim_exec2', ':Pesto install-remote-apis-helpers', {})
    assert.is_true(functional_test_helper:are_remote_apis_helpers_installed())
  end)
end)
