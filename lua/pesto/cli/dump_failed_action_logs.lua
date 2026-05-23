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

  ---@type pesto.bep.BuildEvent[]
  local failed_action_events = vim
    .iter(build_tree:find_events_by_kind({ 'action_completed' }))
    :filter(function(action_completed_event)
      if action_completed_event and action_completed_event.action then
        return not action_completed_event.success
      end
      return true
    end)
    :totable()

  local logger = require('pesto.logger')
  logger.info(string.format('found %d failed action_completed events', #failed_action_events))

  if vim.tbl_count(failed_action_events) == 0 then
    vim.notify('No failed action logs to dump', vim.log.levels.INFO)
    return
  end

  local file_index = -1
  local function get_next_filename(action_mnemonic)
    file_index = file_index + 1
    return string.format('%s-%d', action_mnemonic, file_index)
  end

  local uri_to_dump_file = vim
    .iter(failed_action_events)
    :fold({}, function(acc, failed_action_event)
      local stderr_uri = vim.tbl_get(failed_action_event, 'action', 'stderr', 'uri')
      local action_mnemonic = vim.tbl_get(failed_action_event, 'action', 'type')
      if not stderr_uri then
        logger.error(
          string.format('failed get action stderr uri for action %s', failed_action_event.id_key)
        )
      end
      if not action_mnemonic then
        logger.error(
          string.format(
            'failed get action action_mnemonic for action %s',
            failed_action_event.id_key
          )
        )
      end
      acc[stderr_uri] = get_next_filename(action_mnemonic)
      return acc
    end)

  local successes = 0
  local failures = 0
  vim.iter(pairs(uri_to_dump_file)):each(function(uri, file_name)
    self._build_event_file_loader:fetch_file({
      uri = uri,
      on_load = function(lines)
        local path = vim.fs.joinpath(dest_dir, file_name)
        vim.fn.writefile(lines, path, '')
        successes = successes + 1
      end,
      on_error = function(err)
        logger.debug(
          string.format('failed to fetch file. uri=%s, file=%s, error=%s', uri, file_name, err)
        )
        failures = failures + 1
      end,
    })
  end)

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
