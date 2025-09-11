local RULE_TARGET_KIND_PATTERN = "^(.*) rule$"
local PESTO_UNKNOWN_EVENT_ACTION_TYPE = "_PESTO_UNKNOWN_ACTION_TYPE_"
local PESTO_UNKNOWN_ACTION_RULE_KIND = "_PESTO_UNKNOWN_ACTION_RULE_KIND_"

--- Module-local aliases
---@alias _TargetRuleKind string
---@alias _ActionType string

---@class pesto.QuickfixLoader
---@field private _build_event_file_loader pesto.BuildEventFileLoader
---@field private _settings pesto.Settings
---@field private _error_scratch_buf_nr number|nil
local QuickfixLoader = {}
QuickfixLoader.__index = QuickfixLoader

---@param build_event_file_loader pesto.BuildEventFileLoader
---@param settings pesto.Settings
---@return pesto.QuickfixLoader
function QuickfixLoader:new(build_event_file_loader, settings)
	local o = setmetatable({}, QuickfixLoader)
	o._build_event_file_loader = build_event_file_loader
	o._settings = settings
	o._error_scratch_buf_nr = nil
	return o
end

---@param build_event_tree BuildEventTree
---@param on_first_quickfix_loaded function
function QuickfixLoader:load_quickfix(build_event_tree, on_first_quickfix_loaded)
	---@type table<_TargetRuleKind, table<_ActionType, string>>
	local stderr_uris = self:_get_failed_action_stderr(build_event_tree)

	local logger = require("pesto.logger")
	logger.debug(string.format("Loading the quickfix list. num_stderr_files_to_load=%s", #stderr_uris))

	-- clear quickfix list
	vim.fn.setqflist({}, "r", { title = "pesto: bazel build", lines = {} })

	local workspace_dir = self:_get_workspace_directory(build_event_tree)

	---@type boolean
	local called_on_first_quickfix_loaded = false
	for rule_kind, actions in pairs(stderr_uris) do
		for action_type, stderr_uri in pairs(actions) do
			logger.debug(
				string.format(
					"Loading errors from failed action. rule_kind=%s, action_mnemonic=%s, stderr_uri=%s",
					rule_kind,
					action_type,
					stderr_uri
				)
			)
			self._build_event_file_loader:maybe_download_file(stderr_uri, function(file_path)
				logger.debug(string.format("Loaded stderr file. file_path=%s", file_path))
				local action_errorformat = self:_get_errorformat(rule_kind, action_type)
				if action_errorformat then
					local error_scratch_buf_nr = self:_get_scratch_buf_nr()
					self:_set_errorformat_settings(error_scratch_buf_nr, action_errorformat)
					vim.api.nvim_buf_call(error_scratch_buf_nr, function()
						self:_append_quickfix_items(workspace_dir, file_path, vim.o.errorformat)
					end)
				end
				if not called_on_first_quickfix_loaded then
					on_first_quickfix_loaded()
					called_on_first_quickfix_loaded = true
				end
			end, function(error)
				logger.error(string.format("Error loading action stderr file %s: %s", stderr_uri, error))
			end)
		end
	end
end

---@param workspace_dir string absolute path to the Bazel workspace's root
---@param stderr_file string path to failed Bazel action's stderr output
---@param errorformat string errorformat string (see :help errorformat)
function QuickfixLoader:_append_quickfix_items(workspace_dir, stderr_file, errorformat)
	-- Neovim's CWD may not be the workspace root. In my experience the file
	-- paths a Bazel compiler action outputs to stderr are relative to the
	-- workspace root. To get Neovim to handle these paths correctly when
	-- parsing the errors, we spoof a directory change message. See `:help
	-- quickfix-directory-stack` for more details.

	local enter_workspace_prefix_pattern = "pesto.nvim - Entering workspace root: "
	local errorformat_with_enter_dir = "%D" .. enter_workspace_prefix_pattern .. "%f," .. errorformat

	local lines = vim.fn.readfile(stderr_file)
	table.insert(lines, 1, string.format(enter_workspace_prefix_pattern .. "%s", workspace_dir))

	vim.fn.setqflist({}, "a", {
		lines = lines,
		efm = errorformat_with_enter_dir,
	})
end

---@param build_event_tree BuildEventTree
---@return string
function QuickfixLoader:_get_workspace_directory(build_event_tree)
	local build_started_event = build_event_tree:find_events_by_kind({ "started" })[1]
	return build_started_event.started.workspace_directory
end

---@return number
function QuickfixLoader:_get_scratch_buf_nr()
	if self._error_scratch_buf_nr == nil then
		self._error_scratch_buf_nr = vim.api.nvim_create_buf(false, false)
	end
	return self._error_scratch_buf_nr
end

---@param build_event_tree BuildEventTree
---@return table<_TargetRuleKind, table<_ActionType, string>>
function QuickfixLoader:_get_failed_action_stderr(build_event_tree)
	local BuildEvent = require("pesto.bazel.build_event")
	---@type table<_TargetRuleKind, table<_ActionType, string>>
	local stderr_uris = {}
	for _, target_configured_event in ipairs(build_event_tree:find_events_by_kind({ "target_configured" })) do
		for _, target_completed in
			ipairs(build_event_tree:find_child_event_by_kinds(target_configured_event, { "target_completed" }))
		do
			for _, action_completed in
				ipairs(build_event_tree:find_child_event_by_kinds(target_completed, { "action_completed" }))
			do
				if vim.tbl_get(action_completed, "action", "failure_detail") ~= nil then
					---@type string
					local rule_target_kind = self:_parse_rule_target_kind(
						vim.tbl_get(target_configured_event, "configured", "target_kind")
					) or PESTO_UNKNOWN_ACTION_RULE_KIND
					---@type string
					local action_type = vim.tbl_get(action_completed, "action", "type")
						or PESTO_UNKNOWN_EVENT_ACTION_TYPE
					if stderr_uris[rule_target_kind] == nil then
						stderr_uris[rule_target_kind] = {}
					end
					---@type string|nil
					local stderr_uri = vim.tbl_get(action_completed, "action", "stderr", "uri")
					stderr_uris[rule_target_kind][action_type] = stderr_uri
				end
			end
		end
	end
	return stderr_uris
end

---@param rule_kind string
---@param action_type string
---@return pesto.ActionErrorformat|nil
function QuickfixLoader:_get_errorformat(rule_kind, action_type)
	local errorformats = self._settings:get_errorformats()
	for _, rule_action_errorformats in ipairs(errorformats) do
		if string.match(rule_kind, rule_action_errorformats.rule_kind) then
			for _, action_errorformat in ipairs(rule_action_errorformats.action_errorformats) do
				if string.match(action_type, action_errorformat.action_mnemonic) then
					return action_errorformat
				end
			end
		end
	end
	local logger = require("pesto.logger")
	logger.debug(string.format("Failed to find error format. rule_kind=%s, mnemonic=%s", rule_kind, action_type))
	return nil
end

---@param buf_nr number
---@param rule_errorformat pesto.ActionErrorformat
function QuickfixLoader:_set_errorformat_settings(buf_nr, rule_errorformat)
	if rule_errorformat.errorformat ~= nil then
		vim.bo[buf_nr].errorformat = rule_errorformat.errorformat
	elseif rule_errorformat.compiler ~= nil then
		vim.api.nvim_buf_call(buf_nr, function()
			vim.cmd({
				cmd = "compiler",
				args = { rule_errorformat.compiler },
			})
		end)
	end
end

---@return string
function QuickfixLoader:_parse_rule_target_kind(target_kind)
	local _, _, rule_kind = string.find(target_kind, RULE_TARGET_KIND_PATTERN)
	return rule_kind
end

return QuickfixLoader
