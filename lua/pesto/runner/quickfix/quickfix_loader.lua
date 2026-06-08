---@class pesto.QuickfixLoader.LoadQuickfixOpts
---@field build_event_tree pesto.BuildEventTree|nil
---@field progress_logs string[]|nil
---@field workspace_root string
---@field on_first_quickfix_loaded function

---@class pesto.QuickfixLoader
---@field private _action_logs_quickfix_item_loader pesto.ActionLogsQuickfixItemLoader
---@field private _progress_logs_quickfix_item_loader pesto.ProgressLogsQuickfixItemLoader
---@field private _settings pesto.InternalSettings
---@field private _has_sent_missing_client_notification boolean
local QuickfixLoader = {}
QuickfixLoader.__index = QuickfixLoader

---@param action_logs_quickfix_item_loader pesto.ActionLogsQuickfixItemLoader
---@param progress_logs_quickfix_item_loader pesto.ProgressLogsQuickfixItemLoader
---@param settings pesto.InternalSettings
---@return pesto.QuickfixLoader
function QuickfixLoader:new(
  action_logs_quickfix_item_loader,
  progress_logs_quickfix_item_loader,
  settings
)
  local o = setmetatable({}, QuickfixLoader)

  o._action_logs_quickfix_item_loader = action_logs_quickfix_item_loader
  o._progress_logs_quickfix_item_loader = progress_logs_quickfix_item_loader
  o._settings = settings
  o._has_sent_missing_client_notification = false

  return o
end

---@param opts pesto.QuickfixLoader.LoadQuickfixOpts
function QuickfixLoader:load_quickfix(opts)
  -- clear quickfix list
  vim.fn.setqflist({}, 'r', { title = 'pesto: bazel build', lines = {} })

  ---@type boolean
  local called_on_first_quickfix_loaded = false

  local function on_items_loaded(qf_items)
    vim.fn.setqflist(qf_items, 'a')
    if not called_on_first_quickfix_loaded then
      opts.on_first_quickfix_loaded()
      called_on_first_quickfix_loaded = true
    end
  end

  local function on_error(err)
    local BuildEventFileLoader = require('pesto.bazel.build_event_file_loader')
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
    end
  end

  local logger = require('pesto.logger')
  if opts.build_event_tree then
    logger.trace('Loading quickfix from action logs')
    self._action_logs_quickfix_item_loader:get_quickfix_items(
      opts.build_event_tree,
      on_items_loaded,
      on_error
    )
  elseif opts.progress_logs then
    logger.trace('Loading quickfix from progress output')
    self._progress_logs_quickfix_item_loader:get_quickfix_items(
      opts.progress_logs,
      opts.workspace_root,
      on_items_loaded,
      on_error
    )
  else
    logger.error(
      'Cannot load quickfix items. Must build_event_tree or progress_logs must be defined'
    )
  end
end

return QuickfixLoader
