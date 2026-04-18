local M = {}

---@class pesto.DumpFailedActionLogsSubcommand: pesto.Subcommand
---@field private _default_runner pesto.DefaultRunner
---@field private _build_event_file_loader pesto.BuildEventFileLoader
---@field private _dump_count number
local DumpFailedActionLogsSubcommand = {}
DumpFailedActionLogsSubcommand.__index = DumpFailedActionLogsSubcommand

DumpFailedActionLogsSubcommand.name = 'dump-failed-action-logs'

---@param default_runner pesto.DefaultRunner
---@param build_event_file_loader pesto.BuildEventFileLoader
---@return pesto.DumpFailedActionLogsSubcommand
function DumpFailedActionLogsSubcommand:new(default_runner, build_event_file_loader)
  local o = setmetatable({}, DumpFailedActionLogsSubcommand)

  o._default_runner = default_runner
  o._build_event_file_loader = build_event_file_loader
  o._dump_count = 0

  o.execute = function(opts)
    o:_execute(opts)
  end

  return o
end

---@param opts pesto.SubcommandExecuteOpts
function DumpFailedActionLogsSubcommand:_execute(opts)
  ---@type string|nil
  local dest_dir = opts.fargs[1]
  if dest_dir == nil then
    dest_dir = self:_get_next_dump_dir()
  elseif not vim.fn.isdirectory(dest_dir) then
    error(string.format('invalid dump dir: %s', dest_dir))
  end

  local build_tree = self._default_runner:get_build_event_tree()
  if build_tree == nil then
    vim.notify('Pesto: Cannot dump logs. No current build.', vim.log.levels.WARN)
    return
  end

  local BuildEventTreeQueries = require('pesto.bazel.build_event_tree_queries')
  local build_tree_queries = BuildEventTreeQueries:new(build_tree)

  local failed_action_log_uris = build_tree_queries:find_failed_action_logs()
  local file_names = self:_get_file_names(failed_action_log_uris)

  if vim.tbl_count(file_names) == 0 then
    vim.notify('No failed action logs to dump', vim.log.levels.INFO)
    return
  end

  local logger = require('pesto.logger')
  logger.info(string.format('fetching %d action log files', #file_names))

  local successes = 0
  local failures = 0
  for file_name, uri in pairs(file_names) do
    self._build_event_file_loader:fetch_file({
      uri = uri,
      on_load = function(lines)
        local path = vim.fs.joinpath(dest_dir, file_name)
        vim.fn.writefile(lines, path, '')
        successes = successes + 1
      end,
      on_error = function(err)
        logger.debug(string.format('Failed to fetch file. file=%s, error=%s', file_name, err))
        failures = failures + 1
      end,
    })
  end

  ---@type string[]
  local notification_lines = {}
  if successes > 0 then
    table.insert(
      notification_lines,
      string.format('Successfully dumped %d logs to %s', successes, dest_dir)
    )
  end
  if failures > 0 then
    table.insert(notification_lines, string.format('Failed to dump logs for %d actions', failures))
  end

  vim.notify(table.concat(notification_lines, '\n'), vim.log.levels.INFO)
end

---@param failed_action_log_uris table<string, table<string, string>>
---@return table<string, string>
function DumpFailedActionLogsSubcommand:_get_file_names(failed_action_log_uris)
  ---@type table<string, string>
  local file_names = {}

  ---@type number
  for rule_kind, failed_actions_uris in pairs(failed_action_log_uris) do
    local file_index = 0
    for action_mnemonic, uri in pairs(failed_actions_uris) do
      local file_name = string.format('%s-%s-%d', rule_kind, action_mnemonic, file_index)
      file_names[file_name] = uri
      file_index = file_index + 1
    end
  end

  return file_names
end

---@private
---@return string
function DumpFailedActionLogsSubcommand:_get_next_dump_dir()
  self._dump_count = self._dump_count + 1
  local temp_dir = require('pesto.util.temp_dirs')
  local path = vim.fs.joinpath(
    temp_dir.DEFAULT_FAILED_ACTION_LOGS_DUMP_DIR,
    'dump_' .. tostring(self._dump_count)
  )
  vim.fn.mkdir(path)
  return path
end

return DumpFailedActionLogsSubcommand
