describe('find_option', function()
  ---@type pesto.BazelOptionSpec
  local async_option_spec = {
    long_name = 'async',
    is_boolean = true,
  }
  local keep_going_option_spec = {
    long_name = 'keep_going',
    short_name = 'k',
    is_boolean = true,
  }

  ---@type {name: string, bazel_command: string[], option_spec: pesto.BazelOptionSpec, expected_result: pesto.FindBazelOptionResult|nil}[]
  local test_cases = {
    {
      name = 'simple binary',
      bazel_command = { 'bazel', 'clean', '--async' },
      option_spec = async_option_spec,
      expected_result = {
        name = 'async',
      },
    },
    {
      name = "simple binary prefixed with 'no'",
      bazel_command = { 'bazel', 'clean', '--noasync' },
      option_spec = async_option_spec,
      expected_result = {
        name = 'async',
        value = 'no',
      },
    },
    {
      name = 'simple short',
      bazel_command = { 'bazel', 'build', '-k' },
      option_spec = keep_going_option_spec,
      expected_result = {
        name = 'k',
      },
    },
  }

  for _, test_case in ipairs(test_cases) do
    it(string.format('correctly finds command (test case: %s)', test_case.name), function()
      local bazel_command = require('pesto.bazel.bazel_command')
      local result = bazel_command.find_option(test_case.bazel_command, test_case.option_spec)
      assert.are.same(test_case.expected_result, result)
    end)
  end
end)

describe('inject_bep_option', function()
  local temp_file = '/tmp/pesto.nvim/temp-123-bep.json'
  local lazy_temp_file = function()
    return temp_file
  end

  ---@type {bazel_command: string[], expected_bazel_command: string[]}[]
  local test_cases = {
    {
      bazel_command = { 'bazel' },
      expected_bazel_command = { 'bazel' },
    },
    {
      bazel_command = { 'bazel', 'build' },
      expected_bazel_command = { 'bazel', 'build', '--build_event_json_file', temp_file },
    },
    {
      bazel_command = { 'bazel', 'build', '//foo/bar/baz' },
      expected_bazel_command = {
        'bazel',
        'build',
        '--build_event_json_file',
        temp_file,
        '//foo/bar/baz',
      },
    },
    {
      bazel_command = { 'bazel', 'test', '//foo/bar/baz' },
      expected_bazel_command = {
        'bazel',
        'test',
        '--build_event_json_file',
        temp_file,
        '//foo/bar/baz',
      },
    },
    {
      bazel_command = { 'bazel', 'run', '//foo/bar/baz' },
      expected_bazel_command = {
        'bazel',
        'run',
        '--build_event_json_file',
        temp_file,
        '//foo/bar/baz',
      },
    },
    {
      bazel_command = { 'bazel', 'query', '//foo/bar/baz:*' },
      expected_bazel_command = {
        'bazel',
        'query',
        '//foo/bar/baz:*',
      },
    },
  }

  for _, test_case in ipairs(test_cases) do
    local bazel_command_str = table.concat(test_case.bazel_command, ' ')
    it(string.format('handles bazel command: %s', bazel_command_str), function()
      local bazel_command = require('pesto.bazel.bazel_command')
      bazel_command.inject_bep_option(test_case.bazel_command, lazy_temp_file)
      assert.are.same(test_case.expected_bazel_command, test_case.bazel_command)
    end)
  end
end)
