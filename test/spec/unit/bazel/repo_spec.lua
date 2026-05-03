describe('bazel_repo.get_package_label', function()
  local busted_fixtures = require('busted.fixtures')
  local bazel_repo_dir = busted_fixtures.path('repo_spec_example_repo_fixture')

  teardown(function()
    -- Clean up buffers opened during the test. Each test should clean up their
    -- own buffers, so we should only be closing buffers opened during this test.
    vim.iter(vim.api.nvim_list_bufs()):each(function(buf_id)
      if vim.api.nvim_buf_is_loaded(buf_id) then
        vim.api.nvim_buf_delete(buf_id, {})
      end
    end)
  end)

  it('correctly calculates package labels', function()
    ---@type {repo_file: string, expected_label: string}[]
    local test_cases = {
      {
        repo_file = 'BUILD',
        expected_label = '//',
      },
      {
        repo_file = 'a1/a2/a3/a3.sh',
        expected_label = '//a1/a2',
      },
      {
        repo_file = 'c1/c2/c2.sh',
        expected_label = '//c1/c2',
      },
    }

    for _, test_case in ipairs(test_cases) do
      local file_path = vim.fs.joinpath(bazel_repo_dir, test_case.repo_file)
      vim.cmd.edit(file_path)
      local bazel_repo = require('pesto.bazel.repo')
      local label = bazel_repo.get_package_label()
      assert.are.equal(test_case.expected_label, label)
    end
  end)
end)
