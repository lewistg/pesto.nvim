---@class pesto.QuickfixItemParser
---@field private _error_scratch_buf_nr number
local QuickfixItemParser = {}
QuickfixItemParser.__index = QuickfixItemParser

function QuickfixItemParser:new()
  local o = setmetatable({}, QuickfixItemParser)
  return o
end

---@param lines string[]
---@param errorformat pesto.ActionErrorformat
---@param workspace_root string
---@return any[]
function QuickfixItemParser:parse(lines, errorformat, workspace_root)
  if errorformat.strip_escape_codes then
    local ansi_escape_codes = require('pesto.util.ansi_escape_codes')
    lines = vim.iter(lines):map(ansi_escape_codes.strip_csi_commands):totable()
  end
  local error_scratch_buf_nr = self:_get_scratch_buf_nr()
  self:_set_errorformat_settings(error_scratch_buf_nr, errorformat)
  return vim.api.nvim_buf_call(error_scratch_buf_nr, function()
    -- Neovim's CWD may not be the workspace root. In my experience the file
    -- paths a Bazel compiler action outputs to stderr are relative to the
    -- workspace root. To get Neovim to handle these paths correctly when
    -- parsing the errors, we spoof a directory change message. See `:help
    -- quickfix-directory-stack` for more details.
    local enter_workspace_prefix_pattern = 'pesto.nvim - Entering workspace root: '
    local errorformat_with_enter_dir = '%D'
      .. enter_workspace_prefix_pattern
      .. '%f,'
      .. vim.o.errorformat
    table.insert(lines, 1, string.format(enter_workspace_prefix_pattern .. '%s', workspace_root))

    return vim.fn.getqflist({
      lines = lines,
      efm = errorformat_with_enter_dir,
    }).items
  end)
end

---@return number
function QuickfixItemParser:_get_scratch_buf_nr()
  if self._error_scratch_buf_nr == nil then
    self._error_scratch_buf_nr = vim.api.nvim_create_buf(false, false)
  end
  return self._error_scratch_buf_nr
end

---@private
---@param buf_nr number
---@param rule_errorformat pesto.ActionErrorformat
function QuickfixItemParser:_set_errorformat_settings(buf_nr, rule_errorformat)
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

return QuickfixItemParser
