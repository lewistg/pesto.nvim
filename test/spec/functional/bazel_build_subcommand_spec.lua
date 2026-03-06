local busted_fixtures = require("busted.fixtures")
local Path = require("pesto.util.path")
local table_util = require("pesto.util.table_util")

describe("open BUILD file subcommands", function()
	local nvim_chan
	local bazel_repo_dir = Path:new(busted_fixtures.path("bazel_repo_fixture"))
	local env_vars = vim.fn.environ()
	local job_opts = {
		rpc = true,
		cwd = tostring(bazel_repo_dir),
		env = {
			XDG_CONFIG_HOME = env_vars["XDG_CONFIG_HOME"],
			XDG_STATE_HOME = env_vars["XDG_STATE_HOME"],
			XDG_DATA_HOME = env_vars["XDG_DATA_HOME"],
		},
	}

	---@type pesto.FunctionalTestHelper
	local functional_test_helper

	before_each(function()
		nvim_chan = vim.fn.jobstart({ "nvim", "--embed", "--headless" }, job_opts)
		functional_test_helper = require("pesto.test.functional_test_helper"):new(nvim_chan)
	end)

	after_each(function()
		vim.fn.jobstop(nvim_chan)
	end)

	---@param bazel_args string[]
	local function test_bazel_command(bazel_args)
		vim.rpcrequest(nvim_chan, "nvim_cmd", { cmd = "edit", args = { "foo/foo1/foo2/foo3/foo3.sh" } }, {})

		local subcommand = table_util.concat({ "bazel" }, bazel_args)
		vim.rpcrequest(nvim_chan, "nvim_cmd", { cmd = "Pesto", args = subcommand }, {})

		-- There should be two windows open in the current tab
		local curr_tab_page_nr = vim.rpcrequest(nvim_chan, "nvim_call_function", "tabpagenr", { "$" })
		local tab_info = vim.rpcrequest(nvim_chan, "nvim_call_function", "gettabinfo", { curr_tab_page_nr })

		-- There should be two windows open now
		assert.are.same(2, #tab_info[1].windows)

		--- One of the windows should be the build window
		local build_win_ids = functional_test_helper:find_build_windows()
		assert.are.equal(1, #build_win_ids)

		local wait_status = vim.fn.wait(10 * 1000, function()
			return functional_test_helper:get_build_exit_code() == 0
		end)
		assert.are.equal(0, wait_status)
	end

	it("bazel build runs in a new terminal window", function()
		test_bazel_command({ "build", "//foo/foo1/foo2/foo3" })
	end)

	it("bazel test runs in a new terminal window", function()
		test_bazel_command({ "test", "//foo/foo1/foo2/foo3:foo1_spec" })
	end)

	it("bazel run runs in a new terminal window", function()
		test_bazel_command({ "run", "//foo/foo1/foo2/foo3" })
	end)
end)
