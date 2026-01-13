describe("pesto.BuildEventTreeQueries", function()
	local busted_fixtures = require("busted.fixtures")
	local bazel_repo_dir = require("pesto.util.path"):new(busted_fixtures.path("build_event_tree_spec_fixtures"))
	local broken_build_remote_cache_bep_path = bazel_repo_dir:join("broken-build-remote-cache-bep.json")

	it("BuildEventTree:find_command_line_option finds command line options", function()
		local bep_json_loader = require("pesto.bazel.build_event_json_loader"):new()
		local bep_tree = bep_json_loader:load(broken_build_remote_cache_bep_path)

		local BuildEventTreeQueries = require("pesto.bazel.build_event_tree_queries")
		local bep_tree_queries = BuildEventTreeQueries:new(bep_tree)

		local remote_cache_option = bep_tree_queries:find_command_line_option("canonical", "remote_cache")

		assert.is_equal("grpc://localhost:8980", remote_cache_option.option_value)
	end)
end)
