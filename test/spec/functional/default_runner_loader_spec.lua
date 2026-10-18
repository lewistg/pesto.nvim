describe('default runner loader', function()
  ---@type integer
  local nvim_chan

  ---@type string
  local nvim_bin

  ---@type table
  local job_opts

  local ENTER_KEY = vim.api.nvim_replace_termcodes('<CR>', true, false, true)

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

  local function quickfix_window_test(bep_integration)
    functional_test_helper:set_config_enable_bep_integration(bep_integration)

    -- Note: hello-error/main.c has an  error
    vim.rpcrequest(nvim_chan, 'nvim_cmd', { cmd = 'edit', args = { 'hello-error/main.c' } }, {})

    local error_source_file_buf_id = vim.rpcrequest(nvim_chan, 'nvim_get_current_buf')
    local original_win_id = vim.rpcrequest(nvim_chan, 'nvim_get_current_win')

    vim.rpcrequest(nvim_chan, 'nvim_cmd', { cmd = 'Pesto', args = { 'compile-one-dep' } }, {})

    -- Build should finish successfully
    local exit_code = functional_test_helper:wait_for_build(60 * 1000)
    assert.are.same(0, exit_code)

    -- Eventually the quickfix window should be opened
    local wait_status = vim.fn.wait(5 * 1000, function()
      local current_tab_page_id = vim.rpcrequest(nvim_chan, 'nvim_get_current_tabpage')
      local tabpage_win_ids =
        vim.rpcrequest(nvim_chan, 'nvim_tabpage_list_wins', current_tab_page_id)

      return vim.iter(tabpage_win_ids):any(function(win_id)
        local win_info =
          vim.rpcrequest(nvim_chan, 'nvim_call_function', 'getwininfo', { win_id })[1]
        local is_quickfix = vim.tbl_get(win_info or {}, 'quickfix')
        return is_quickfix == 1
      end)
    end)
    assert.are.same(0, wait_status)

    -- Test quickfix navigation by making sure it jumps to the error
    local quickfix_items = functional_test_helper:get_jumpable_quickfix_items()
    assert.is_true(#quickfix_items > 0)

    local qf_line_index = quickfix_items[1].line_index
    local qf_item = quickfix_items[1].qf_item

    -- We open a separate window to observe the the navigation back to the original source file
    vim.rpcrequest(nvim_chan, 'nvim_set_current_win', original_win_id)
    vim.rpcrequest(nvim_chan, 'nvim_cmd', { cmd = 'edit', args = { 'hello-error/BUILD' } }, {})

    functional_test_helper:jump_via_quickfix_item(qf_line_index)

    -- Confirm the jump
    local current_buf_id = vim.rpcrequest(nvim_chan, 'nvim_get_current_buf')
    assert.are.same(error_source_file_buf_id, current_buf_id)
  end

  it('loads errors into the quickfix window when BEP log is the quickfix source', function()
    quickfix_window_test(true)
  end)

  it(
    'loads errors into the quickfix window when the bazel progress output is the quickfix source',
    function()
      quickfix_window_test(false)
    end
  )

  it('the Bazel output window can be closed by with <CR>', function()
    vim.rpcrequest(nvim_chan, 'nvim_cmd', { cmd = 'edit', args = { 'hello-error/main.c' } }, {})

    vim.rpcrequest(nvim_chan, 'nvim_cmd', { cmd = 'Pesto', args = { 'compile-one-dep' } }, {})

    ---@type number|nil
    local build_win_id
    vim.fn.wait(1000, function()
      build_win_id = functional_test_helper:find_build_windows(0)[1]
      return build_win_id ~= nil
    end)
    assert.truthy(build_win_id)

    functional_test_helper:wait_for_build(120 * 1000)

    -- Build window should close on <CR>
    vim.rpcrequest(nvim_chan, 'nvim_feedkeys', ENTER_KEY, 't', false)
    local wait_status = vim.fn.wait(1000, function()
      local build_win_ids = functional_test_helper:find_build_windows(0)
      return #build_win_ids == 0
    end)
    assert.is_true(wait_status == 0, 'Bazel output build window did not close')
  end)
end)
