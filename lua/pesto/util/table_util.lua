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

---@generic T
---@param list T[]
---@param i number
---@param j number|nil
---@return fun(): T|nil
function M.slice_iter(list, i, j)
	i = math.max(1, i)
	if j == nil then
		j = #list
	end
	return function()
		if i <= #list and i <= j then
			local next = list[i]
			i = i + 1
			return next
		end
	end
end

---@generic T: table
---@param t T
---@return T
function M.deep_copy(t)
	local copy = {}
	for key, value in pairs(t) do
		if type(value) == "table" then
			copy[key] = M.deep_copy(value)
		else
			copy[key] = value
		end
	end
	return copy
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

return M
