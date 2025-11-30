local M = {}

local iter_util = require("pesto.util.iter_util")

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

---@generic K
---@generic V
---@param entries {key: K,  value: V}
---@return {[K]: V}
function M.to_map(entries)
	local map = {}
	for _, entry in ipairs(entries) do
		map[entry[1]] = entry[2]
	end
	return map
end

---@generic T
---@param list T[]
---@param i number
---@param j number|nil
---@return T[]
function M.slice(list, i, j)
	return iter_util.to_list(M.slice_iter(list, i, j))
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

---@generic T
---@generic U
---@param list_1 T[]
---@param list_2 U[]
---@return {[1]: T, [2]: U}[]
function M.zip(list_1, list_2)
	local ret = {}
	local i = 1
	local j = math.min(#list_1, #list_2)
	while i <= j do
		table.insert(ret, { list_1[i], list_2[i] })
		i = i + 1
	end
	return ret
end

---@generic T
---@generic U
---@param tuples {[1]: T, [2]: U}[]
---@return T[], U[]
function M.unzip(tuples)
	local ts = {}
	local us = {}
	for _, tuple in ipairs(tuples) do
		local t, u = unpack(tuple)
		table.insert(ts, t)
		table.insert(us, u)
	end
	return ts, us
end

---@generic T
---@param list T[]
---@param filter fun(T): boolean
---@return T[]
function M.take_while(list, filter)
	local ret = {}
	for _, value in ipairs(list) do
		if filter(value) then
			table.insert(ret, value)
		else
			break
		end
	end
	return ret
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
