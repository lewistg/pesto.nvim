local table_util = require("pesto.util.table_util")

---@class BepTreeNode
---@field id_key string
---@field children {[string]: BepTreeNode}

---@class BepTree
local BepTree = {}

---@param raw_events table[]
function BepTree:new(raw_events)
	local o = setmetatable({}, BepTree)
end

---@param raw_events table[]
---@return {[string]: BuildEvent}
function BepTree:_set_ids(raw_events)
	---@type {[string]: BuildEvent}
	local events = {}
	for _, event in ipairs(raw_events) do
		local id = event["id"]
		if id == nil then
			error("Build event missing an ID")
		end
		local id_key = BepTree.get_id_key(id)

		id["id_key"] = id_key
		events[id_key] = event

		for _, child_event_id in ipairs(event.chidren or {}) do
			child_event_id["id_key"] = BepTree.get_id_key(child_event_id)
		end
	end
	return events
end

--- Gets a unique fingerprint for the build event ID
---@param build_event_id BuildEventId
---@return string
function BepTree.get_id_key(build_event_id)
	local specific_id_type = table_util.some_key(build_event_id)
	if type(specific_id_type) ~= "string" then
		error(string.format('unrecongized id type: "%s"', specific_id_type or ""))
	end
	---@param value table
	local function get_key(value)
		local sorted_keys = table_util.get_keys(value)
		table.sort(sorted_keys)
		local values = table_util.map(sorted_keys, function(k)
			local v = value[k]
			if type(v) == "table" then
				return get_key(v)
			else
				return tostring(v)
			end
		end)
		return table.concat(values, "_")
	end
	return specific_id_type .. ":" .. get_key(build_event_id)
end

return BepTree
