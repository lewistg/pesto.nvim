local table_util = require("pesto.util.table_util")
local BufferSection = require("pesto.ui.buffer_section")

---@class TargetSectionParams
---@field label string
---@field buffer_section BufferSection
---@field indent_width number 0-based index
---@field is_successful boolean

---@class TargetSection
---@field private _label string
---@field private _is_expanded boolean
---@field private _is_successful boolean
---@field private _indent string
---@field buffer_section BufferSection
local TargetSection = {}
TargetSection.__index = TargetSection

---@param params TargetSectionParams
---@return TargetSection
function TargetSection:new(params)
	local o = setmetatable({}, TargetSection)

	o._label = params.label
	o._is_expanded = false
	o._is_successful = params.is_successful
	o._indent = string.rep(" ", params.indent_width)
	o.buffer_section = params.buffer_section

	return o
end

function TargetSection:set_lines()
	self.buffer_section:edit_lines({
		start_row = 0,
		row_end = 1,
		lines = { self:_get_header_line() },
	})
end

---@private
---@return string
function TargetSection:_get_header_line()
	if self._is_successful then
		local disabled_toggle_button = " - "
		return string.format("%s%s %s", self._indent, disabled_toggle_button, self._label)
	else
		---@type string
		local toggle_button
		if self._is_expanded then
			toggle_button = "[-]"
		else
			toggle_button = "[+]"
		end
		return string.format("%s%s %s", self._indent, toggle_button, self._label)
	end
end

---@class TargetListSectionParams
---@field buffer_section BufferSection
---@field title string
---@field targets string[]

---@class TargetListSection
---@field private _buffer_section BufferSection
---@field private _title string
---@field private _targets string[]
---@field private _is_expanded boolean
---@field private _target_buffer_sections BufferSection[]
---@field private _target_sections TargetSection[]
local TargetListSection = {}
TargetListSection.__index = TargetListSection

---@param params TargetListSectionParams
---@return TargetListSection
function TargetListSection:new(params)
	local o = setmetatable({}, TargetListSection)

	o._buffer_section = params.buffer_section
	o._title = params.title
	o._targets = params.targets
	o._is_expanded = false

	o._buffer_section:edit_lines({
		lines = { o:_get_header() },
		start_row = 0,
		row_end = 1,
	})

	o._target_sections = table_util.map(params.targets, function(target)
		---@type BufferSection
		local buffer_section = BufferSection:new({})

		---@type TargetSectionParams
		local target_section_params = {
			label = target,
			indent_width = 2,
			is_successful = false,
			buffer_section = buffer_section,
		}
		return TargetSection:new(target_section_params)
	end)

	return o
end

---@param row number
---@return boolean
function TargetListSection:contains_line(row)
    return self._buffer_section:contains_line(row)
end

---@param cursor_pos number The 0-indexed cursor position relative to the buffer section
function TargetListSection:on_enter_key(cursor_pos)
	if cursor_pos[1] - 1 == self._buffer_section.start_row then
		self:_toggle_expanded()
	end
end

---@private
function TargetListSection:_toggle_expanded()
	self._is_expanded = not self._is_expanded

	-- Disable line change callback

	if self._is_expanded then
		for i, target_section in ipairs(self._target_sections) do
			-- Re-insert the buffer section
			self._buffer_section:edit_lines({
				start_row = i + 1,
				row_end = i + 2,
				lines = target_section.buffer_section,
			})
			target_section:set_lines()
		end
	else
		self._buffer_section:edit_lines({
			start_row = 1,
			row_end = -1,
			lines = {},
		})
	end
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

---@class BuildEventsBuffer
---@field private _build_event_tree BuildEventTree|nil
---@field private _buf_id number
---@field private _target_list_sections TargetListSection[]
---@field private _root_buffer_section BufferSection
---@field private _failed_targets_section TargetListSection
---@field private _successful_targets_section TargetListSection
local BuildEventsBuffer = {}
BuildEventsBuffer.__index = BuildEventsBuffer

---@return BuildEventsBuffer
function BuildEventsBuffer:new()
	local o = setmetatable({}, BuildEventsBuffer)

	o._buf_id = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_keymap(o._buf_id, "n", "<CR>", "", {
		callback = function()
			o:on_enter_key()
		end,
	})

	o._root_buffer_section = BufferSection:new({
		buf_id = o._buf_id,
		start_row = 0,
	})

	o._root_buffer_section:edit_lines({
		start_row = 0,
		row_end = 1,
		lines = { BuildEventsBuffer.HEADER_LINE, "" },
	})

	local failed_targets_buffer_section = BufferSection:new({
		buf_id = o._buf_id,
		start_row = 0,
	})
	o._root_buffer_section:edit_lines({
		start_row = 2,
		row_end = 3,
		lines = failed_targets_buffer_section,
	})
	o._failed_targets_section = TargetListSection:new({
		title = "Failed targets",
		-- targets = failure_target_complete_events,
		targets = { "//foo/bar/baz/qux", "//foo/bar/baz/quux" },
		buffer_section = failed_targets_buffer_section,
		line_editor = self,
	})

	local successful_targets_buffer_section = BufferSection:new({
		buf_id = o._buf_id,
		start_row = 0,
	})
	o._root_buffer_section:edit_lines({
		start_row = 4,
		row_end = 5,
		lines = successful_targets_buffer_section,
	})
	o._successful_targets_section = TargetListSection:new({
		title = "Successful targets",
		-- targets = failure_target_complete_events,
		targets = { "//foo/bar/baz/qux", "//foo/bar/baz/quux" },
		buffer_section = successful_targets_buffer_section,
		line_editor = self,
	})

	return o
end

---@type string
BuildEventsBuffer.HEADER_LINE = "Build summary"

function BuildEventsBuffer:get_buf_id()
	return self._buf_id
end

function BuildEventsBuffer:on_enter_key()
	local cursor_pos = vim.api.nvim_win_get_cursor(0)

    local target_list_sections = {
        self._failed_targets_section,
        self._successful_targets_section
    }

    for _, target_list_section in ipairs(target_list_sections) do
        if target_list_section:contains_line(cursor_pos[1] - 1) then
            target_list_section:on_enter_key(cursor_pos)
        end
    end
end

---@param build_event_tree BuildEventTree
function BuildEventsBuffer:load_events(build_event_tree)
	self._build_event_tree = build_event_tree

	---@type BuildEvent[]
	local target_complete_events = self._build_event_tree:find_events({ "target_completed" })

	---@type TargetComplete[]
	local successful_target_complete_events = {}
	---@type TargetComplete[]
	local failure_target_complete_events = {}
	for _, event in ipairs(target_complete_events) do
		if event.completed ~= nil and event.completed.success then
			table.insert(successful_target_complete_events, event)
		else
			table.insert(failure_target_complete_events, event)
		end
	end
end

return BuildEventsBuffer
