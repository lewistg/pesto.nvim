local BepTree = require("pesto.bazel.bep_tree")
local busted_fixtures = require("busted.fixtures")
local Path = require("pesto.util.path")

describe("BepTree", function()
	local bazel_repo_dir = Path:new(busted_fixtures.path("bep_tree_spec_fixtures"))
	local clean_compile_build_events_path = bazel_repo_dir:join("clean-compile.json")

	it("BepTree:new constructs the tree from raw build events", function()
    end)
end)

describe("BepTree.get_id_key", function()
	it("gets a key for an build event ID", function()
		local target_completed_id = {
			["target_completed"] = {
				["label"] = "//src/main/java/net/starlark/java/syntax:syntax",
				["configuration"] = {
					["id"] = "356831ae87e24de471c4d2ef34fec8d0bad337e3ab0982e0d835037122dcbcf0",
				},
			},
		}
		local id_key = BepTree.get_id_key(target_completed_id)
		local expected_id_key =
			"target_completed:356831ae87e24de471c4d2ef34fec8d0bad337e3ab0982e0d835037122dcbcf0_//src/main/java/net/starlark/java/syntax:syntax"
		assert.are.same(expected_id_key, id_key)
	end)
end)
