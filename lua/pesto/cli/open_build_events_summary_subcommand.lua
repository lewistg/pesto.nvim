---@class pesto.OpenBuildEventsSummarySubcommand: Subcommand
---@field private _build_window_manager pesto.BuildWindowManager
local OpenBuildEventsSummarySubcommand = {}
OpenBuildEventsSummarySubcommand.__index = OpenBuildEventsSummarySubcommand

OpenBuildEventsSummarySubcommand.name = "open-build-events-summary"

---@param build_window_manager pesto.BuildWindowManager
function OpenBuildEventsSummarySubcommand:new(build_window_manager)
	local o = setmetatable({}, OpenBuildEventsSummarySubcommand)

	o._build_window_manager = build_window_manager

	o.execute = function(opts)
		o:_execute(opts)
	end

	return o
end

---@param opts SubcommandExecuteOpts
function OpenBuildEventsSummarySubcommand:_execute(opts)
	self._build_window_manager:open_build_summary()
end

return OpenBuildEventsSummarySubcommand
