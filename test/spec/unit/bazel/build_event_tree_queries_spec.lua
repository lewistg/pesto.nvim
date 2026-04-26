describe('pesto.BuildEventTreeQueries', function()
  local busted_fixtures = require('busted.fixtures')
  local bazel_repo_dir = busted_fixtures.path('build_event_tree_spec_fixtures')
  local broken_build_remote_cache_bep_path =
    vim.fs.joinpath(bazel_repo_dir, 'broken-build-remote-cache-bep.json')
  local broken_scala_build_bep_path = vim.fs.joinpath(bazel_repo_dir, 'broken-scala-build-bep.json')

  it('pesto.BuildEventTree:find_command_line_option finds command line options', function()
    local bep_json_loader = require('pesto.bazel.build_event_json_loader'):new()
    local bep_tree = bep_json_loader:load(broken_build_remote_cache_bep_path)

    local BuildEventTreeQueries = require('pesto.bazel.build_event_tree_queries')
    local bep_tree_queries = BuildEventTreeQueries:new(bep_tree)

    local remote_cache_option =
      bep_tree_queries:find_command_line_option('canonical', 'remote_cache')[1]

    assert.is_equal('grpc://localhost:8980', remote_cache_option.option_value)
  end)

  it(
    'pesto.BuildEventTree:find_command_line_option finds all options when there are multiple',
    function()
      local bep_json_loader = require('pesto.bazel.build_event_json_loader'):new()
      local bep_tree = bep_json_loader:load(broken_build_remote_cache_bep_path)

      local BuildEventTreeQueries = require('pesto.bazel.build_event_tree_queries')
      local bep_tree_queries = BuildEventTreeQueries:new(bep_tree)

      local remote_header_options =
        bep_tree_queries:find_command_line_option('canonical', 'remote_header')
      local key_values = vim
        .iter(remote_header_options)
        :map(function(option)
          return { option['option_name'], option['option_value'] }
        end)
        :totable()

      table.sort(key_values, function(item1, item2)
        return item1[2] < item2[2]
      end)

      assert.are.same(
        { { 'remote_header', 'baz=qux' }, { 'remote_header', 'foo=bar' } },
        key_values
      )
    end
  )

  it(
    'pesto.BuildEventTreeQueries:find_failed_action_logs returns the failed action log URIs',
    function()
      local bep_json_loader = require('pesto.bazel.build_event_json_loader'):new()
      local bep_tree = bep_json_loader:load(broken_scala_build_bep_path)

      local BuildEventTreeQueries = require('pesto.bazel.build_event_tree_queries')
      local bep_tree_queries = BuildEventTreeQueries:new(bep_tree)

      local failed_action_logs = bep_tree_queries:find_failed_action_logs()

      local expected_action_logs = {
        ['scala_binary'] = {
          ['Scalac'] = {
            'file:///home/foo/.cache/bazel/_bazel_foo/881c0a1d696f65d91fc6329b424aec0b/execroot/_main/bazel-out/_tmp/actions/stderr-2',
          },
        },
      }

      assert.are.same(expected_action_logs, failed_action_logs)
    end
  )
end)
