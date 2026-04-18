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

function BuildEventTreeQueries:find_failed_action_logs()
  ---@type table<string, table<string, string>>
  local stderr_uris = {}
  for _, target_configured_event in
    ipairs(self._build_event_tree:find_events_by_kind({ 'target_configured' }))
  do
    for _, target_completed in
      ipairs(
        self._build_event_tree:find_child_event_by_kinds(
          target_configured_event,
          { 'target_completed' }
        )
      )
    do
      for _, action_completed in
        ipairs(
          self._build_event_tree:find_child_event_by_kinds(target_completed, { 'action_completed' })
        )
      do
        if vim.tbl_get(action_completed, 'action', 'failure_detail') ~= nil then
          ---@type string
          local rule_target_kind = self:_parse_rule_target_kind(
            vim.tbl_get(target_configured_event, 'configured', 'target_kind')
          ) or PESTO_UNKNOWN_ACTION_RULE_KIND
          ---@type string
          local action_type = vim.tbl_get(action_completed, 'action', 'type')
            or PESTO_UNKNOWN_EVENT_ACTION_TYPE
          if stderr_uris[rule_target_kind] == nil then
            stderr_uris[rule_target_kind] = {}
          end
          ---@type string|nil
          local stderr_uri = vim.tbl_get(action_completed, 'action', 'stderr', 'uri')
          stderr_uris[rule_target_kind][action_type] = stderr_uri
        end
      end
    end
  end
  return stderr_uris
end

---@return string
function BuildEventTreeQueries:_parse_rule_target_kind(target_kind)
  local _, _, rule_kind = string.find(target_kind, RULE_TARGET_KIND_PATTERN)
  return rule_kind
end

return BuildEventTreeQueries
