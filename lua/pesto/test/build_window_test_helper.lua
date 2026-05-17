--- @class pesto.BuildWindowTestHelper
--- @field private _nvim_chan number
--- @field private _functional_test_helper pesto.FunctionalTestHelper
local BuildWindowTestHelper = {}
BuildWindowTestHelper.__index = BuildWindowTestHelper

function BuildWindowTestHelper:new(nvim_chan, functional_test_helper)
  local o = setmetatable({}, BuildWindowTestHelper)

  self._nvim_chan = nvim_chan
  self._functional_test_helper = functional_test_helper

  return o
end

function BuildWindowTestHelper:verify_build_window_opens()
  local assert = require('luassert')

  -- There should be two windows open in the current tab
  local curr_tab_page_nr =
    vim.rpcrequest(self._nvim_chan, 'nvim_call_function', 'tabpagenr', { '$' })

  -- There should be two windows open eventually
  local wait_status = vim.fn.wait(5 * 1000, function()
    local tab_info =
      vim.rpcrequest(self._nvim_chan, 'nvim_call_function', 'gettabinfo', { curr_tab_page_nr })
    assert(tab_info ~= nil)
    return #tab_info[1].windows == 2
  end)
  assert.are.equal(0, wait_status)

  --- One of the windows should be the build window
  local build_win_ids = self._functional_test_helper:find_build_windows()
  assert.are.equal(1, #build_win_ids)

  wait_status = vim.fn.wait(10 * 1000, function()
    return self._functional_test_helper:get_build_exit_code() == 0
  end)
  assert.are.equal(0, wait_status)
end

---@param tabpagenr number|nil
function BuildWindowTestHelper:find_build_windows(tabpagenr)
  --- One of the windows should be the build window
  local build_win_ids = self._functional_test_helper:find_build_windows()
  assert.are.equal(1, #build_win_ids)
end

return BuildWindowTestHelper
