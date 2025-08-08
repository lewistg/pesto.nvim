---@class pesto.LazyPromise
---@field private _pending_callbacks {on_resolved: fun(value: any), on_error: fun(error: any)}[]
---@field private _state "pending"|"calculating"|"resolved"|"error"
---@field private _get_async_value fun(on_resolved: fun(value), on_error: fun(error))|nil
---@field private _value any
---@field private _error any
local LazyPromise = {}
LazyPromise.__index = LazyPromise

---@param get_value_async fun(resolve: fun(value: any), reject: fun(error: any))
---@return pesto.LazyPromise
function LazyPromise:new(get_value_async)
	local o = setmetatable({}, LazyPromise)

	o._pending_callbacks = {}
	o._state = "pending"
	o._get_async_value = get_value_async

	return o
end

---@return pesto.LazyPromise
function LazyPromise.resolved(value)
	local lazy_promise = LazyPromise:new(function() end)
	lazy_promise._value = value
	lazy_promise._state = "resolved"
	return lazy_promise
end

---@param on_resolved fun(value: any)
---@param on_error fun(error: any)
function LazyPromise:get_value(on_resolved, on_error)
	if self._state == "resolved" then
		on_resolved(self._value)
	elseif self._state == "error" then
		on_error(self._error)
	else
		assert(self._state == "pending")
		assert(self._get_async_value ~= nil)
		table.insert(self._pending_callbacks, {
			on_resolved = on_resolved,
			on_error = on_error,
		})
		local function _on_error(error)
			self:_on_error(error)
			self._state = "error"
		end
		local status, ret = pcall(self._get_async_value, function(value)
			self._value = value
			self:_on_resolved(self._value)
			self._state = "resolved"
		end, _on_error)
		if not status then
			_on_error(ret)
		end
	end
end

---@private
function LazyPromise:_on_resolved(value)
	for _, callbacks in ipairs(self._pending_callbacks) do
		callbacks.on_resolved(value)
	end
end

---@private
function LazyPromise:_on_error(error)
	for _, callbacks in ipairs(self._pending_callbacks) do
		callbacks.on_error(error)
	end
end

---@param promises pesto.LazyPromise[]
---@param on_all_settled fun(results: {value: any|nil, error: any|nil})
function LazyPromise.all_settled(promises, on_all_settled)
	if #promises == 0 then
		on_all_settled({})
		return
	end
	---@type {value: any|nil, error: any|nil}[]
	local results = {}
	---@type number
	local num_unsettled = #promises
	for i, promise in ipairs(promises) do
		promise:get_value(function(value)
			results[i] = { value = value }
			num_unsettled = num_unsettled - 1
			if num_unsettled == 0 then
				on_all_settled(results)
			end
		end, function(error)
			results[i] = { error = error }
			num_unsettled = num_unsettled - 1
			if num_unsettled == 0 then
				on_all_settled(results)
			end
		end)
	end
end

return LazyPromise
