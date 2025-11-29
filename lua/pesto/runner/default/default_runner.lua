---@class pesto.DefaultRunner
---@field private _settings pesto.Settings
---@field private _build_terminal_manager pesto.BuildTerminalManager
---@field private _quickfix_loader pesto.QuickfixLoader
local DefaultRunner = {}
DefaultRunner.__index = DefaultRunner

---@param settings pesto.Settings
---@param build_terminal_manager pesto.BuildTerminalManager
---@param quickfix_loader pesto.QuickfixLoader
function DefaultRunner:new(settings, build_terminal_manager, quickfix_loader)
	local o = setmetatable({}, DefaultRunner)

	o._settings = settings
	o._build_terminal_manager = build_terminal_manager
	o._quickfix_loader = quickfix_loader

	return o
end

---@param opts RunBazelOpts
function DefaultRunner.__call(self, opts)
	if self._settings:get_enable_bep_integration() then
		require("pesto.cli.bazel_build_event_util").inject_bep_option(opts.bazel_command, self._settings)
	end

	local quickfix_loader = self._quickfix_loader
	local build_terminal_manager = self._build_terminal_manager
	local build_term_buf_id
	build_term_buf_id = self._build_terminal_manager:run_bazel(
		opts,
		---@param build_finished_event pesto.BuildFinishedEvent
		function(build_finished_event)
			local logger = require("pesto.logger")
			logger.info("Build finished. Loading quickfix")

			-- Wrapping these vim.notify calls in a vim.schedule seems to
			-- prevent (perhaps) a textlock issue that blocks us from
			-- immediately opening the quickfix window.
			if build_finished_event.exit_code == 0 then
				vim.schedule(function()
					vim.notify("Pesto: Build succeeded", vim.log.levels.INFO)
				end)
			else
				vim.schedule(function()
					vim.notify("Pesto: Build failed", vim.log.levels.ERROR)
				end)
			end

			local build_tree = build_finished_event:get_build_event_tree()
			if build_tree then
				quickfix_loader:load_quickfix(build_tree, function()
					vim.cmd.copen()
					build_terminal_manager:close_terminal_buf(build_term_buf_id)
				end)
			else
				local logger = require("pesto.logger")
				logger.warn("Failed to load build event tree")
			end
		end
	)

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
