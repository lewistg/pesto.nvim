---@class LazyTable
---@field [string] any
---@field private cache table
---@field private lazy_values function
local LazyTable = {}

---@param lazy_table LazyTable
---@param key string
---@param lazy_value fun()
function LazyTable.__newindex(lazy_table, key, lazy_value)
	if type(lazy_value) ~= "function" then
		error(
			string.format(
				"Attempting to set field %s to a non-function value. All fields on a lazy table must be a functions that return the field's value",
				key
			)
		)
	end
	lazy_table.lazy_values[key] = lazy_value
end

---@param lazy_table LazyTable
---@param key string
function LazyTable.__index(lazy_table, key)
	if lazy_table.cache[key] == nil then
		lazy_table.cache[key] = lazy_table.lazy_values[key]()
	end
	return lazy_table.cache[key]
end

---@param lazy_fields? {[string]: fun(): any}
---@return LazyTable
function LazyTable:new(lazy_fields)
	local o = setmetatable(lazy_fields or {}, LazyTable)
	rawset(o, "cache", {})
	rawset(o, "lazy_values", {})
	return o
end

return LazyTable
