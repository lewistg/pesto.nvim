describe('test subcommand', function()
  local nvim_chan

  ---@type pesto.FunctionalTestHelper
  local functional_test_helper

  ---@type pesto.BuildWindowTestHelper
  local build_window_test_helper

  before_each(function()
    local run_files = require('rules_nvim_lua.runfiles')
    local nvim_bin = run_files.rlocation('nvim/bin/nvim')

    local functional_test_setup = require('pesto.test.functional_test_setup')
    local fixture_repo =
      functional_test_setup.set_up_repo_fixture('_main/test/spec/functional/bazel_repo_fixture')
    local xdg_dirs = functional_test_setup.set_up_plugin()

    local job_opts = {
      rpc = true,
      cwd = fixture_repo,
      env = {
        XDG_CONFIG_HOME = xdg_dirs.xdg_config,
        XDG_STATE_HOME = xdg_dirs.xdg_state,
        XDG_DATA_HOME = xdg_dirs.xdg_home,
      },
    }

    nvim_chan = vim.fn.jobstart({ nvim_bin, '--embed', '--headless' }, job_opts)
    functional_test_helper = require('pesto.test.functional_test_helper'):new(nvim_chan)
    build_window_test_helper =
      require('pesto.test.build_window_test_helper'):new(nvim_chan, functional_test_helper)
  end)

  after_each(function()
    vim.fn.jobstop(nvim_chan)
  end)

  it('runs the tests', function()
    vim.rpcrequest(
      nvim_chan,
      'nvim_cmd',
      { cmd = 'edit', args = { 'java/src/test/java/com/example/ExampleTest.java' } },
      {}
    )

    local subcommand = { 'test' }
    vim.rpcrequest(nvim_chan, 'nvim_cmd', { cmd = 'Pesto', args = subcommand }, {})

    build_window_test_helper:verify_build_window_opens()
  end)
end)
