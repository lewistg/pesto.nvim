describe("pesto.BuildEventTreeQueries", function()
	local busted_fixtures = require("busted.fixtures")
	local bazel_repo_dir = busted_fixtures.path("build_event_tree_spec_fixtures")
	local broken_build_remote_cache_bep_path = vim.fs.joinpath(bazel_repo_dir, "broken-build-remote-cache-bep.json")

	it("BuildEventTree:find_command_line_option finds command line options", function()
		local bep_json_loader = require("pesto.bazel.build_event_json_loader"):new()
		local bep_tree = bep_json_loader:load(broken_build_remote_cache_bep_path)

		local BuildEventTreeQueries = require("pesto.bazel.build_event_tree_queries")
		local bep_tree_queries = BuildEventTreeQueries:new(bep_tree)

		local remote_cache_option = bep_tree_queries:find_command_line_option("canonical", "remote_cache")[1]

		assert.is_equal("grpc://localhost:8980", remote_cache_option.option_value)
	end)

	it("BuildEventTree:find_command_line_option finds all options when there are multiple", function()
		local bep_json_loader = require("pesto.bazel.build_event_json_loader"):new()
		local bep_tree = bep_json_loader:load(broken_build_remote_cache_bep_path)

		local BuildEventTreeQueries = require("pesto.bazel.build_event_tree_queries")
		local bep_tree_queries = BuildEventTreeQueries:new(bep_tree)

		local remote_header_options = bep_tree_queries:find_command_line_option("canonical", "remote_header")
		local key_values = vim.iter(remote_header_options)
			:map(function(option)
				return { option["option_name"], option["option_value"] }
			end)
			:totable()

		table.sort(key_values, function(item1, item2)
			return item1[2] < item2[2]
		end)

		assert.are.same({ { "remote_header", "baz=qux" }, { "remote_header", "foo=bar" } }, key_values)
	end)
end)
