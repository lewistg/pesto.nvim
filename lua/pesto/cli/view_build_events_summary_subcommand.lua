local BuildEventsBuffer = require("pesto.ui.build_events_buffer")
local BuildEventTree = require("pesto.bazel.build_event_tree")

---@class ViewBuildEventsSummarySubcommand: Subcommand
---@field private _build_event_json_loader BuildEventJsonLoader
---@field private _build_events_buffer BuildEventsBuffer
local ViewBuildEventsSummarySubcommand = {}
ViewBuildEventsSummarySubcommand.__index = ViewBuildEventsSummarySubcommand

ViewBuildEventsSummarySubcommand.name = "view-build-events-summary"

---@param build_event_json_loader BuildEventJsonLoader
function ViewBuildEventsSummarySubcommand:new(build_event_json_loader)
	local o = setmetatable({}, ViewBuildEventsSummarySubcommand)

	o._build_event_json_loader = build_event_json_loader

	o.execute = function(opts)
		o:_execute(opts)
	end

	return o
end

---@param opts SubcommandExecuteOpts
function ViewBuildEventsSummarySubcommand:_execute(opts)
	if #opts.fargs < 1 then
		error(string.format("missing file name argument"))
	end

	---@type string
	local build_events_file = opts.fargs[1]
	if not vim.fn.filereadable(build_events_file) then
		error(string.format("file not readable: %s", build_events_file))
	end

	local build_events_buffer = BuildEventsBuffer:new()
	local build_events = self._build_event_json_loader:load(build_events_file)
	---@type BuildEventTree
	local build_events_tree = BuildEventTree:new(build_events)
	-- build_events_buffer:load_events(build_events_tree)

	vim.api.nvim_set_current_buf(build_events_buffer:get_buf_id())
end

return ViewBuildEventsSummarySubcommand
