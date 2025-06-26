local busted_fixtures = require("busted.fixtures")
local Path = require("pesto.util.path")

describe("CLI completion", function()
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

	local ESCAPE_KEY = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
	local TAB_KEY = vim.api.nvim_replace_termcodes("<Tab>", true, false, true)

	setup(function()
		nvim_chan = vim.fn.jobstart({ "nvim", "--embed", "--headless" }, job_opts)
	end)

	teardown(function()
		vim.fn.jobstop(nvim_chan)
	end)

	before_each(function()
		-- Clear out autocomplete
		vim.rpcrequest(nvim_chan, "nvim_feedkeys", ESCAPE_KEY, "t", false)
	end)

	---@type {prefix_keys: string, expected_command_line: string, expected_completions: string[], open_file: Path|nil}[]
	local test_cases = {
		{
			prefix_keys = "Pes",
			expected_command_line = "Pesto",
			expected_completions = {},
		},
		{
			prefix_keys = "Pesto bazel ",
			expected_command_line = "Pesto bazel build",
			expected_completions = { "build", "run", "test" },
		},
		{
			prefix_keys = "Pesto bazel build //",
			expected_command_line = "Pesto bazel build //bar/",
			expected_completions = {
				"//bar/",
				"//bar:",
				"//baz/",
				"//baz:",
				"//foo/",
				"//foo:",
			},
		},
		{
			prefix_keys = "Pesto bazel build //foo/*",
			expected_command_line = "Pesto bazel build //foo/foo1/",
			expected_completions = {
				"//foo/foo1/",
				"//foo/foo1:",
			},
		},
		{
			open_file = Path:new("foo/foo1/foo2/foo3/foo1.sh"),
			prefix_keys = "Pesto bazel build :",
			expected_command_line = "Pesto bazel build :foo1",
			expected_completions = {
				"//foo/foo1/",
				"//foo/foo1:",
			},
		},
	}

	for i, test_case in ipairs(test_cases) do
		it("CLI completion test #" .. i, function()
			if test_case.open_file then
				vim.rpcrequest(nvim_chan, "nvim_cmd", { cmd = "edit", args = { tostring(test_case.open_file) } }, {})
			end
			vim.rpcrequest(nvim_chan, "nvim_feedkeys", ":" .. test_case.prefix_keys, "t", false)
			vim.rpcrequest(nvim_chan, "nvim_feedkeys", TAB_KEY, "t", false)

			local command_line = vim.rpcrequest(nvim_chan, "nvim_call_function", "getcmdline", {})
			assert.are.same(test_case.expected_command_line, command_line)
		end)
	end
end)
