describe('inject_bep_option', function()
  local temp_file = '/tmp/pesto.nvim/temp-123-bep.json'
  local lazy_temp_file = function()
    return temp_file
  end

  ---@type {bazel_command: string[], expected_bazel_command: string[]}
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
      local bazel_build_event_util = require('pesto.bazel.bazel_command')
      bazel_build_event_util.inject_bep_option(test_case.bazel_command, lazy_temp_file)
      assert.are.same(test_case.expected_bazel_command, test_case.bazel_command)
    end)
  end
end)
