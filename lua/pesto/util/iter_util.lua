local M = {}

---@generic T
---@alias iter fun(): T|nil

---@genric T
---@param iter iter
function M.to_list(iter)
	local ret = {}
	for value in iter do
		table.insert(ret, value)
	end
	return ret
end

return M
