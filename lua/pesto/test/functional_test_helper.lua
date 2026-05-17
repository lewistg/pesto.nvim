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

function FunctionalTestHelper:get_temp_dir()
  return vim.rpcrequest(
    self.nvim_chan,
    'nvim_exec_lua',
    "return require('pesto.components').functional_test_hooks:get_temp_dir()",
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
