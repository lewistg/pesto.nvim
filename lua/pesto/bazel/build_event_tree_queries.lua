local RULE_TARGET_KIND_PATTERN = '^(.*) rule$'
local PESTO_UNKNOWN_EVENT_ACTION_TYPE = '_PESTO_UNKNOWN_ACTION_TYPE_'
local PESTO_UNKNOWN_ACTION_RULE_KIND = '_PESTO_UNKNOWN_ACTION_RULE_KIND_'

--- Contains common, higher-level queries on a pesto.BuildEventTree
---@class pesto.BuildEventTreeQueries
---@field private _build_event_tree pesto.BuildEventTree
local BuildEventTreeQueries = {}
BuildEventTreeQueries.__index = BuildEventTreeQueries

---@param build_event_tree pesto.BuildEventTree
---@return pesto.BuildEventTreeQueries
function BuildEventTreeQueries:new(build_event_tree)
  local o = setmetatable({}, BuildEventTreeQueries)
  o._build_event_tree = build_event_tree
  return o
end

---@param command_line_label string
---@param option_name string
---@return pesto.bep.Option[]
function BuildEventTreeQueries:find_command_line_option(command_line_label, option_name)
  ---@type pesto.bep.BuildEvent
  local command_line_event = nil
  for _, event in ipairs(self._build_event_tree:find_events_by_kind({ 'structured_command_line' })) do
    if
      vim.tbl_get(event, 'structured_command_line', 'command_line_label') == command_line_label
    then
      command_line_event = event
      break
    end
  end

  if command_line_event == nil then
    return {}
  end

  ---@type pesto.bep.CommandLineSection|nil
  local command_line_section
  for _, section in
    ipairs(vim.tbl_get(command_line_event, 'structured_command_line', 'sections') or {})
  do
    local section_label = vim.tbl_get(section, 'section_label')
    if section_label == 'command options' then
      command_line_section = section
    end
  end

  if command_line_section == nil then
    return {}
  end

  return vim
    .iter(vim.tbl_get(command_line_section, 'option_list', 'option') or {})
    :filter(function(option)
      return vim.tbl_get(option, 'option_name') == option_name
    end)
    :totable()
end

---@return table<string, table<string, string[]>> stderr_uris Multi-level map: rule kind -> action type -> stderr uri.
function BuildEventTreeQueries:find_failed_action_logs()
  local table_util = require('pesto.util.table_util')

  --- Failed `action_completed` events by label
  ---@type table<string, pesto.bep.BuildEvent[]>
  local failed_action_completed_events = vim
    .iter(self._build_event_tree:find_events_by_kind({ 'action_completed' }))
    :fold({}, function(acc_action_completed_events, action_completed_event)
      -- Only get failed actions
      if vim.tbl_get(action_completed_event, 'action', 'failure_detail') == nil then
        return acc_action_completed_events
      end
      local label = vim.tbl_get(action_completed_event, 'id', 'action_completed', 'label')
      if label ~= nil then
        local action_completed_events =
          table_util.get_or_set(acc_action_completed_events, label, {})
        table.insert(action_completed_events, action_completed_event)
      end
      return acc_action_completed_events
    end)

  if vim.tbl_isempty(failed_action_completed_events) then
    return {}
  end

  --- `target_configured` events by label
  ---@type table<string, {event: pesto.bep.BuildEvent, rule_target_kind: string}>
  local target_configured_events = vim
    .iter(self._build_event_tree:find_events_by_kind({ 'target_configured' }))
    :fold({}, function(acc, target_configured_event)
      local label = vim.tbl_get(target_configured_event.id, 'target_configured', 'label')

      ---@type string
      local rule_target_kind = self:_parse_rule_target_kind(
        vim.tbl_get(target_configured_event, 'configured', 'target_kind')
      ) or PESTO_UNKNOWN_ACTION_RULE_KIND

      if label ~= nil then
        acc[label] = {
          event = target_configured_event,
          rule_target_kind = rule_target_kind,
        }
      end
      return acc
    end)

  ---@type table<string, table<string, string[]>>
  local stderr_uris = vim
    .iter(failed_action_completed_events)
    :fold({}, function(acc_stderr_uris, label, action_completed_events)
      if target_configured_events[label] == nil then
        local logger = require('pesto.logger')
        logger.error(string.format("failed to find 'target_configured' event for label: %s", label))
        return acc_stderr_uris
      end
      local rule_target_kind = target_configured_events[label].rule_target_kind
      for _, action_completed_event in pairs(action_completed_events) do
        ---@type string|nil
        local stderr_uri = vim.tbl_get(action_completed_event, 'action', 'stderr', 'uri')
        if stderr_uri then
          ---@type string
          local action_type = vim.tbl_get(action_completed_event, 'action', 'type')
            or PESTO_UNKNOWN_EVENT_ACTION_TYPE

          local stderr_uris = table_util.get_or_set(
            table_util.get_or_set(acc_stderr_uris, rule_target_kind, {}),
            action_type,
            {}
          )
          table.insert(stderr_uris, stderr_uri)
        end
      end
      return acc_stderr_uris
    end)

  return stderr_uris
end

---@return string
function BuildEventTreeQueries:_parse_rule_target_kind(target_kind)
  local _, _, rule_kind = string.find(target_kind, RULE_TARGET_KIND_PATTERN)
  return rule_kind
end

return BuildEventTreeQueries
