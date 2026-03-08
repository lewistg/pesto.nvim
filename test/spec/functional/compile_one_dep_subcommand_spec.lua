describe("open BUILD file subcommands", function()
	local nvim_chan
	local busted_fixtures = require("busted.fixtures")
	local bazel_repo_dir = busted_fixtures.path("bazel_repo_fixture")
	local env_vars = vim.fn.environ()
	local job_opts = {
		rpc = true,
		cwd = bazel_repo_dir,
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

	local function verify_compile_one_dep()
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

	it("compile-one-dep builds some dependency for the currently open source file", function()
		vim.rpcrequest(nvim_chan, "nvim_cmd", { cmd = "edit", args = { "hello-world/main.c" } }, {})

		local subcommand = { "compile-one-dep" }
		vim.rpcrequest(nvim_chan, "nvim_cmd", { cmd = "Pesto", args = subcommand }, {})

		verify_compile_one_dep()
	end)

	it(
		"compile-one-dep builds some dependency for the currently open source file even when the package is in an ancestor directory",
		function()
			local src_dir = vim.fs.joinpath(bazel_repo_dir, "java/src/main/java/com/example")
			vim.rpcrequest(
				nvim_chan,
				"nvim_cmd",
				{ cmd = "edit", args = { vim.fs.joinpath(src_dir, "Main.java") } },
				{}
			)

			local build_file =
				vim.rpcrequest(nvim_chan, "nvim_exec_lua", "return require('pesto.bazel.repo').find_build_file(0)", {})

			-- Make sure the build file is in a different directory (should be an ancestor)
			assert.are_not.equal(src_dir, vim.fs.dirname(build_file))

			local subcommand = { "compile-one-dep" }
			vim.rpcrequest(nvim_chan, "nvim_cmd", { cmd = "Pesto", args = subcommand }, {})

			verify_compile_one_dep()
		end
	)
end)
