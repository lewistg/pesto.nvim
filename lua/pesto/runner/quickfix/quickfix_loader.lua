---@class pesto.QuickfixLoader
---@field private _action_logs_quickfix_item_loader pesto.ActionLogsQuickfixItemLoader
---@field private _settings pesto.InternalSettings
---@field private _has_sent_missing_client_notification boolean
local QuickfixLoader = {}
QuickfixLoader.__index = QuickfixLoader

---@param action_logs_quickfix_item_loader pesto.ActionLogsQuickfixItemLoader
---@param settings pesto.InternalSettings
---@return pesto.QuickfixLoader
function QuickfixLoader:new(action_logs_quickfix_item_loader, settings)
  local o = setmetatable({}, QuickfixLoader)

  o._action_logs_quickfix_item_loader = action_logs_quickfix_item_loader
  o._settings = settings
  o._has_sent_missing_client_notification = false

  return o
end

---@param build_event_tree pesto.BuildEventTree
---@param on_first_quickfix_loaded function
function QuickfixLoader:load_quickfix(build_event_tree, on_first_quickfix_loaded)
  -- clear quickfix list
  vim.fn.setqflist({}, 'r', { title = 'pesto: bazel build', lines = {} })

  ---@type boolean
  local called_on_first_quickfix_loaded = false

  self._action_logs_quickfix_item_loader:get_quickfix_items(build_event_tree, function(qf_items)
    vim.fn.setqflist(qf_items, 'a')
    if not called_on_first_quickfix_loaded then
      on_first_quickfix_loaded()
      called_on_first_quickfix_loaded = true
    end
  end, function(err)
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
  end)
end

return QuickfixLoader
