describe('copy-last-bazel-command', function()
  ---@type integer
  local nvim_chan

  ---@type string
  local nvim_bin

  ---@type table
  local job_opts

  ---@type pesto.FunctionalTestHelper
  local functional_test_helper

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
  end)

  after_each(function()
    vim.fn.jobstop(nvim_chan)
  end)

  it('copy-last-bazel-command yanks the last run Bazel command to "" and "+', function()
    vim.rpcrequest(nvim_chan, 'nvim_cmd', { cmd = 'edit', args = { 'hello-world/main.c' } }, {})

    local subcommand = { 'build' }
    vim.rpcrequest(nvim_chan, 'nvim_cmd', { cmd = 'Pesto', args = subcommand }, {})
    functional_test_helper:wait_for_build(10 * 1000)

    vim.rpcrequest(
      nvim_chan,
      'nvim_cmd',
      { cmd = 'Pesto', args = { 'copy-last-bazel-command' } },
      {}
    )

    local expected_command_pattern =
      '(cd [^%s]*/bazel_repo_fixture/hello%-world && bazel build //hello%-world:all)'

    local plus_reg = vim.rpcrequest(nvim_chan, 'nvim_call_function', 'getreg', { '+' }) or ''
    local unnnamed_reg = vim.rpcrequest(nvim_chan, 'nvim_call_function', 'getreg', { '"' }) or ''

    assert.truthy(string.match(plus_reg, expected_command_pattern))
    assert.truthy(string.match(unnnamed_reg, expected_command_pattern))
  end)
end)
