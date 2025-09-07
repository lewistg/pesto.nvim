local BuildEventsBuffer = require("pesto.ui.build_events_buffer.build_events_buffer")
local BuildEventTree = require("pesto.bazel.build_event_tree")
local terminal_buf_info = require("pesto.runner.default.terminal_buf_info")

---@class pesto.OpenBuildEventsSummarySubcommand: Subcommand
---@field private _build_event_json_loader pesto.BuildEventJsonLoader
---@field private _build_events_buffer pesto.BuildEventsBuffer
---@field private _build_event_file_loader pesto.BuildEventFileLoader
local OpenBuildEventsSummarySubcommand = {}
OpenBuildEventsSummarySubcommand.__index = OpenBuildEventsSummarySubcommand

OpenBuildEventsSummarySubcommand.name = "open-build-events-summary"

---@param build_event_json_loader pesto.BuildEventJsonLoader
---@param build_event_file_loader pesto.BuildEventFileLoader
function OpenBuildEventsSummarySubcommand:new(build_event_json_loader, build_event_file_loader)
	local o = setmetatable({}, OpenBuildEventsSummarySubcommand)

	o._build_event_json_loader = build_event_json_loader
	o._build_event_file_loader = build_event_file_loader

	o.execute = function(opts)
		o:_execute(opts)
	end

	return o
end

---@param opts SubcommandExecuteOpts
function OpenBuildEventsSummarySubcommand:_execute(opts)
	---@type string|nil
	local build_events_file
	if #opts.fargs < 1 then
		local buf_id = vim.api.nvim_get_current_buf()
		local term_buf_info = terminal_buf_info.get_pesto_terminal_info(buf_id)
		if term_buf_info and term_buf_info.bep_file then
			build_events_file = term_buf_info.bep_file
		end
	else
		build_events_file = opts.fargs[1]
	end

	if build_events_file == nil then
		vim.notify(string.format("Missing file name argument"), vim.log.levels.ERROR)
		return
	end

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

return OpenBuildEventsSummarySubcommand
