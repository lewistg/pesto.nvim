local BufferSection = require("pesto.ui.util.buffer_section")
local BuildEventTree = require("pesto.bazel.build_event_tree")
local TargetListSection = require("pesto.ui.build_events_buffer.target_list_section")
local table_util = require("pesto.util.table_util")
local LazyPromise = require("pesto.util.lazy_promise")

---@class pesto.BazelTargetResult
---@field label string
---@field target_kind string|nil
---@field failed_actions_logs pesto.TargetActionLogs[]

---@class pesto.BuildEventsBuffer
---@field private _build_event_tree BuildEventTree|nil
---@field private _buf_id number
---@field private _target_list_sections pesto.TargetListSection[]
---@field private _root_buffer_section pesto.BufferSection
---@field private _failed_targets_section pesto.TargetListSection
---@field private _successful_targets_section pesto.TargetListSection
---@field private _build_event_file_loader pesto.BuildEventFileLoader
local BuildEventsBuffer = {}
BuildEventsBuffer.__index = BuildEventsBuffer

BuildEventsBuffer.FILE_TYPE = "pesto-build-summary"

---@param buf_id number
function BuildEventsBuffer.is_build_events_buffer(buf_id)
	return vim.api.nvim_buf_get_option(buf_id, "filetype") == BuildEventsBuffer.FILE_TYPE
end

---@param build_event_tree BuildEventTree
---@param build_event_file_loader pesto.BuildEventFileLoader
---@return pesto.BuildEventsBuffer
function BuildEventsBuffer:new(build_event_tree, build_event_file_loader)
	local o = setmetatable({}, BuildEventsBuffer)

	o._build_event_file_loader = build_event_file_loader

	local failure_bazel_target_results, successful_bazel_target_results = o:_load_events(build_event_tree)
	---@type {label: string, logs: pesto.TargetActionLogs[]}[]
	local failure_labels = vim.tbl_map(function(result)
		return {
			label = result.label,
			logs = result.failed_actions_logs,
		}
	end, failure_bazel_target_results)
	---@type {label: string, logs: pesto.TargetActionLogs[]}[]
	local successful_labels = vim.tbl_map(function(result)
		return {
			label = result.label,
		}
	end, successful_bazel_target_results)

	o._buf_id = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(o._buf_id, "filetype", BuildEventsBuffer.FILE_TYPE)
	vim.api.nvim_buf_set_option(o._buf_id, "modifiable", false)

	vim.api.nvim_buf_set_keymap(o._buf_id, "n", "<CR>", "", {
		callback = function()
			o:on_enter_key()
		end,
	})

	o._root_buffer_section = BufferSection:new({
		buf_id = o._buf_id,
		start_row = 0,
	})

	o._root_buffer_section:edit_lines({
		start_row = 0,
		end_row = 1,
		lines = { BuildEventsBuffer.HEADER_LINE, "" },
	})

	local failed_targets_buffer_section = BufferSection:new({
		buf_id = o._buf_id,
		start_row = 0,
	})
	o._root_buffer_section:edit_lines({
		start_row = 2,
		end_row = 2,
		lines = failed_targets_buffer_section,
	})

	-- Insert spacer
	o._root_buffer_section:edit_lines({
		start_row = 3,
		end_row = 3,
		lines = { "" },
	})

	o._failed_targets_section = TargetListSection:new({
		title = "Failed targets",
		targets = failure_labels,
		buffer_section = failed_targets_buffer_section,
		line_editor = self,
	})

	local successful_targets_buffer_section = BufferSection:new({
		buf_id = o._buf_id,
		start_row = 0,
	})
	o._root_buffer_section:edit_lines({
		start_row = 4,
		end_row = 4,
		lines = successful_targets_buffer_section,
	})
	o._successful_targets_section = TargetListSection:new({
		title = "Successful targets",
		targets = successful_labels,
		buffer_section = successful_targets_buffer_section,
		line_editor = self,
	})

	return o
end

---@type string
BuildEventsBuffer.HEADER_LINE = "Build summary"

function BuildEventsBuffer:get_buf_id()
	return self._buf_id
end

function BuildEventsBuffer:on_enter_key()
	local cursor_pos = vim.api.nvim_win_get_cursor(0)

	local target_list_sections = {
		self._failed_targets_section,
		self._successful_targets_section,
	}

	for _, target_list_section in ipairs(target_list_sections) do
		if target_list_section:contains_line(cursor_pos[1] - 1) then
			target_list_section:on_enter_key(cursor_pos)
		end
	end
end

---@private
---@param build_event_tree BuildEventTree
---@return pesto.BazelTargetResult[], pesto.BazelTargetResult[]
function BuildEventsBuffer:_load_events(build_event_tree)
	self._build_event_tree = build_event_tree

	---@type pesto.BuildEvent[]
	local target_complete_events = self._build_event_tree:find_events_by_kind({ "target_completed" })
	target_complete_events = vim.tbl_filter(function(target_completed_event)
		if not target_completed_event.id.target_completed.label then
			return nil
		end
		---@type pesto.BuildEventId
		local id = {
			target_configured = {
				label = target_completed_event.id.target_completed.label,
			},
		}
		---@type pesto.BuildEvent|nil
		local target_configured_event = build_event_tree:find_event_by_id(id)
		if
			target_configured_event
			and target_configured_event.configured
			and BuildEventTree.is_rule_kind(target_configured_event.configured.target_kind or "")
		then
			return target_completed_event
		end
	end, target_complete_events)

	---@type pesto.BazelTargetResult[]
	local successful_bazel_target_results = {}
	---@type pesto.BazelTargetResult[]
	local failure_bazel_target_results = {}

	for _, event in ipairs(target_complete_events) do
		assert(event.id.target_completed ~= nil, "Build event does not have a TargetCompletedId id")

		---@type pesto.TargetComplete
		local target_completed = event.completed

		local label = event.id.target_completed.label or "(unknown label)"

		if target_completed ~= nil and target_completed.success then
			---@type pesto.BazelTargetResult
			local target_result = {
				label = label,
				failed_actions_logs = {},
			}
			table.insert(successful_bazel_target_results, target_result)
		else
			---@type pesto.TargetActionLogs[]
			local failed_actions_logs = self:_get_failed_action_logs(event)
			---@type pesto.BazelTargetResult
			local target_result = {
				label = label,
				failed_actions_logs = failed_actions_logs,
			}
			table.insert(failure_bazel_target_results, target_result)
		end
	end

	return failure_bazel_target_results, successful_bazel_target_results
end

---@param target_completed_event pesto.BuildEvent
---@return pesto.TargetActionLogs[]
function BuildEventsBuffer:_get_failed_action_logs(target_completed_event)
	assert(target_completed_event.id.target_completed ~= nil, "Build event does not have a TargetCompletedId id")

	---@type pesto.BuildEvent[]
	local action_completed_events =
		self._build_event_tree:find_child_event_by_kinds(target_completed_event, { "action_completed" })
	---@type pesto.TargetActionLogs[]
	local failed_action_logs = {}
	for _, build_event in ipairs(action_completed_events) do
		if build_event.action and not build_event.action.success then
			---@type pesto.LazyPromise|nil
			local stdout_logs
			if build_event.action.stdout and build_event.action.stdout then
				stdout_logs = LazyPromise:new(function(resolve, reject)
					self._build_event_file_loader:load_file(build_event.action.stdout, resolve, reject)
				end)
			end

			---@type pesto.LazyPromise|nil
			local stderr_logs
			if build_event.action.stderr and build_event.action.stderr then
				stderr_logs = LazyPromise:new(function(resolve, reject)
					self._build_event_file_loader:load_file(build_event.action.stderr, resolve, reject)
				end)
			end

			table.insert(failed_action_logs, {
				stdout = stdout_logs,
				stderr = stderr_logs,
			})
		end
	end

	return failed_action_logs
end

return BuildEventsBuffer
