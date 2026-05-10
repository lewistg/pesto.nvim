describe('default runner temp BEP file cleanup', function()
  local nvim_chan
  local busted_fixtures = require('busted.fixtures')
  local env_vars = vim.fn.environ()
  local job_opts = {
    rpc = true,
    cwd = busted_fixtures.path('bazel_repo_fixture'),
    env = {
      XDG_CONFIG_HOME = env_vars['XDG_CONFIG_HOME'],
      XDG_STATE_HOME = env_vars['XDG_STATE_HOME'],
      XDG_DATA_HOME = env_vars['XDG_DATA_HOME'],
    },
  }

  ---@type number
  local BUILD_TIMEOUT = 10 * 1000

  ---@type pesto.FunctionalTestHelper
  local functional_test_helper

  setup(function()
    nvim_chan = vim.fn.jobstart({ 'nvim', '--embed', '--headless' }, job_opts)
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
