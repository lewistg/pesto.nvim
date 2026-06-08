describe('find_option', function()
  ---@type pesto.BazelOptionSpec
  local keep_going_option_spec = {
    long_name = 'keep_going',
    short_name = 'k',
    category = 'build',
    is_boolean = true,
  }

  local bazel_command = require('pesto.bazel.bazel_command')

  ---@type {name: string, bazel_command: string[], option_spec: pesto.BazelOptionSpec, expected_result: pesto.FindBazelOptionResult|nil}[]
  local test_cases = {
    {
      name = 'simple binary',
      bazel_command = { 'bazel', 'clean', '--async' },
      option_spec = bazel_command.ASYNC_OPTION_SPEC,
      expected_result = {
        name = 'async',
      },
    },
    {
      name = "simple binary prefixed with 'no'",
      bazel_command = { 'bazel', 'clean', '--noasync' },
      option_spec = bazel_command.ASYNC_OPTION_SPEC,
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
    {
      name = 'finds async clean option',
      bazel_command = { 'bazel', 'clean', '--async=yes' },
      option_spec = bazel_command.ASYNC_OPTION_SPEC,
      expected_result = {
        name = 'async',
        value = 'yes',
      },
    },
  }

  for _, test_case in ipairs(test_cases) do
    it(string.format('correctly finds command (test case: %s)', test_case.name), function()
      local result = bazel_command.find_option(test_case.bazel_command, test_case.option_spec)
      assert.are.same(test_case.expected_result, result)
    end)
  end
end)

describe('inject_option', function()
  local temp_file = '/tmp/pesto.nvim/temp-123-bep.json'

  local bazel_command = require('pesto.bazel.bazel_command')

  ---@type {name: string, bazel_command: string[], option_spec: pesto.BazelOptionSpec, value: string, expected_bazel_command: string[], expected_injection_result: pesto.OptionInjectionResult|nil}[]
  local test_cases = {
    {
      name = 'should not inject a non-startup option',
      bazel_command = { 'bazel' },
      option_spec = bazel_command.BUILD_EVENT_JSON_FILE_OPTION_SPEC,
      value = temp_file,
      expected_bazel_command = { 'bazel' },
      expected_injection_result = nil,
    },
    {
      name = 'can inject a build option',
      bazel_command = { 'bazel', 'build' },
      option_spec = bazel_command.BUILD_EVENT_JSON_FILE_OPTION_SPEC,
      value = temp_file,
      expected_bazel_command = { 'bazel', 'build', '--build_event_json_file', temp_file },
      expected_injection_result = {
        option_value = temp_file,
        was_injected = true,
      },
    },
    {
      name = 'can inject a build option when a target is already specified',
      bazel_command = { 'bazel', 'build', '//foo/bar/baz' },
      option_spec = bazel_command.BUILD_EVENT_JSON_FILE_OPTION_SPEC,
      value = temp_file,
      expected_bazel_command = {
        'bazel',
        'build',
        '--build_event_json_file',
        temp_file,
        '//foo/bar/baz',
      },
      expected_injection_result = {
        option_value = temp_file,
        was_injected = true,
      },
    },
    {
      name = 'can inject a build option into a test command',
      bazel_command = { 'bazel', 'test', '//foo/bar/baz' },
      option_spec = bazel_command.BUILD_EVENT_JSON_FILE_OPTION_SPEC,
      value = temp_file,
      expected_bazel_command = {
        'bazel',
        'test',
        '--build_event_json_file',
        temp_file,
        '//foo/bar/baz',
      },
      expected_injection_result = {
        option_value = temp_file,
        was_injected = true,
      },
    },
    {
      name = 'can inject a build option into a run command',
      bazel_command = { 'bazel', 'run', '//foo/bar/baz' },
      option_spec = bazel_command.BUILD_EVENT_JSON_FILE_OPTION_SPEC,
      value = temp_file,
      expected_bazel_command = {
        'bazel',
        'run',
        '--build_event_json_file',
        temp_file,
        '//foo/bar/baz',
      },
      expected_injection_result = {
        option_value = temp_file,
        was_injected = true,
      },
    },
    {
      name = 'can inject a startup option into a command that already has a sub-command',
      bazel_command = { 'bazel', 'query', '//foo/bar/baz:*' },
      option_spec = {
        long_name = 'max_idel_secs',
        has_value = true,
        category = 'startup',
      },
      value = '10800',
      expected_bazel_command = {
        'bazel',
        '--max_idel_secs',
        '10800',
        'query',
        '//foo/bar/baz:*',
      },
      expected_injection_result = {
        option_value = '10800',
        was_injected = true,
      },
    },
    {
      name = 'does not override an existing option',
      bazel_command = { 'bazel', 'clean', '--async=yes' },
      option_spec = bazel_command.ASYNC_OPTION_SPEC,
      value = 'no',
      expected_bazel_command = {
        'bazel',
        'clean',
        '--async=yes',
      },
      --- Injection should not override the existing option
      expected_injection_result = {
        option_value = 'yes',
        was_injected = false,
      },
    },
  }

  for _, test_case in ipairs(test_cases) do
    local bazel_command_str = table.concat(test_case.bazel_command, ' ')
    it(test_case.name, function()
      local result = bazel_command.inject_option(
        test_case.bazel_command,
        test_case.option_spec,
        function()
          return test_case.value
        end
      )
      assert.are.same(test_case.expected_injection_result, result)
      assert.are.same(test_case.expected_bazel_command, test_case.bazel_command)
    end)
  end
end)
