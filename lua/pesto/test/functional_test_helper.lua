---@class pesto.FunctionalTestHelper
---@field private nvim_chan number
local FunctionalTestHelper = {}
FunctionalTestHelper.__index = FunctionalTestHelper

---@param nvim_chan number
function FunctionalTestHelper:new(nvim_chan)
	local o = setmetatable({}, FunctionalTestHelper)

	o.nvim_chan = nvim_chan

	return o
end

function FunctionalTestHelper:find_build_windows()
	--- One of the windows should be the build window
	return vim.rpcrequest(
		self.nvim_chan,
		"nvim_exec_lua",
		"return require('pesto.components').build_window_manager:find_build_windows(0)",
		{}
	)
end

function FunctionalTestHelper:get_build_exit_code()
	--- One of the windows should be the build window
	return vim.rpcrequest(
		self.nvim_chan,
		"nvim_exec_lua",
		"return require('pesto.components').build_window_manager:get_build_exit_code()",
		{}
	)
end

---@param mode pesto.CliCompletionMode
function FunctionalTestHelper:set_completion_mode(mode)
	vim.rpcrequest(
		self.nvim_chan,
		"nvim_exec_lua",
		string.format(
			"require('pesto.components').functional_test_hooks:extend_global_table('pesto', { cli_completion = { mode = '%s' } })",
			mode
		),
		{}
	)
end

return FunctionalTestHelper
