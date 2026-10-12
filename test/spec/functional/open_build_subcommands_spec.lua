describe('open BUILD file subcommands', function()
  ---@type integer
  local nvim_chan
  ---@type pesto.XdgDirs
  local xdg_dirs
  ---@type string
  local nvim_bin
  ---@type string
  local fixture_repo

  setup(function()
    local functional_test_setup = require('pesto.test.functional_test_setup')
    fixture_repo =
      functional_test_setup.set_up_repo_fixture('_main/test/spec/functional/bazel_repo_fixture')
    xdg_dirs = functional_test_setup.set_up_plugin()

    local run_files = require('rules_nvim_lua.runfiles')
    nvim_bin = run_files.rlocation('nvim/bin/nvim')
  end)

  before_each(function()
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
  end)

  after_each(function()
    vim.fn.jobstop(nvim_chan)
  end)

  ---@param subcommand "sp-build"|"vs-build"
  local function split_command_test(subcommand)
    local source_file_relative_path = 'foo/foo1/foo2/foo3/foo3.sh'

    vim.rpcrequest(
      nvim_chan,
      'nvim_cmd',
      { cmd = 'edit', args = { source_file_relative_path } },
      {}
    )
    vim.rpcrequest(nvim_chan, 'nvim_cmd', { cmd = 'Pesto', args = { subcommand } }, {})

    local curr_tab_page_nr = vim.rpcrequest(nvim_chan, 'nvim_call_function', 'tabpagenr', { '$' })
    local tab_info =
      vim.rpcrequest(nvim_chan, 'nvim_call_function', 'gettabinfo', { curr_tab_page_nr })

    -- There should be two windows open now
    assert.are.same(2, #tab_info[1].windows)

    local tab_win_infos = vim.tbl_map(function(win_id)
      return vim.rpcrequest(nvim_chan, 'nvim_call_function', 'getwininfo', { win_id })[1]
    end, tab_info[1].windows)

    -- Sorted left to right, top to bottom
    table.sort(tab_win_infos, function(win_info_a, win_info_b)
      if win_info_a.wincol ~= win_info_b.wincol then
        return win_info_a.wincol < win_info_b.wincol
      else
        return win_info_a.winrow < win_info_b.winrow
      end
    end)

    -- The windows should be side-by-side
    if subcommand == 'sp-build' then
      assert.are.same(tab_win_infos[1].wincol, tab_win_infos[2].wincol)
    else
      assert.are.same(tab_win_infos[1].winrow, tab_win_infos[2].winrow)
    end

    local left_buf_info =
      vim.rpcrequest(nvim_chan, 'nvim_call_function', 'getbufinfo', { tab_win_infos[1].bufnr })[1]

    local right_buf_info =
      vim.rpcrequest(nvim_chan, 'nvim_call_function', 'getbufinfo', { tab_win_infos[2].bufnr })[1]

    local build_file_path = vim.fs.joinpath(fixture_repo, 'foo/foo1/foo2/foo3/BUILD')
    assert.are.same(tostring(build_file_path), left_buf_info.name)

    local source_file_path = vim.fs.joinpath(fixture_repo, source_file_relative_path)
    assert.are.same(tostring(source_file_path), right_buf_info.name)
  end

  it("sp-build opens the source file's corresponding BUILD file", function()
    split_command_test('sp-build')
  end)

  it("vs-build opens the source file's corresponding BUILD file", function()
    split_command_test('vs-build')
  end)
end)
