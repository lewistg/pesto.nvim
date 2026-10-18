describe('load-quickfix subcommand', function()
  local nvim_chan

  ---@type string
  local nvim_bin

  ---@type table
  local job_opts

  ---@type string
  local fixture_repo

  ---@type pesto.FunctionalTestHelper
  local functional_test_helper

  setup(function()
    local run_files = require('rules_nvim_lua.runfiles')

    nvim_bin = run_files.rlocation('nvim/bin/nvim')

    local functional_test_setup = require('pesto.test.functional_test_setup')

    fixture_repo =
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

  it('load-quickfix loads the quickfix list', function()
    local bep_json_file = vim.fn.tempname() .. '.json'
    -- Note: hello-error/main.c has an  error
    local system_completed = vim
      .system({ 'bazel', 'build', '//hello-error:main', '--build_event_json_file', bep_json_file }, {
        cwd = fixture_repo,
      })
      :wait()
    assert.is_true(system_completed.code == 1)
    assert.truthy(vim.uv.fs_stat(bep_json_file))

    local subcommand = { 'load-quickfix', bep_json_file }
    vim.rpcrequest(nvim_chan, 'nvim_cmd', { cmd = 'Pesto', args = subcommand }, {})

    local wait_status = vim.wait(1000 * 10, function()
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
