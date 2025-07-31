local table_util = require("pesto.util.table_util")

---@class pesto.LineEdit
---@field start_row number
---@field end_row number
---@field lines string[]|pesto.BufferSection If a buffer section is provided, it is assumed to be empty

---@class pesto.BufferSectionParams
---@field buf_id number|nil
---@field start_row number|nil

--- Manages contiguous range of lines in a buffer
---@class pesto.BufferSection
---@field start_row number|nil 0-indexed, buffer-relative
---@field row_len number
---@field child_sections pesto.BufferSection Linked list of child sections
---@field next_section pesto.BufferSection|nil
---@field private _on_lines_changed fun(line_delta: number)
---@field private _buf_id number|nil
local BufferSection = {}
BufferSection.__index = BufferSection

---@param params pesto.BufferSectionParams
function BufferSection:new(params)
	local o = setmetatable({}, BufferSection)

	o._buf_id = params.buf_id
	if o._buf_id ~= nil then
		o.start_row = 0
		o.row_len = 1
	else
		o.start_row = 0
		o.row_len = 0
	end

	o.start_row = params.start_row
	o.row_len = 1

	return o
end

---@return boolean
function BufferSection:is_attached()
	return self._buf_id ~= nil
end

---@param rel_line_edit pesto.LineEdit Section relative line edit
function BufferSection:edit_lines(rel_line_edit)
	if self._buf_id == nil then
		error("Cannot set lines when buffer section is not attached to a buffer")
	end

	local normalized_rel_start_row = self:_normalize_rel_row_index(rel_line_edit.start_row)
	local normalized_rel_end_row = self:_normalize_rel_row_index(rel_line_edit.end_row)

	-- We only allow edits that keep the buffer section contiguous, so you
	-- cannot edit lines beyond the line right after the buffer section's
	-- current range of lines.
	if normalized_rel_start_row > self.row_len then
		error(string.format("Invalid start row: %d", rel_line_edit.start_row))
	elseif normalized_rel_end_row > self.row_len then
		error(string.format("Invalid end row: %d", rel_line_edit.end_row))
	end

	local start_row = self.start_row + normalized_rel_start_row
	local end_row = self.start_row + normalized_rel_end_row

	-- If the replaced lines overlaps any existing child buffer sections, then
	-- the entirety of those child buffer sections are removed.
	local overlapping_child_sections = self:_find_overlapping_child_sections(start_row, end_row)
	for _, child_section in ipairs(overlapping_child_sections) do
		start_row = math.min(start_row, child_section.start_row)
		end_row = math.max(end_row, child_section:get_end_row())
		child_section:_detatch()
	end

	---@type string[]
	local lines
	if getmetatable(rel_line_edit.lines) == BufferSection then
		-- Adding a child buffer section

		---@type pesto.BufferSection
		local buffer_section = rel_line_edit.lines
		buffer_section._buf_id = self._buf_id
		buffer_section.start_row = start_row
		buffer_section.row_len = 1
		self:_insert_child_section(buffer_section)
		buffer_section:on_lines_changed(function(line_delta)
			---@type pesto.BufferSection
			local next_section = buffer_section.next_section
			while next_section do
				next_section.start_row = next_section.start_row + line_delta
				next_section = next_section.next_section
			end
			self.row_len = self.row_len + line_delta

			if self._on_lines_changed then
				self._on_lines_changed(line_delta)
			end
		end)

		lines = { "" }
	else
		lines = rel_line_edit.lines
	end

	vim.api.nvim_buf_set_lines(self._buf_id, start_row, end_row, false, lines)

	---@type number
	local num_replaced_lines = end_row - start_row
	---@type number
	local len_delta = #lines - num_replaced_lines

	self.row_len = self.row_len + len_delta

	if self._on_lines_changed then
		self._on_lines_changed(len_delta)
	end
end

---@param row number
function BufferSection:_normalize_rel_row_index(row)
	if row < 0 then
		--- See docs for nvim_buf_set_lines
		return self.row_len + 1 + row
	else
		return row
	end
end

---@return number 0-indexed, buffer-relative, inclusive
function BufferSection:get_end_row()
	return self.start_row + self.row_len - 1
end

---@param row number 0-based index
---@return boolean
function BufferSection:contains_line(row)
	if self._buf_id == nil then
		-- Detached from a buffer
		return false
	else
		return row >= self.start_row and row <= self:get_end_row()
	end
end

---@private
function BufferSection:_detatch()
	self._buf_id = nil
	self.start_row = 0
	self.row_len = 0
	self._on_lines_changed = nil
end

---@param start_row number 0-indexed, buffer-relative
---@param end_row number 0-indexed, buffer-relative
---@return pesto.BufferSection[]
function BufferSection:_find_overlapping_child_sections(start_row, end_row)
	---@type pesto.BufferSection[]
	local child_sections = {}
	local buffer_section = self.child_sections
	while buffer_section ~= nil do
		if
			buffer_section:contains_line(start_row)
			or buffer_section:contains_line(end_row)
			or (start_row < buffer_section.start_row and end_row > buffer_section:get_end_row())
		then
			table.insert(child_sections, buffer_section)
		end
		buffer_section = buffer_section.next_section
	end
	return child_sections
end

---@private
---@param child_section pesto.BufferSection
function BufferSection:_insert_child_section(child_section)
	if self.child_sections == nil then
		self.child_sections = child_section
		return
	end

	---@type pesto.BufferSection|nil
	local next_section = self.child_sections
	---@type pesto.BufferSection|nil
	local prev_section = nil
	while next_section and next_section.start_row <= next_section.start_row do
		prev_section = next_section
		next_section = next_section.next_section
	end

	if prev_section == nil then
		-- List is empty
		self.child_sections = child_section
	else
		prev_section.next_section = child_section
		child_section.next_section = next_section
	end
end

---@param callback fun(line_delta: number)
function BufferSection:on_lines_changed(callback)
	self._on_lines_changed = callback
end

return BufferSection
