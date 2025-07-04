local table_util = require("pesto.util.table_util")
local BuildEvent = require("pesto.bazel.build_event")

---@class BuildEventTree
---@field private build_events {[string]: BuildEvent}
local BuildEventTree = {}
BuildEventTree.__index = BuildEventTree

---@param raw_events table[]
---@return BuildEventTree
function BuildEventTree:new(raw_events)
	local o = setmetatable({}, BuildEventTree)

	---@type {[string]: BuildEvent}
	o.build_events = {}
	for _, raw_event in ipairs(raw_events) do
		---@type BuildEvent
		local build_event = BuildEvent:new(raw_event)
		o.build_events[build_event.id_key] = build_event
	end
	return o
end

---@param event_kinds BuildEventKind[]
---@return BuildEvent[]
function BuildEventTree:find_events(event_kinds)
	local event_kind_set = table_util.make_set(event_kinds)
	---@type BuildEvent[]
	local events = {}
	for _, build_event in pairs(self.build_events) do
		local specific_id_type = table_util.some_key(build_event.id)
		if event_kind_set[specific_id_type] ~= nil then
			table.insert(events, build_event)
		end
	end
	return events
end

return BuildEventTree
