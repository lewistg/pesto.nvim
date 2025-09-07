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

	before_each(function()
		nvim_chan = vim.fn.jobstart({ "nvim", "--embed", "--headless" }, job_opts)
	end)

	after_each(function()
		vim.fn.jobstop(nvim_chan)
	end)

	it("compile-one-dep builds some dependency for the currently open source file", function()
		vim.rpcrequest(nvim_chan, "nvim_cmd", { cmd = "edit", args = { "hello-world/main.c" } }, {})

		local subcommand = { "bazel", "compile-one-dep" }
		vim.rpcrequest(nvim_chan, "nvim_cmd", { cmd = "Pesto", args = subcommand }, {})

		-- There should be two windows open in the current tab
		local curr_tab_page_nr = vim.rpcrequest(nvim_chan, "nvim_call_function", "tabpagenr", { "$" })
		local tab_info = vim.rpcrequest(nvim_chan, "nvim_call_function", "gettabinfo", { curr_tab_page_nr })

		-- There should be two windows open now
		assert.are.same(2, #tab_info[1].windows)

		--- One of the windows should be the build window
		local build_win_id = vim.rpcrequest(
			nvim_chan,
			"nvim_exec_lua",
			"return require('pesto.runner.default.build_window').find_build_window()",
			{}
		)

		assert.are_not.equal(vim.NIL, build_win_id)

		local build_win_buf_id = vim.rpcrequest(nvim_chan, "nvim_win_get_buf", build_win_id)

		local wait_status = vim.fn.wait(10 * 1000, function()
			local build_info = vim.rpcrequest(nvim_chan, "nvim_cmd", {
				cmd = "lua",
				args = {
					string.format(
						"return require('pesto.runner.default.terminal_buf_info').get_pesto_terminal_info(%s)",
						build_win_buf_id
					),
				},
			}, {})
			return build_info.exit_code == 0
		end)
	end)
end)
