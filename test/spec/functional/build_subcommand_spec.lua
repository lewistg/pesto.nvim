describe('build subcommand', function()
  local nvim_chan
  local busted_fixtures = require('busted.fixtures')
  local bazel_repo_dir = busted_fixtures.path('bazel_repo_fixture')
  local env_vars = vim.fn.environ()
  local job_opts = {
    rpc = true,
    cwd = bazel_repo_dir,
    env = {
      XDG_CONFIG_HOME = env_vars['XDG_CONFIG_HOME'],
      XDG_STATE_HOME = env_vars['XDG_STATE_HOME'],
      XDG_DATA_HOME = env_vars['XDG_DATA_HOME'],
    },
  }

  ---@type pesto.FunctionalTestHelper
  local functional_test_helper

  ---@type pesto.BuildWindowTestHelper
  local build_window_test_helper

  before_each(function()
    nvim_chan = vim.fn.jobstart({ 'nvim', '--embed', '--headless' }, job_opts)
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
end)
