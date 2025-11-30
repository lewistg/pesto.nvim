local LazyPromise = require("pesto.util.lazy_promise")
local table_util = require("pesto.util.table_util")

---@alias pesto.TargetActionLogs {stdout: pesto.LazyPromise|nil, stderr: pesto.LazyPromise|nil}

---@class pesto.TargetSectionParams
---@field label string
---@field failed_actions_logs pesto.TargetActionLogs[]
---@field buffer_section pesto.BufferSection
---@field indent_width number 0-based index
---@field is_successful boolean

---@class pesto.TargetSection
---@field private _label string
---@field private _is_expanded boolean
---@field private _is_successful boolean
---@field private _indent string
---@field private _logs pesto.TargetActionLogs
---@field buffer_section pesto.BufferSection
local TargetSection = {}
TargetSection.__index = TargetSection

---@param params pesto.TargetSectionParams
---@return pesto.TargetSection
function TargetSection:new(params)
	---@type pesto.TargetSection
	local o = setmetatable({}, TargetSection)

	o._label = params.label
	o._is_expanded = false
	o._is_successful = params.is_successful
	o._indent = string.rep(" ", params.indent_width)
	o._logs = params.failed_actions_logs
	o.buffer_section = params.buffer_section

	return o
end

function TargetSection:on_enter_key(cursor_pos)
	if cursor_pos[1] - 1 == self.buffer_section.start_row then
		self._is_expanded = not self._is_expanded
		self:set_lines()
	end
end

---@param row number
---@return boolean
function TargetSection:contains_line(row)
	return self.buffer_section:contains_line(row)
end

function TargetSection:set_lines()
	if not self.buffer_section:is_attached() then
		return
	end

	self.buffer_section:edit_lines({
		start_row = 0,
		end_row = -1,
		lines = {
			self:_get_header_line(),
		},
	})

	if self._is_expanded then
		self.buffer_section:edit_lines({
			start_row = 1,
			end_row = -1,
			lines = {
				self._indent .. "Loading...",
			},
		})

		---@param name string
		---@param log_load_result {value: string[]|nil, error: string|nil}
		local function get_laid_out_lines(name, log_load_result)
			---@type string
			local indent = self._indent .. self._indent
			---@type string[]
			local lines = {}
			if log_load_result.value ~= nil then
				if #log_load_result.value > 0 then
					local indented_log_lines = vim.tbl_map(function(line)
						return indent .. line
					end, log_load_result.value)
					local divider_line = indent .. "---"
					table.insert(lines, indent .. name)
					table.insert(lines, divider_line)
					table_util.append(lines, indented_log_lines)
					table.insert(lines, divider_line)
				end
			else
				table.insert(lines, self._indent .. " - " .. name)
				local error_line = string.format("%sError loading logs: %s", self._indent, log_load_result.error)
				table.insert(lines, error_line)
			end
			return lines
		end

		local log_line_promises = table_util.flat_map(self._logs, function(logs)
			return { logs.stdout or LazyPromise.resolved({}), logs.stderr or LazyPromise.resolved({}) }
		end)

		LazyPromise.all_settled(
			log_line_promises,
			---@param log_line_results {value: string[]|nil, error: string|nil}
			function(log_line_results)
				---@type string[]
				local log_lines = {}
				for i, log_line_result in ipairs(log_line_results) do
					---@type string
					local label
					if i % 2 == 0 then
						label = "stderr:"
					else
						label = "stdout:"
					end
					---@type string[]
					local laid_out_lines = get_laid_out_lines(label, log_line_result)
					table_util.append(log_lines, laid_out_lines)

					if #laid_out_lines > 0 and i < #log_line_results then
						-- Add spacer
						table.insert(log_lines, "")
					end
				end

				if #log_lines == 0 then
					table.insert(log_lines, string.format("%s%s(no logs)", self._indent, self._indent))
				end

				self:_set_logs(log_lines)
			end
		)
	end
end

---@private
---@param log_lines string[]
function TargetSection:_set_logs(log_lines)
	if self.buffer_section:is_attached() and self._is_expanded then
		self.buffer_section:edit_lines({
			start_row = 1,
			end_row = -1,
			lines = log_lines,
		})
	end
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

return TargetSection
