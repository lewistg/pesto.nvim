local table_util = require("pesto.util.table_util")
local BuildEvent = require("pesto.bazel.build_event")

---@class BuildEventTree
---@field private build_events {[string]: pesto.BuildEvent}
local BuildEventTree = {}
BuildEventTree.__index = BuildEventTree

---@param raw_events table[]
---@return BuildEventTree
function BuildEventTree:new(raw_events)
	local o = setmetatable({}, BuildEventTree)

	---@type {[string]: pesto.BuildEvent}
	o.build_events = {}
	for _, raw_event in ipairs(raw_events) do
		---@type pesto.BuildEvent
		local build_event = BuildEvent:new(raw_event)
		o.build_events[build_event.id_key] = build_event
	end
	return o
end

---@param build_event_id pesto.BuildEventId[]
---@return pesto.BuildEvent|nil
function BuildEventTree:find_event_by_id(build_event_id)
	local id_key = BuildEvent.get_id_key(build_event_id)
	return self.build_events[id_key]
end

---@param build_event pesto.BuildEvent
---@param event_kinds pesto.BuildEventKind[]
---@return pesto.BuildEvent[]
function BuildEventTree:find_child_event_by_kinds(build_event, event_kinds)
	local event_kind_set = table_util.make_set(event_kinds)
	local child_ids = vim.tbl_filter(function(id)
		local kind = table_util.some_key(id) --[[@as pesto.BuildEventKind]]
		return event_kind_set[kind] ~= nil
	end, build_event.children or {})

	---@type pesto.BuildEvent[]
	local child_events = {}
	for _, id in ipairs(child_ids) do
		local id_key = BuildEvent.get_id_key(id)
		local child_event = self.build_events[id_key]
		if child_event ~= nil then
			table.insert(child_events, child_event)
		end
	end

	return child_events
end

---@param event_kinds pesto.BuildEventKind[]
---@return pesto.BuildEvent[]
function BuildEventTree:find_events_by_kind(event_kinds)
	local event_kind_set = table_util.make_set(event_kinds)
	---@type pesto.BuildEvent[]
	local events = {}
	for _, build_event in pairs(self.build_events) do
		local specific_id_type = table_util.some_key(build_event.id)
		if event_kind_set[specific_id_type] ~= nil then
			table.insert(events, build_event)
		end
	end
	return events
end

---@type string target_kind
---@return string
function BuildEventTree.is_rule_kind(target_kind)
	return string.match(target_kind, ".* rule$")
end

return BuildEventTree
