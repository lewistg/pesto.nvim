---@class pesto.DefaultRunner
---@field private _settings pesto.Settings
---@field private _build_terminal_manager pesto.BuildTerminalManager
local DefaultRunner = {}
DefaultRunner.__index = DefaultRunner

---@param settings pesto.Settings
---@param build_terminal_manager pesto.BuildTerminalManager
function DefaultRunner:new(settings, build_terminal_manager)
	local o = setmetatable({}, DefaultRunner)

	o._settings = settings
	o._build_terminal_manager = build_terminal_manager

	return o
end

---@param opts RunBazelOpts
function DefaultRunner.__call(self, opts)
	if self._settings:get_enable_bep_integration() then
		require("pesto.cli.bazel_build_event_util").inject_bep_option(opts.bazel_command, self._settings)
	end

	local build_term_buf_id = self._build_terminal_manager:run_bazel(opts)

	---@type number|nil
	local win_id

	local build_window = require("pesto.runner.default.build_window")
	if self._settings:get_auto_open_build_term() then
		win_id = build_window.get_or_create_tab_build_window(0)
	else
		win_id = build_window.find_build_window(0)
	end
	if win_id ~= nil then
		vim.api.nvim_win_set_buf(win_id, build_term_buf_id)
	end
end

return DefaultRunner
