--- Module-local aliases
---@alias _TargetRuleKind string
---@alias _ActionType string

---@class pesto.RemoteCacheInfo
---@field uri string
---@field remote_headers string[]

---@class pesto.QuickfixLoader
---@field private _build_event_file_loader pesto.BuildEventFileLoader
---@field private _settings pesto.InternalSettings
---@field private _error_scratch_buf_nr number|nil
---@field private _has_sent_missing_client_notification boolean
local QuickfixLoader = {}
QuickfixLoader.__index = QuickfixLoader

---@param build_event_file_loader pesto.BuildEventFileLoader
---@param settings pesto.InternalSettings
---@return pesto.QuickfixLoader
function QuickfixLoader:new(build_event_file_loader, settings)
  local o = setmetatable({}, QuickfixLoader)
  o._build_event_file_loader = build_event_file_loader
  o._settings = settings
  o._error_scratch_buf_nr = nil
  o._has_sent_missing_client_notification = false
  return o
end

---@param build_event_tree pesto.BuildEventTree
---@param on_first_quickfix_loaded function
function QuickfixLoader:load_quickfix(build_event_tree, on_first_quickfix_loaded)
  -- clear quickfix list
  vim.fn.setqflist({}, 'r', { title = 'pesto: bazel build', lines = {} })

  local workspace_dir = self:_get_workspace_directory(build_event_tree)

  local logger = require('pesto.logger')

  local BuildEventTreeQueries = require('pesto.bazel.build_event_tree_queries')
  local build_event_tree_queries = BuildEventTreeQueries:new(build_event_tree)

  ---@type pesto.bep.BuildEvent[]
  local failed_actions = build_event_tree_queries:find_failed_action_completed_events()

  logger.debug(string.format('Found %d failed action(s)', #failed_actions))

  local BuildEventFileLoader = require('pesto.bazel.build_event_file_loader')
  ---@type pesto.RemoteCacheInfo|nil
  local remote_cache_info
  ---@type boolean
  local called_on_first_quickfix_loaded = false

  vim.iter(failed_actions):each(function(action_completed_event)
    ---@type string|nil
    local stderr_uri = vim.tbl_get(action_completed_event, 'action', 'stderr', 'uri')
    if stderr_uri == nil then
      logger.trace(string.format('Failed to extract stderr_uri'))
      return
    end

    if BuildEventFileLoader.is_byte_stream_uri(stderr_uri) and remote_cache_info == nil then
      remote_cache_info = self:_get_remote_cache_info(build_event_tree)
      if remote_cache_info == nil then
        error('Failed to find "remote_cache" command line option')
      else
        logger.info(string.format('Extracted remote cache URI: %s', remote_cache_info.uri))
      end
    end

    logger.trace(string.format('Fetching stderr logs. uri=%s', stderr_uri))

    self._build_event_file_loader:fetch_file({
      uri = stderr_uri,
      on_load = function(stderr_lines)
        logger.debug(string.format('Fetched stderr logs. uri=%s', stderr_uri))
        local action_errorformat = self:_get_action_errorformat(action_completed_event)
        if action_errorformat then
          if action_errorformat.strip_escape_codes then
            logger.trace(string.format('Stripping ANSI CSI commands from logs. uri=%s', stderr_uri))
            local ansi_escape_codes = require('pesto.util.ansi_escape_codes')
            stderr_lines =
              vim.iter(stderr_lines):map(ansi_escape_codes.strip_csi_commands):totable()
          end
          local error_scratch_buf_nr = self:_get_scratch_buf_nr()
          self:_set_errorformat_settings(error_scratch_buf_nr, action_errorformat)
          vim.api.nvim_buf_call(error_scratch_buf_nr, function()
            self:_append_quickfix_items(workspace_dir, stderr_lines, vim.o.errorformat)
          end)
          if not called_on_first_quickfix_loaded then
            on_first_quickfix_loaded()
            called_on_first_quickfix_loaded = true
          end
        end
      end,
      on_error = function(err)
        if
          err == BuildEventFileLoader.BazelRemoteHelpersNotSetupError
          and not self._has_sent_missing_client_notification
        then
          vim.notify(
            table.concat({
              'Pesto: Cannot load quickfix',
              '',
              'Failed action logs are stored remotely, and a download client has not been configured.',
              "Run `:Pesto install-remote-apis-helpers` to use Pesto's default client.",
              'For more information see `:help pesto-bazel-remote-apis-helpers`.',
            }, '\n'),
            vim.log.levels.WARN
          )
          self._has_sent_missing_client_notification = true
        else
          logger.error(
            string.format('Error loading action stderr file %s: %s', stderr_uri, tostring(err))
          )
        end
      end,
      remote_cache_uri = vim.tbl_get(remote_cache_info or {}, 'uri'),
      remote_headers = vim.tbl_get(remote_cache_info or {}, 'remote_headers'),
    })
  end)
end

---@param workspace_dir string absolute path to the Bazel workspace's root
---@param stderr_lines string[] path to failed Bazel action's stderr output
---@param errorformat string errorformat string (see :help errorformat)
function QuickfixLoader:_append_quickfix_items(workspace_dir, stderr_lines, errorformat)
  -- Neovim's CWD may not be the workspace root. In my experience the file
  -- paths a Bazel compiler action outputs to stderr are relative to the
  -- workspace root. To get Neovim to handle these paths correctly when
  -- parsing the errors, we spoof a directory change message. See `:help
  -- quickfix-directory-stack` for more details.

  local enter_workspace_prefix_pattern = 'pesto.nvim - Entering workspace root: '
  local errorformat_with_enter_dir = '%D' .. enter_workspace_prefix_pattern .. '%f,' .. errorformat

  table.insert(
    stderr_lines,
    1,
    string.format(enter_workspace_prefix_pattern .. '%s', workspace_dir)
  )

  vim.fn.setqflist({}, 'a', {
    lines = stderr_lines,
    efm = errorformat_with_enter_dir,
  })
end

---@param build_event_tree pesto.BuildEventTree
---@return string
function QuickfixLoader:_get_workspace_directory(build_event_tree)
  local build_started_event = build_event_tree:find_events_by_kind({ 'started' })[1]
  return build_started_event.started.workspace_directory
end

---@return number
function QuickfixLoader:_get_scratch_buf_nr()
  if self._error_scratch_buf_nr == nil then
    self._error_scratch_buf_nr = vim.api.nvim_create_buf(false, false)
  end
  return self._error_scratch_buf_nr
end

---@param build_event_tree pesto.BuildEventTree
---@return pesto.RemoteCacheInfo|nil
function QuickfixLoader:_get_remote_cache_info(build_event_tree)
  local BuildEventsTreeQueries = require('pesto.bazel.build_event_tree_queries')
  local build_event_tree_queries = BuildEventsTreeQueries:new(build_event_tree)

  local remote_cache_option = build_event_tree_queries:find_command_line_option(
    'canonical',
    'remote_cache'
  )[1] or build_event_tree_queries:find_command_line_option('canonical', 'remote_executor')[1]

  if not remote_cache_option or not remote_cache_option.option_value then
    return nil
  end

  local remote_headers =
    build_event_tree_queries:find_command_line_option('canonical', 'remote_header')

  return {
    uri = remote_cache_option.option_value,
    remote_headers = vim
      .iter(remote_headers)
      :map(function(h)
        return h.option_value
      end)
      :totable(),
  }
end

---@param failed_action_completed_event pesto.bep.BuildEvent
---@return pesto.ActionErrorformat|nil
function QuickfixLoader:_get_action_errorformat(failed_action_completed_event)
  ---@type pesto.ActionErrorformat|nil
  local action_errorformat = vim
    .iter(self._settings:get_errorformats())
    :find(function(action_errorformat)
      ---@type string[]
      local mnemonic_patterns
      if type(action_errorformat.action_mnemonic) == 'string' then
        mnemonic_patterns = { action_errorformat.action_mnemonic }
      else
        mnemonic_patterns = action_errorformat.action_mnemonic
      end
      return vim.iter(mnemonic_patterns):any(function(mnemonic_pattern)
        return string.match(
          vim.tbl_get(failed_action_completed_event, 'action', 'type'),
          mnemonic_pattern
        )
      end)
    end)
  local logger = require('pesto.logger')
  logger.debug(function()
    local id_key = failed_action_completed_event.id_key or ''
    local action_mnemonic = vim.tbl_get(failed_action_completed_event, 'action', 'type')
    return string.format(
      'Failed to find errorforamt for action. action_id_key=%s, action_mnemonic=%s',
      id_key or '',
      action_mnemonic or ''
    )
  end)
  return action_errorformat
end

---@param buf_nr number
---@param rule_errorformat pesto.ActionErrorformat
function QuickfixLoader:_set_errorformat_settings(buf_nr, rule_errorformat)
  if rule_errorformat.errorformat ~= nil then
    vim.bo[buf_nr].errorformat = rule_errorformat.errorformat
  elseif rule_errorformat.compiler ~= nil then
    vim.api.nvim_buf_call(buf_nr, function()
      vim.cmd({
        cmd = 'compiler',
        args = { rule_errorformat.compiler },
      })
    end)
  end
end

return QuickfixLoader
