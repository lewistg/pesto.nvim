---@class pesto.DefaultRunner
---@field private _settings pesto.InternalSettings
---@field private _build_window_manager pesto.BuildWindowManager
---@field private _build_event_json_loader pesto.BuildEventJsonLoader
---@field private _quickfix_loader pesto.QuickfixLoader
---@field private _temp_bep_files pesto.TempBepFiles
---@field private _build_event_tree pesto.BuildEventTree|nil
---
--- Allowlist of of BEP files to keep when we cleanup previous BEP files. We
--- keep a small history BEP files in case we need to debug the BEP integration
--- and look at the actual build events.
---@field private _temp_bep_files_to_keep string[]
---
---@field private _builds_since_temp_bep_file_cleanup number
local DefaultRunner = {}
DefaultRunner.__index = DefaultRunner

DefaultRunner.TEMP_BEP_FILE_CLEANUP_INTERVAL = 10
DefaultRunner.MAX_TEMP_BEP_FILES_TO_KEEP = DefaultRunner.TEMP_BEP_FILE_CLEANUP_INTERVAL / 2

---@param settings pesto.InternalSettings
---@param build_window_manager pesto.BuildWindowManager
---@param build_event_json_loader pesto.BuildEventJsonLoader
---@param quickfix_loader pesto.QuickfixLoader
---@param temp_bep_files pesto.TempBepFiles
function DefaultRunner:new(
  settings,
  build_window_manager,
  build_event_json_loader,
  quickfix_loader,
  temp_bep_files
)
  local o = setmetatable({}, DefaultRunner)

  o._settings = settings
  o._build_window_manager = build_window_manager
  o._build_event_json_loader = build_event_json_loader
  o._quickfix_loader = quickfix_loader
  o._temp_bep_files = temp_bep_files
  o._temp_bep_files_to_keep = {}
  o._builds_since_temp_bep_file_cleanup = 0

  return o
end

---@param opts pesto.RunBazelOpts
function DefaultRunner.__call(self, opts)
  local logger = require('pesto.logger')

  ---@type pesto.QuickfixLogSource
  local quickfix_log_source = self._settings:get_quickfix_log_source()

  ---@type string|nil
  local bep_file = nil

  if self._settings:get_enable_bep_integration() or quickfix_log_source == 'bep' then
    bep_file = self:_inject_bep_file_option(opts.bazel_command)
  else
    local bazel_command = require('pesto.bazel.bazel_command')
    local result = bazel_command.inject_option(
      opts.bazel_command,
      bazel_command.CURSES_OPTION_SPEC,
      function()
        return 'no'
      end
    )
    if not result then
      logger.error('failed to inject nocurses option')
    end
  end

  self._build_event_tree = nil

  self._build_window_manager:start_new_build({
    term_command = opts.bazel_command,
    cwd = opts.context.package_dir or opts.context.workspace_dir,
    auto_open = self._settings:get_auto_open_build_term(),
    capture_stdout = quickfix_log_source == 'pty_output',
    on_exit = function(is_current, stdout_lines)
      self:_maybe_clean_temp_bep_files()
      if not is_current then
        return
      end

      local function on_first_quickfix_loaded()
        ---@diagnostic disable-next-line
        if self._build_window_manager:is_build_win_current() then
          local win_util = require('pesto.util.window')
          --- If the user is currently in the bazel terminal buffer, then we
          --- keep it focused so they can close it quickly after it finishes
          --- using one of the quick-exit hotkeys. (See usage of
          --- BuildWindowManager.BAZEL_TERM_BUF_QUICK_EXIT_KEYS)
          win_util.keep_current(function()
            --- Open the quickfix window above the bazel output window
            vim.cmd('leftabove copen')
          end)
        else
          vim.cmd.copen()
        end
      end

      if bep_file then
        if not vim.uv.fs_stat(bep_file) then
          logger.error(string.format('BEP logs file does not exist: %s', bep_file))
        else
          ---@diagnostic disable-next-line: invisible
          self._build_event_tree = self._build_event_json_loader:load(bep_file)
        end
      end

      if quickfix_log_source == 'bep' then
        ---@diagnostic disable-next-line: invisible
        self._quickfix_loader:load_quickfix({
          ---@diagnostic disable-next-line: invisible
          build_event_tree = self._build_event_tree,
          on_first_quickfix_loaded = on_first_quickfix_loaded,
          workspace_root = opts.context.workspace_dir,
        })
      elseif quickfix_log_source == 'pty_output' then
        if stdout_lines then
          ---@diagnostic disable-next-line: invisible
          self._quickfix_loader:load_quickfix({
            progress_logs = stdout_lines,
            on_first_quickfix_loaded = on_first_quickfix_loaded,
            workspace_root = opts.context.workspace_dir,
          })
        else
          logger.error("log source is 'pty_output' but stdout_lines were not captured")
        end
      else
        assert(false, string.format('unrecognized log source: %s', quickfix_log_source))
      end
    end,
    get_build_event_tree = function()
      ---@diagnostic disable-next-line: invisible
      return self._build_event_tree
    end,
  })
end

---@private
---@param bzl_command string[]
function DefaultRunner:_inject_bep_file_option(bzl_command)
  ---@type fun(): string
  local temp_bep_file = function()
    ---@diagnostic disable-next-line: invisible
    return self._temp_bep_files:get_temp_bep_file()
  end

  local bazel_command = require('pesto.bazel.bazel_command')
  local result = bazel_command.inject_option(
    bzl_command,
    bazel_command.BUILD_EVENT_JSON_FILE_OPTION_SPEC,
    temp_bep_file
  )
  if result then
    local bep_file = result.option_value
    if result.was_injected then
      self:_add_temp_bep_file(bep_file)
    end
    return bep_file
  else
    local logger = require('pesto.logger')
    logger.error('failed to inject BEP option')
  end
  return nil
end

---@private
---@param bep_file string
function DefaultRunner:_add_temp_bep_file(bep_file)
  table.insert(self._temp_bep_files_to_keep, 1, bep_file)
  while #self._temp_bep_files_to_keep > DefaultRunner.MAX_TEMP_BEP_FILES_TO_KEEP do
    table.remove(self._temp_bep_files_to_keep)
  end
end

function DefaultRunner:_maybe_clean_temp_bep_files()
  self._builds_since_temp_bep_file_cleanup = self._builds_since_temp_bep_file_cleanup + 1
  if self._builds_since_temp_bep_file_cleanup < DefaultRunner.TEMP_BEP_FILE_CLEANUP_INTERVAL then
    return
  end
  local table_util = require('pesto.util.table_util')
  local files_to_keep =
    table_util.make_set(vim.iter(self._temp_bep_files_to_keep):map(vim.fs.basename):totable())
  self._temp_bep_files:delete_old_files(files_to_keep)
  self._builds_since_temp_bep_file_cleanup = 0
end

---@return pesto.BuildEventTree|nil
function DefaultRunner:get_build_event_tree()
  return self._build_event_tree
end

return DefaultRunner
