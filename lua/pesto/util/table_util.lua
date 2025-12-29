local M = {}

---@generic T
---@generic U
---@param fn fun(t: T): U[]
---@param list T[]
---@return U[]
function M.flat_map(fn, list)
	return vim.tbl_flatten(vim.tbl_map(fn, list))
end

---@generic T
---@param ... T[]
---@return T[]
function M.concat(...)
	return vim.tbl_flatten({ ... })
end

---@generic T
---@generic U
---@param list T[]
---@param fn fun(accumulator: U, next_value: T): U
---@param initial_value U
---@return U
function M.reduce(list, fn, initial_value)
	local acc = initial_value
	for _, next_value in ipairs(list) do
		acc = fn(acc, next_value)
	end
	return acc
end

---@return string|nil
function M.some_key(dict_table)
	for key, _ in pairs(dict_table) do
		return key
	end
end

---@generic T
---@param ts `T`[]
---@return {[T]: boolean}
function M.make_set(ts)
	---@type {[`T`]: boolean}
	local t_set = {}
	for _, value in ipairs(ts) do
		t_set[value] = true
	end
	return t_set
end

---@generic T
---@param dict_table {[string]: T}
---@param key string
---@param default_value T
function M.get_or_set(dict_table, key, default_value)
	if dict_table[key] == nil then
		dict_table = default_value
	end
	return dict_table[key]
end

return M
