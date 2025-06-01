local M = {}

local iter_util = require("pesto.util.iter_util")

---@generic T
---@generic U
---@param list T[]
---@param fn fun(t: T): U
---@return U[]
function M.map(list, fn)
	local ret = {}
	for _, item in ipairs(list) do
		table.insert(ret, fn(item))
	end
	return ret
end

---@generic T
---@generic U
---@param list T[]
---@param fn fun(t: T): U[]
---@return U[]
function M.flat_map(list, fn)
	local ret = {}
	for _, item in ipairs(list) do
		for _, mapped_item in ipairs(fn(item)) do
			table.insert(ret, mapped_item)
		end
	end
	return ret
end

---@generic T
---@param list1 T[]
---@param list2 T[]
---@return T[]
function M.concat(list1, list2)
	local concated_list = {}
	for _, value in ipairs(list1) do
		table.insert(concated_list, value)
	end
	for _, value in ipairs(list2) do
		table.insert(concated_list, value)
	end
	return concated_list
end

---@generic T
---@param list T[]
---@param fn fun(t: T): boolean
---@return T[]
function M.filter(list, fn)
	local filtered_list = {}
	for _, value in ipairs(list) do
		if fn(value) then
			table.insert(filtered_list, value)
		end
	end
	return filtered_list
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
---@param target_value T
---@param are_equal fun(a: T, b: T): boolean
---@return T|nil, number|nil
function M.find(list, target_value, are_equal)
	are_equal = are_equal or function(a, b)
		return a == b
	end
	for i, value in ipairs(list) do
		if are_equal(value, target_value) then
			return value, i
		end
	end
	return nil, nil
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

---@generic K
---@generic V
---@param map {[K]: V}
function M.get_keys(map)
	local keys = {}
	for key, _ in pairs(map) do
		table.insert(keys, key)
	end
	return keys
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

return M
