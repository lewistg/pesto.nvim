local M = {}

---@class pesto.BuildFinishedEvent
---@field private _build_event_json_loader pesto.BuildEventJsonLoader
---@field private _build_event_tree BuildEventTree|nil
---@field private _bep_file string|nil
---@field exit_code number
M.BuildFinishedEvent = {}
M.BuildFinishedEvent.__index = M.BuildFinishedEvent

---@param exit_code number
---@param bep_file string|nil
---@param build_event_json_loader pesto.BuildEventJsonLoader
function M.BuildFinishedEvent:new(exit_code, bep_file, build_event_json_loader)
	local o = setmetatable({}, M.BuildFinishedEvent)

	o.exit_code = exit_code
	o._bep_file = bep_file
	o._build_event_json_loader = build_event_json_loader

	return o
end

---@return BuildEventTree|nil
function M.BuildFinishedEvent:get_build_event_tree()
	if self._bep_file == nil then
		return nil
	elseif self._build_event_tree == nil then
		self._build_event_tree = self._build_event_json_loader:load(self._bep_file)
	end
	return self._build_event_tree
end

return M
