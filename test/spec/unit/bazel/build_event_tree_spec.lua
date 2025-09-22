describe("pesto.BuildEventTree", function()
	local busted_fixtures = require("busted.fixtures")
	local bazel_repo_dir = require("pesto.util.path"):new(busted_fixtures.path("build_event_tree_spec_fixtures"))
	local clean_compile_build_events_path = bazel_repo_dir:join("clean-compile.json")

	it("BuildEventTree:new constructs the tree from raw build events", function()
		local bep_json_loader = require("pesto.bazel.build_event_json_loader"):new()
		local bep_tree = bep_json_loader:load(clean_compile_build_events_path)

		local started_events = bep_tree:find_events_by_kind({ "started" })
		assert.is_equal(1, #started_events)
		assert.is_equal("started", started_events[1].kind)

		local target_completed_events = bep_tree:find_events_by_kind({ "target_completed" })
		assert.is_equal(1, #started_events)
		assert.is_equal("target_completed", target_completed_events[1].kind)
	end)
end)

describe("BuildEventTree.get_id_key", function()
	it("gets a key for an build event ID", function()
		local target_completed_id = {
			["target_completed"] = {
				["label"] = "//src/main/java/net/starlark/java/syntax:syntax",
				["configuration"] = {
					["id"] = "356831ae87e24de471c4d2ef34fec8d0bad337e3ab0982e0d835037122dcbcf0",
				},
			},
		}
		local BuildEvent = require("pesto.bazel.build_event")
		local id_key = BuildEvent.get_id_key(target_completed_id)
		local expected_id_key =
			"target_completed:356831ae87e24de471c4d2ef34fec8d0bad337e3ab0982e0d835037122dcbcf0_//src/main/java/net/starlark/java/syntax:syntax"
		assert.are.same(expected_id_key, id_key)
	end)
end)
