local M = {}

---@param str string
---@param prefix string
function M.starts_with(str, prefix)
	return str:sub(1, string.len(prefix)) == prefix
end

---@param str string
---@param suffix string
function M.ends_with(str, suffix)
	return str:find(suffix .. "$")
end

---@param str string
---@param separator string
---@param limit number
function M.split(str, separator, limit)
	local parts = {}
	local last_seprator_end = 0
	while true do
		local i, j
		if limit == nil or limit > 0 then
			i, j = str:find(separator, last_seprator_end + 1)
		end
		if not i then
			table.insert(parts, str:sub(last_seprator_end + 1))
			break
		end
		table.insert(parts, str:sub(last_seprator_end + 1, i - 1))
		if limit ~= nil then
			limit = limit - 1
		end
		last_seprator_end = j
	end
	return parts
end

return M
