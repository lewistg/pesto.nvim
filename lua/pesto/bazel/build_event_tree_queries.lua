--- Contains common, higher-level queries on a pesto.BuildEventTree
---@class pesto.BuildEventTreeQueries
---@field private _build_event_tree BuildEventTree
local BuildEventTreeQueries = {}
BuildEventTreeQueries.__index = BuildEventTreeQueries

---@param build_event_tree BuildEventTree
---@return pesto.BuildEventTreeQueries
function BuildEventTreeQueries:new(build_event_tree)
	local o = setmetatable({}, BuildEventTreeQueries)
	o._build_event_tree = build_event_tree
	return o
end

---@param command_line_label string
---@param option_name string
---@return pesto.bep.Option[]
function BuildEventTreeQueries:find_command_line_option(command_line_label, option_name)
	---@type pesto.bep.BuildEvent
	local command_line_event = nil
	for _, event in ipairs(self._build_event_tree:find_events_by_kind({ "structured_command_line" })) do
		if vim.tbl_get(event, "structured_command_line", "command_line_label") == command_line_label then
			command_line_event = event
			break
		end
	end

	if command_line_event == nil then
		return {}
	end

	---@type pesto.bep.CommandLineSection|nil
	local command_line_section
	for _, section in ipairs(vim.tbl_get(command_line_event, "structured_command_line", "sections") or {}) do
		local section_label = vim.tbl_get(section, "section_label")
		if section_label == "command options" then
			command_line_section = section
		end
	end

	if command_line_section == nil then
		return {}
	end

	return vim.iter(vim.tbl_get(command_line_section, "option_list", "option") or {})
		:filter(function(option)
			return vim.tbl_get(option, "option_name") == option_name
		end)
		:totable()
end

return BuildEventTreeQueries
