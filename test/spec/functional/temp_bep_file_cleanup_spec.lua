describe('default runner temp BEP file cleanup', function()
  ---@type integer
  local nvim_chan

  ---@type number
  local BUILD_TIMEOUT = 60 * 1000

  ---@type pesto.FunctionalTestHelper
  local functional_test_helper

  setup(function()
    local run_files = require('rules_nvim_lua.runfiles')

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

    local nvim_bin = run_files.rlocation('nvim/bin/nvim')
    nvim_chan = vim.fn.jobstart({ nvim_bin, '--embed', '--headless' }, job_opts)
    functional_test_helper = require('pesto.test.functional_test_helper'):new(nvim_chan)
  end)

  teardown(function()
    vim.fn.jobstop(nvim_chan)
  end)

  ---@param temp_bep_dir string
  local function get_num_bep_files(temp_bep_dir)
    local file_count = 0
    vim.fs.find(function(name, _)
      file_count = file_count + 1
    end, { limit = math.huge, type = 'file', path = temp_bep_dir })
    return file_count
  end

  it('automatically deletes old BEP log files', function()
    local DefaultRunner = require('pesto.runner.default.default_runner')

    local temp_dir = functional_test_helper:get_temp_dir()
    local temp_bep_dir = vim.fs.joinpath(temp_dir, 'bep')

    local function build()
      vim.rpcrequest(nvim_chan, 'nvim_cmd', { cmd = 'edit', args = { 'hello-world/main.c' } }, {})
      vim.rpcrequest(nvim_chan, 'nvim_cmd', { cmd = 'Pesto', args = { 'build' } }, {})
      functional_test_helper:wait_for_build(BUILD_TIMEOUT)
    end

    for build_count = 1, DefaultRunner.TEMP_BEP_FILE_CLEANUP_INTERVAL - 1 do
      build()
      local file_count = get_num_bep_files(temp_bep_dir)
      assert.are.same(build_count, file_count)
    end

    build()
    local file_count = get_num_bep_files(temp_bep_dir)
    assert.are.same(DefaultRunner.MAX_TEMP_BEP_FILES_TO_KEEP, file_count)
  end)
end)
