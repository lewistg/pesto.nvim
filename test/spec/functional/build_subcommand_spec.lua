describe('build subcommand', function()
  ---@type integer
  local nvim_chan

  ---@type string
  local nvim_bin

  ---@type table
  local job_opts

  ---@type pesto.FunctionalTestHelper
  local functional_test_helper

  ---@type pesto.BuildWindowTestHelper
  local build_window_test_helper

  setup(function()
    local run_files = require('rules_nvim_lua.runfiles')
    nvim_bin = run_files.rlocation('nvim/bin/nvim')

    local functional_test_setup = require('pesto.test.functional_test_setup')
    local fixture_repo =
      functional_test_setup.set_up_repo_fixture('_main/test/spec/functional/bazel_repo_fixture')
    local xdg_dirs = functional_test_setup.set_up_plugin()

    job_opts = {
      rpc = true,
      cwd = fixture_repo,
      env = {
        XDG_CONFIG_HOME = xdg_dirs.xdg_config,
        XDG_STATE_HOME = xdg_dirs.xdg_state,
        XDG_DATA_HOME = xdg_dirs.xdg_home,
      },
    }
  end)

  before_each(function()
    nvim_chan = vim.fn.jobstart({ nvim_bin, '--embed', '--headless' }, job_opts)
    functional_test_helper = require('pesto.test.functional_test_helper'):new(nvim_chan)
    build_window_test_helper =
      require('pesto.test.build_window_test_helper'):new(nvim_chan, functional_test_helper)
  end)

  after_each(function()
    vim.fn.jobstop(nvim_chan)
  end)

  it('builds the targets for the package associated with the current file', function()
    vim.rpcrequest(nvim_chan, 'nvim_cmd', { cmd = 'edit', args = { 'hello-world/main.c' } }, {})

    local subcommand = { 'build' }
    vim.rpcrequest(nvim_chan, 'nvim_cmd', { cmd = 'Pesto', args = subcommand }, {})

    build_window_test_helper:verify_build_window_opens()
  end)

  it('builds the targets when an explicit resolver ID is given', function()
    vim.rpcrequest(
      nvim_chan,
      'nvim_cmd',
      { cmd = 'edit', args = { 'java/src/main/java/com/example/Main.java' } },
      {}
    )

    local subcommand = { 'build', 'all' }
    vim.rpcrequest(nvim_chan, 'nvim_cmd', { cmd = 'Pesto', args = subcommand }, {})

    build_window_test_helper:verify_build_window_opens()
  end)
end)
