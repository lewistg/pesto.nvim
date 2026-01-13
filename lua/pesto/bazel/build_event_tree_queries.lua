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
---@return pesto.Option|nil
function BuildEventTreeQueries:find_command_line_option(command_line_label, option_name)
	local events = self._build_event_tree:find_events_by_kind({ "structured_command_line" })

	---@type pesto.Option[]|nil
	local command_options
	for _, event in ipairs(events) do
		if vim.tbl_get(event, "structured_command_line", "command_line_label") == command_line_label then
			for _, section in ipairs(vim.tbl_get(event, "structured_command_line", "sections") or {}) do
				local section_label = vim.tbl_get(section, "section_label")
				if section_label == "command options" then
					command_options = vim.tbl_get(section, "option_list", "option") or {}
					break
				end
			end
		end
	end

	for _, option in ipairs(command_options or {}) do
		if vim.tbl_get(option, "option_name") == option_name then
			return option
		end
	end
	return nil
end

return BuildEventTreeQueries
