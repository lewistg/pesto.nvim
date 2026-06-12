---@class pesto.FunctionalTestHelper
---@field private nvim_chan number
local FunctionalTestHelper = {}
FunctionalTestHelper.__index = FunctionalTestHelper

---@param nvim_chan number
function FunctionalTestHelper:new(nvim_chan)
  local o = setmetatable({}, FunctionalTestHelper)

  o.nvim_chan = nvim_chan

  return o
end

function FunctionalTestHelper:install_remote_apis_helpers()
  return vim.rpcrequest(self.nvim_chan, 'nvim_exec2', ':Pesto install-remote-apis-helpers', {})
end

---@return boolean
function FunctionalTestHelper:are_remote_apis_helpers_installed()
  return vim.rpcrequest(
    self.nvim_chan,
    'nvim_exec_lua',
    string.format(
      "return require('pesto.components').functional_test_hooks:are_remote_apis_helpers_installed()"
    ),
    {}
  ) --[[@as boolean]]
end

---@param mode pesto.CliCompletionMode
function FunctionalTestHelper:set_completion_mode(mode)
  vim.rpcrequest(
    self.nvim_chan,
    'nvim_exec_lua',
    string.format(
      "require('pesto.components').functional_test_hooks:extend_global_table('pesto', { cli_completion = { mode = '%s' } })",
      mode
    ),
    {}
  )
end

---@param enabled boolean
function FunctionalTestHelper:set_config_enable_bep_integration(enabled)
  vim.rpcrequest(
    self.nvim_chan,
    'nvim_exec_lua',
    string.format(
      "require('pesto.components').functional_test_hooks:extend_global_table('pesto', { enable_bep_integration = %s })",
      tostring(enabled)
    ),
    {}
  )
end

function FunctionalTestHelper:get_temp_dir()
  return vim.rpcrequest(
    self.nvim_chan,
    'nvim_exec_lua',
    "return require('pesto.components').functional_test_hooks:get_temp_dir()",
    {}
  )
end

function FunctionalTestHelper:get_quickfix_buf_id()
  return vim.rpcrequest(
    self.nvim_chan,
    'nvim_exec_lua',
    "return require('pesto.components').functional_test_hooks:get_quickfix_buf_id()",
    {}
  )
end

function FunctionalTestHelper:get_quickfix_items()
  return vim.rpcrequest(
    self.nvim_chan,
    'nvim_exec_lua',
    "return require('pesto.components').functional_test_hooks:get_quickfix_items()",
    {}
  )
end

---@return {qf_item: any, line_index: number}[]
function FunctionalTestHelper:get_jumpable_quickfix_items()
  local qf_items = self:get_quickfix_items()
  local qf_items_with_index = {}
  for i, item in ipairs(qf_items or {}) do
    if item.bufnr ~= 0 then
      table.insert(qf_items_with_index, { qf_item = item, line_index = i })
    end
  end
  return qf_items_with_index
end

---@param qf_line_index 1-based line index
function FunctionalTestHelper:jump_via_quickfix_item(qf_line_index)
  return vim.rpcrequest(
    self.nvim_chan,
    'nvim_exec_lua',
    string.format(
      "return require('pesto.components').functional_test_hooks:jump_via_quickfix_item(0, %d)",
      qf_line_index
    ),
    {}
  )
end

--[[
-- Default runner helpers
--]]

---@param timeout_millis number
---@return number
function FunctionalTestHelper:wait_for_build(timeout_millis)
  local job_exit = vim.rpcrequest(
    self.nvim_chan,
    'nvim_exec_lua',
    string.format(
      "return require('pesto.components').functional_test_hooks:wait_for_build(%d)",
      timeout_millis
    ),
    {}
  )
  if job_exit == vim.NIL or job_exit == nil then
    error('Failed to get job exit code')
  end
  return job_exit
end

---@param tabpagenr number|nil
function FunctionalTestHelper:find_build_windows(tabpagenr)
  --- One of the windows should be the build window
  return vim.rpcrequest(
    self.nvim_chan,
    'nvim_exec_lua',
    string.format(
      "return require('pesto.components').build_window_manager:find_build_windows(%d)",
      tabpagenr or 0
    ),
    {}
  )
end

function FunctionalTestHelper:get_build_exit_code()
  --- One of the windows should be the build window
  return vim.rpcrequest(
    self.nvim_chan,
    'nvim_exec_lua',
    "return require('pesto.components').build_window_manager:get_build_exit_code()",
    {}
  )
end

return FunctionalTestHelper
