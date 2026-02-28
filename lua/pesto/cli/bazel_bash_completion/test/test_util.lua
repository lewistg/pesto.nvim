local M = {}

---@param command_with_cursor string
---@return string line The command line string without the cursor
---@return number cursor_pos The cursor position in the string without cursor (0-indexed)
function M.parse_command_test_case(command_with_cursor)
	local cursor_pos = command_with_cursor:find("|")
	assert(cursor_pos ~= nil, "Did not find cursor")
	return command_with_cursor:gsub("|", ""), cursor_pos - 1
end

return M
