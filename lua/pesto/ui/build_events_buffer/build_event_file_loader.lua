local BuildEventsBuffer = require("pesto.ui.build_events_buffer.build_events_buffer")
local BuildEventTree = require("pesto.bazel.build_event_tree")

---@class ViewBuildEventsSummarySubcommand: Subcommand
---@field private _build_event_json_loader pesto.BuildEventJsonLoader
---@field private _build_events_buffer pesto.BuildEventsBuffer
---@field private _build_event_file_loader pesto.BuildEventFileLoader
local ViewBuildEventsSummarySubcommand = {}
ViewBuildEventsSummarySubcommand.__index = ViewBuildEventsSummarySubcommand

ViewBuildEventsSummarySubcommand.name = "view-build-events-summary"

---@param build_event_json_loader pesto.BuildEventJsonLoader
---@param build_event_file_loader pesto.BuildEventFileLoader
function ViewBuildEventsSummarySubcommand:new(build_event_json_loader, build_event_file_loader)
	local o = setmetatable({}, ViewBuildEventsSummarySubcommand)

	o._build_event_json_loader = build_event_json_loader
	o._build_event_file_loader = build_event_file_loader

	o.execute = function(opts)
		o:_execute(opts)
	end

	return o
end

---@param opts SubcommandExecuteOpts
function ViewBuildEventsSummarySubcommand:_execute(opts)
	if #opts.fargs < 1 then
		vim.notify(string.format("Missing file name argument"), vim.log.levels.ERROR)
		return
	end

	---@type string
	local build_events_file = opts.fargs[1]
	if vim.fn.filereadable(build_events_file) == 0 then
		vim.notify(string.format("File not readable: %s", build_events_file), vim.log.levels.ERROR)
		return
	end

	local build_events = self._build_event_json_loader:load(build_events_file)

	---@type BuildEventTree
	local build_events_tree = BuildEventTree:new(build_events)
	-- build_events_buffer:load_events(build_events_tree)

	local build_events_buffer = BuildEventsBuffer:new(build_events_tree, self._build_event_file_loader)
	vim.api.nvim_set_current_buf(build_events_buffer:get_buf_id())
end

return ViewBuildEventsSummarySubcommand
