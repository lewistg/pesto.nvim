local BufferSection = require("pesto.ui.util.buffer_section")
local TargetSection = require("pesto.ui.build_events_buffer.target_section")
local table_util = require("pesto.util.table_util")

---@class pesto.TargetListSectionParams
---@field buffer_section pesto.BufferSection
---@field title string
---@field targets {label: string, logs: pesto.TargetActionLogs[]}[]

---@class pesto.TargetListSection
---@field private _buffer_section pesto.BufferSection
---@field private _title string
---@field private _targets string[]
---@field private _is_expanded boolean
---@field private _target_buffer_sections pesto.BufferSection[]
---@field private _target_sections pesto.TargetSection[]
local TargetListSection = {}
TargetListSection.__index = TargetListSection

---@param params pesto.TargetListSectionParams
---@return pesto.TargetListSection
function TargetListSection:new(params)
	local o = setmetatable({}, TargetListSection)

	o._buffer_section = params.buffer_section
	o._title = params.title
	o._targets = params.targets
	o._is_expanded = false

	o._buffer_section:edit_lines({
		lines = { o:_get_header() },
		start_row = 0,
		end_row = 1,
	})

	o._target_sections = table_util.map(
		params.targets,
		---@param target {label: string, logs: pesto.TargetActionLogs[]}
		function(target)
			---@type pesto.BufferSection
			local buffer_section = BufferSection:new({})

			---@type pesto.TargetSectionParams
			local target_section_params = {
				label = target.label,
				failed_actions_logs = target.logs,
				indent_width = 2,
				is_successful = false,
				buffer_section = buffer_section,
			}
			return TargetSection:new(target_section_params)
		end
	)

	return o
end

---@param row number
---@return boolean
function TargetListSection:contains_line(row)
	return self._buffer_section:contains_line(row)
end

---@param cursor_pos number The 0-indexed cursor position relative to the buffer section
function TargetListSection:on_enter_key(cursor_pos)
	local row = cursor_pos[1] - 1
	if row == self._buffer_section.start_row then
		self:_toggle_expanded()
	elseif self._is_expanded then
		for _, target_section in ipairs(self._target_sections) do
			if target_section:contains_line(row) then
				target_section:on_enter_key(cursor_pos)
				break
			end
		end
	end
end

---@private
function TargetListSection:_toggle_expanded()
	self._is_expanded = not self._is_expanded

	vim.print(
		string.format(
			"before: buffer section lines start: %d, end %d, row_len; %d",
			self._buffer_section.start_row,
			self._buffer_section:get_end_row(),
			self._buffer_section.row_len
		)
	)
	self._buffer_section:edit_lines({
		start_row = 0,
		end_row = -1,
		lines = { self:_get_header() },
	})
	if self._is_expanded then
		for i, target_section in ipairs(self._target_sections) do
			self._buffer_section:edit_lines({
				start_row = i,
				end_row = i,
				lines = target_section.buffer_section,
			})
			target_section:set_lines()
		end
	end
	vim.print(
		string.format(
			"before: buffer section lines start: %d, end %d, row_len; %d",
			self._buffer_section.start_row,
			self._buffer_section:get_end_row(),
			self._buffer_section.row_len
		)
	)
end

---@private
---@return string
function TargetListSection:_get_header()
	local toggle_button
	if self._is_expanded then
		toggle_button = "[-]"
	else
		toggle_button = "[+]"
	end
	return string.format("%s %s (%d)", toggle_button, self._title, #self._targets)
end

return TargetListSection
