describe('load-quickfix subcommand', function()
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

  it('load-quickfix loads the quickfix list', function()
    local bep_json_file = vim.fn.tempname() .. '.json'
    -- Note: hello-error/main.c has an  error
    local system_completed = vim
      .system({ 'bazel', 'build', '//hello-error:main', '--build_event_json_file', bep_json_file }, {
        cwd = fixture_root,
      })
      :wait()
    assert.is_true(system_completed.code == 1)
    assert.truthy(vim.uv.fs_stat(bep_json_file))

    local subcommand = { 'load-quickfix', bep_json_file }
    vim.rpcrequest(nvim_chan, 'nvim_cmd', { cmd = 'Pesto', args = subcommand }, {})

    local wait_status = vim.wait(1000 * 5, function()
      local buf_id = functional_test_helper:get_quickfix_buf_id()
      return buf_id ~= vim.NIL
    end)
    assert.is_true(wait_status)

    local quickfix_items = functional_test_helper:get_jumpable_quickfix_items()
    assert.is_true(#quickfix_items > 0)

    local qf_line_index = quickfix_items[1].line_index
    local qf_item = quickfix_items[1].qf_item

    functional_test_helper:jump_via_quickfix_item(qf_line_index)

    local curr_buf_id = vim.rpcrequest(nvim_chan, 'nvim_get_current_buf')
    assert.are.same(curr_buf_id, qf_item.bufnr)
  end)
end)
