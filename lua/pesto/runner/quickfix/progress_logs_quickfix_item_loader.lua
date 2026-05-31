---@class pesto.ProgressLogsQuickfixItemLoader.FailedActionProgressLogs
---@field action_mnemonic string
---@field stdout_lines string[]

--- Parses quickfix items from Bazel's progress logs. This is a less precise
--- method than the pesto.ActionLogsQuickfixItemLoader, but it may be good
--- enough in many instance. When the action logs are stored in a remote cache,
--- ActionLogsQuickfixItemLoader must hit the network to fetch the fail action
--- logs. Progress are all local, so ProgressLogsQuickfixItemLoader does not
--- have this problem.
---@class pesto.ProgressLogsQuickfixItemLoader
---@field private _quickfix_item_parser pesto.QuickfixItemParser
---@field private _mnemonic_errorformat_resolver pesto.MnemonicErrorformatResolver
local ProgressLogsQuickfixItemLoader = {}
ProgressLogsQuickfixItemLoader.__index = ProgressLogsQuickfixItemLoader

ProgressLogsQuickfixItemLoader.ERROR_START_PATTERN = '^ERROR:.*error executing ([^%s]+) command.*'
ProgressLogsQuickfixItemLoader.INFO_START_PATTERN = '^INFO:.*'
ProgressLogsQuickfixItemLoader.NON_ERROR_BAZEL_LOG_PATTERNS = {
  ProgressLogsQuickfixItemLoader.INFO_START_PATTERN,
}
--- Sometimes Bazel emits these extra log lines. We do our best to filter them
--- out. Add more as you find them.
ProgressLogsQuickfixItemLoader.BAZEL_EXTRA_LINE_PATTERNS = {
  '^%s*Use %-%-verbose_failures to see the command lines of failed build steps.',
  '^%s*Use %-%-sandbox_debug to see verbose messages from the sandbox and retain the sandbox build root for debugging',
}

---@param quickfix_item_parser pesto.QuickfixItemParser
---@param mnemonic_errorformat_resolver pesto.MnemonicErrorformatResolver
---@return pesto.ProgressLogsQuickfixItemLoader
function ProgressLogsQuickfixItemLoader:new(quickfix_item_parser, mnemonic_errorformat_resolver)
  local o = setmetatable({}, ProgressLogsQuickfixItemLoader)

  o._quickfix_item_parser = quickfix_item_parser
  o._mnemonic_errorformat_resolver = mnemonic_errorformat_resolver

  return o
end

--- Parses the output from a bazel command run with the --nocurses flag. Like
--- this:
--- ```
--- bazel build --nocurses //foo/bar/baz
--- ```
---@param stdout_lines string[]
---@return pesto.ProgressLogsQuickfixItemLoader.FailedActionProgressLogs[] failed_action_progress_logs
function ProgressLogsQuickfixItemLoader.parse_no_curses_bazel_stdout(stdout_lines)
  ---@type pesto.ProgressLogsQuickfixItemLoader.FailedActionProgressLogs[]
  local failed_action_progress_logs = {}

  local stripped_lines = vim
    .iter(stdout_lines)
    :map(function(line)
      local ansi_escape_codes = require('pesto.util.ansi_escape_codes')
      local stripped_line = ansi_escape_codes.strip_csi_commands(line)
      stripped_line = string.gsub(stripped_line, '\r$', '')
      stripped_line = string.gsub(stripped_line, '^\r', '')
      return stripped_line
    end)
    :totable()

  ---@type pesto.ProgressLogsQuickfixItemLoader.FailedActionProgressLogs|nil
  local curr_entry = nil
  for _, line in ipairs(stripped_lines) do
    local is_terminator, action_mnemonic = ProgressLogsQuickfixItemLoader._is_terminator_line(line)
    if is_terminator then
      if curr_entry ~= nil then
        -- We just finished an error section
        table.insert(failed_action_progress_logs, curr_entry)
      end
      if action_mnemonic then
        curr_entry = {
          action_mnemonic = action_mnemonic,
          stdout_lines = {},
        }
      else
        curr_entry = nil
      end
    elseif curr_entry ~= nil then
      table.insert(curr_entry.stdout_lines, line)
    end
  end

  if curr_entry then
    table.insert(failed_action_progress_logs, curr_entry)
  end

  return vim
    .iter(failed_action_progress_logs)
    :map(function(progress_logs)
      progress_logs.stdout_lines =
        ProgressLogsQuickfixItemLoader._strip_extra_lines(progress_logs.stdout_lines)
      return progress_logs
    end)
    :totable()
end

---@return boolean is_terminator, string|nil action_mnemonic
function ProgressLogsQuickfixItemLoader._is_terminator_line(line)
  local action_mnemonic = line:match(ProgressLogsQuickfixItemLoader.ERROR_START_PATTERN)
  if action_mnemonic then
    return true, action_mnemonic
  end
  for _, pattern in ipairs(ProgressLogsQuickfixItemLoader.NON_ERROR_BAZEL_LOG_PATTERNS) do
    if string.match(line, pattern) then
      return true
    end
  end
  return false
end

function ProgressLogsQuickfixItemLoader._strip_extra_lines(lines)
  if #lines == 0 then
    return lines
  end
  local first = ProgressLogsQuickfixItemLoader._find_first_non_strippable_line(lines, 1)
  if first == nil then
    return lines
  end
  local last = ProgressLogsQuickfixItemLoader._find_first_non_strippable_line(lines, -1)
  -- If first is not nil, then last should not be either
  assert(last ~= nil)

  return vim
    .iter(lines)
    :slice(first, last)
    :filter(function(line)
      return vim
        .iter(ProgressLogsQuickfixItemLoader.BAZEL_EXTRA_LINE_PATTERNS)
        :all(function(pattern)
          return not string.match(line, pattern)
        end)
    end)
    :totable()
end

---@return number|nil
function ProgressLogsQuickfixItemLoader._find_first_non_strippable_line(lines, direction)
  local i
  local done
  if direction > 0 then
    i = 1
    direction = 1
    done = function()
      return i > #lines
    end
  else
    i = #lines
    direction = -1
    done = function()
      return i < 1
    end
  end

  local function is_strippable_line(line)
    if string.match(line, '^%s*$') then
      return true
    end
    return vim.iter(ProgressLogsQuickfixItemLoader.BAZEL_EXTRA_LINE_PATTERNS):any(function(pattern)
      return string.match(line, pattern)
    end)
  end

  while not done() do
    if not is_strippable_line(lines[i]) then
      return i
    end
    i = i + direction
  end

  return nil
end

---@param no_curses_stdout string[]
---@param workspace_root string
---@param on_items_loaded fun(qf_items: table[]) Called when a batch quickfix items have been parsed
---@param on_error fun(err: any) Called when an error occurs
function ProgressLogsQuickfixItemLoader:get_quickfix_items(
  no_curses_stdout,
  workspace_root,
  on_items_loaded,
  on_error
)
  local output_by_action_mnemonic =
    ProgressLogsQuickfixItemLoader.parse_no_curses_bazel_stdout(no_curses_stdout)

  local logger = require('pesto.logger')
  logger.trace(string.format('parsed %d failed action logs', #output_by_action_mnemonic))

  for _, entry in ipairs(output_by_action_mnemonic) do
    local errorformat = self._mnemonic_errorformat_resolver:get_errorformat(entry.action_mnemonic)
    if errorformat ~= nil then
      local items =
        self._quickfix_item_parser:parse(entry.stdout_lines, errorformat, workspace_root)
      on_items_loaded(items)
    else
      logger.warn(
        string.format(
          'failed to find errorformat for failed action. action_mnemonic=%s',
          entry.action_mnemonic
        )
      )
    end
  end
end

return ProgressLogsQuickfixItemLoader
