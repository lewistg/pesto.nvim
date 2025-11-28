describe("default runner loader", function()
	local nvim_chan
	local Path = require("pesto.util.path")
	local busted_fixtures = require("busted.fixtures")
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

	setup(function()
		nvim_chan = vim.fn.jobstart({ "nvim", "--embed", "--headless" }, job_opts)
	end)

	teardown(function()
		vim.fn.jobstop(nvim_chan)
	end)

	--- Navigate to
	---@param quickfix_buf_id number 0 for the current buffer
	---@param error_index number
	local function jump_via_quickfix_item(quickfix_buf_id, error_index)
		local quickfix_lines = vim.rpcrequest(nvim_chan, "nvim_buf_get_lines", quickfix_buf_id, 0, -2, false)
	end

	it("loads errors into the quickfix window", function()
		-- Note: hello-error/main.c has an  error
		vim.rpcrequest(nvim_chan, "nvim_cmd", { cmd = "edit", args = { "hello-error/main.c" } }, {})

		local error_source_file_buf_id = vim.rpcrequest(nvim_chan, "nvim_get_current_buf")
		local original_win_id = vim.rpcrequest(nvim_chan, "nvim_get_current_win")

		vim.rpcrequest(nvim_chan, "nvim_cmd", { cmd = "Pesto", args = { "compile-one-dep" } }, {})

		-- Build should finish successfully
		local expected_exit_code = 1 -- The build should fail
		local wait_status = vim.fn.wait(10 * 1000, function()
			local exit_code = vim.rpcrequest(
				nvim_chan,
				"nvim_exec_lua",
				"return require('pesto.components').functional_test_helper:get_build_exit_code()",
				{}
			)
			assert.is_true(exit_code == vim.NIL or exit_code == expected_exit_code)
			return exit_code == expected_exit_code
		end)
		assert.are.same(0, wait_status)

		-- Eventually the quickfix window should be focused
		wait_status = vim.fn.wait(5 * 1000, function()
			local current_tab_page_id = vim.rpcrequest(nvim_chan, "nvim_get_current_tabpage")
			local tabpage_win_ids = vim.rpcrequest(nvim_chan, "nvim_tabpage_list_wins", current_tab_page_id)

			local current_win_id = vim.rpcrequest(nvim_chan, "nvim_get_current_win")
			local current_win_info =
				vim.rpcrequest(nvim_chan, "nvim_call_function", "getwininfo", { current_win_id })[1]
			local is_quickfix = vim.tbl_get(current_win_info or {}, "quickfix")

			return is_quickfix == 1
		end)
		assert.are.same(0, wait_status)

		-- Test quickfix navigation by making sure it jumps to the error
		local quickfix_items = vim.rpcrequest(
			nvim_chan,
			"nvim_exec_lua",
			"return require('pesto.components').functional_test_helper:get_quickfix_items()",
			{}
		)

		-- We open a separate window, to observe the the navigation back to the original source file
		vim.rpcrequest(nvim_chan, "nvim_set_current_win", original_win_id)
		vim.rpcrequest(nvim_chan, "nvim_cmd", { cmd = "edit", args = { "hello-error/BUILD" } }, {})

		for _, quickfix_entry in ipairs(quickfix_items) do
			if quickfix_entry.bufnr ~= 0 then
				vim.rpcrequest(
					nvim_chan,
					"nvim_exec_lua",
					string.format(
						"return require('pesto.components').functional_test_helper:jump_via_quickfix_item(0, %d)",
						quickfix_entry.lnum - 1
					),
					{}
				)
				break
			end
		end

		-- Confirm the jump
		local current_buf_id = vim.rpcrequest(nvim_chan, "nvim_get_current_buf")
		assert.are.same(error_source_file_buf_id, current_buf_id)
	end)
end)
