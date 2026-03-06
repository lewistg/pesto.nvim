---@class pesto.DefaultRunner
---@field private _settings pesto.Settings
---@field private _build_window_manager pesto.BuildWindowManager
---@field private _build_event_json_loader pesto.BuildEventJsonLoader
---@field private _quickfix_loader pesto.QuickfixLoader
local DefaultRunner = {}
DefaultRunner.__index = DefaultRunner

---@param settings pesto.Settings
---@param build_window_manager pesto.BuildWindowManager
---@param build_event_json_loader pesto.BuildEventJsonLoader
---@param quickfix_loader pesto.QuickfixLoader
function DefaultRunner:new(settings, build_window_manager, build_event_json_loader, quickfix_loader)
	local o = setmetatable({}, DefaultRunner)

	o._settings = settings
	o._build_window_manager = build_window_manager
	o._build_event_json_loader = build_event_json_loader
	o._quickfix_loader = quickfix_loader

	return o
end

---@param opts RunBazelOpts
function DefaultRunner.__call(self, opts)
	local bazel_build_event_util = require("pesto.cli.bazel_build_event_util")

	---@type string|nil
	local bep_file = nil
	if self._settings:get_enable_bep_integration() then
		bazel_build_event_util.inject_bep_option(opts.bazel_command, self._settings)
		bep_file = bazel_build_event_util.extract_bep_option(opts.bazel_command)
	end

	local bazel_command = table.concat(opts.bazel_command, " ")
	local term_command =
		string.format("(cd %s && %s)", opts.context.package_dir or opts.context.workspace_dir, bazel_command)

	---@type BuildEventTree|nil
	local build_event_tree = nil

	self._build_window_manager:start_new_build({
		term_command = term_command,
		auto_open = self._settings:get_auto_open_build_term(),
		on_exit = function(is_current)
			if not is_current then
				return
			end
			if bep_file then
				---@diagnostic disable-next-line: invisible
				build_event_tree = self._build_event_json_loader:load(bep_file)
				---@diagnostic disable-next-line: invisible
				self._quickfix_loader:load_quickfix(build_event_tree, function()
					vim.cmd.copen()
				end)
			end
		end,
		get_build_event_tree = function()
			return build_event_tree
		end,
	})
end

return DefaultRunner
