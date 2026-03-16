describe("default runner loader", function()
	local nvim_chan

	---@type pesto.FunctionalTestHelper
	local functional_test_helper

	setup(function()
		-- Note: If you ever need to debug this test, note that the parent directory for vim.fn.tempname() gets deleted
		-- after the test finishes. You may consider using a hardcoded directory (e.g., /tmp/pesto_test/remote_apis_install_test/)
		--local sandbox_dir = "/tmp/pesto_test/remote_apis_install_test/"
		local sandbox_dir = vim.fn.tempname()

		-- Note: Here's a command you use to run neovim in the temp dir if you happen to get to persist
		-- ```
		-- XDG_CONFIG_HOME="$(realpath ./xdg_config_home)" \
		-- XDG_STATE_HOME="$(realpath ./xdg_state_home)" \
		-- XDG_DATA_HOME="$(realpath ./xdg_data_home)" \
		-- vim
		-- ```
		local xdg_config_home_dir = vim.fs.joinpath(sandbox_dir, "xdg_config_home")
		local xdg_state_home_dir = vim.fs.joinpath(sandbox_dir, "xdg_state_home")
		local xdg_data_home_dir = vim.fs.joinpath(sandbox_dir, "xdg_data_home")

		local pesto_dir = vim.fs.joinpath(xdg_data_home_dir, "/nvim/site/pack/test/start/pesto.nvim")

		---@type string[]
		local dirs = {
			xdg_config_home_dir,
			xdg_data_home_dir,
			xdg_state_home_dir,
			pesto_dir,
		}
		vim.iter(dirs):each(function(dir)
			local result = vim.fn.mkdir(dir, "p")
			assert(result == 1)
		end)

		-- Note: We only want to copy committed files, so we use git archive.
		-- One disadvantage to git archive is that any files you want to have
		-- copied have to be committed.
		local archive_result =
			vim.system({ "bash", "-c", string.format("git archive HEAD | tar -x -f - -C %s", pesto_dir) }):wait()
		assert(archive_result.code == 0)

		local busted_fixtures = require("busted.fixtures")
		local job_opts = {
			rpc = true,
			cwd = busted_fixtures.path("bazel_repo_fixture"),
			env = {
				XDG_CONFIG_HOME = xdg_config_home_dir,
				XDG_STATE_HOME = xdg_state_home_dir,
				XDG_DATA_HOME = xdg_data_home_dir,
			},
		}

		nvim_chan = vim.fn.jobstart({ "nvim", "--embed", "--headless" }, job_opts)

		functional_test_helper = require("pesto.test.functional_test_helper"):new(nvim_chan)
	end)

	teardown(function()
		vim.fn.jobstop(nvim_chan)
	end)

	it("installs the Bazel remote APIs helpers", function()
		assert.is_false(functional_test_helper:are_remote_apis_helpers_installed())
		vim.rpcrequest(nvim_chan, "nvim_exec2", ":Pesto install-remote-apis-helpers", {})
		assert.is_true(functional_test_helper:are_remote_apis_helpers_installed())
	end)
end)
