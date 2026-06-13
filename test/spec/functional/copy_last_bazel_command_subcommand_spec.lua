describe('copy-last-bazel-command', function()
  local nvim_chan
  local busted_fixtures = require('busted.fixtures')
  local env_vars = vim.fn.environ()
  local fixture_root = busted_fixtures.path('bazel_repo_fixture')
  local job_opts = {
    rpc = true,
    cwd = fixture_root,
    env = {
      XDG_CONFIG_HOME = env_vars['XDG_CONFIG_HOME'],
      XDG_STATE_HOME = env_vars['XDG_STATE_HOME'],
      XDG_DATA_HOME = env_vars['XDG_DATA_HOME'],
    },
  }

  ---@type pesto.FunctionalTestHelper
  local functional_test_helper

  before_each(function()
    nvim_chan = vim.fn.jobstart({ 'nvim', '--embed', '--headless' }, job_opts)
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
