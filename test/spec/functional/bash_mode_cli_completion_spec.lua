describe("CLI completion with 'bash' mode", function()
  local nvim_chan
  local run_files = require('rules_nvim_lua.runfiles')

  local bazel_repo_dir = run_files.rlocation('_main/test/spec/functional/bazel_repo_fixture')

  local job_opts = {
    rpc = true,
    cwd = bazel_repo_dir,
    env = {
      XDG_CONFIG_HOME = run_files.rlocation('xdg/local/config'),
      XDG_STATE_HOME = run_files.rlocation('xdg/local/state'),
      XDG_DATA_HOME = run_files.rlocation('xdg/local/share'),
    },
  }

  local ESCAPE_KEY = vim.api.nvim_replace_termcodes('<Esc>', true, false, true)
  local TAB_KEY = vim.api.nvim_replace_termcodes('<Tab>', true, false, true)

  ---@type pesto.FunctionalTestHelper
  local functional_test_helper

  local NVIM_BIN = run_files.rlocation('nvim/bin/nvim')

  setup(function()
    nvim_chan = vim.fn.jobstart({ NVIM_BIN, '--embed', '--headless' }, job_opts)
    functional_test_helper = require('pesto.test.functional_test_helper'):new(nvim_chan)
    functional_test_helper:set_completion_mode('bash')
  end)

  teardown(function()
    vim.fn.jobstop(nvim_chan)
  end)

  before_each(function()
    -- Clear out autocomplete
    vim.rpcrequest(nvim_chan, 'nvim_feedkeys', ESCAPE_KEY, 't', false)
  end)

  ---@type {prefix_keys: string, expected_command_line: string, expected_completions: string[], open_file: string|nil}[]
  local test_cases = {
    {
      prefix_keys = 'Pes',
      expected_command_line = 'Pesto',
      expected_completions = {},
    },
    {
      prefix_keys = 'Pesto bazel ',
      expected_command_line = 'Pesto bazel analyze-profile ',
      expected_completions = { 'build', 'run', 'test' },
    },
    {
      prefix_keys = 'Pesto bazel build //',
      expected_command_line = 'Pesto bazel build //:',
      expected_completions = {
        '//:',
        '//bar/',
        '//bar:',
        '//baz/',
        '//baz:',
        '//foo/',
        '//foo:',
      },
    },
    {
      prefix_keys = 'Pesto bazel build //foo/',
      expected_command_line = 'Pesto bazel build //foo/foo1/',
      expected_completions = {
        '//foo/foo1/',
        '//foo/foo1:',
      },
    },
    {
      open_file = 'foo/foo1/foo2/foo3/foo1.sh',
      prefix_keys = 'Pesto bazel build :',
      expected_command_line = 'Pesto bazel build :foo1 ',
      expected_completions = {
        '//foo/foo1/',
        '//foo/foo1:',
      },
    },
    {
      open_file = 'foo/foo1/foo2/foo3/foo1.sh',
      prefix_keys = 'Pesto bazel build //foo/foo1/foo2/foo3:',
      expected_command_line = 'Pesto bazel build //foo/foo1/foo2/foo3:foo1 ',
      expected_completions = {
        '//foo/foo1/foo2/foo3:foo1',
        '//foo/foo1/foo2/foo3:foo1_spec',
        '//foo/foo1/foo2/foo3:foo2',
        '//foo/foo1/foo2/foo3:foo3',
      },
    },
  }

  for i, test_case in ipairs(test_cases) do
    it('CLI completion test #' .. i, function()
      if test_case.open_file then
        vim.rpcrequest(nvim_chan, 'nvim_cmd', { cmd = 'edit', args = { test_case.open_file } }, {})
      end
      vim.rpcrequest(nvim_chan, 'nvim_feedkeys', ':' .. test_case.prefix_keys, 't', false)
      vim.rpcrequest(nvim_chan, 'nvim_feedkeys', TAB_KEY, 't', false)

      vim.wait(1000, function()
        local command_line = vim.rpcrequest(nvim_chan, 'nvim_call_function', 'getcmdline', {})
        return test_case.expected_command_line == command_line
      end)

      local command_line = vim.rpcrequest(nvim_chan, 'nvim_call_function', 'getcmdline', {})
      assert.are.same(test_case.expected_command_line, command_line)
    end)
  end
end)
