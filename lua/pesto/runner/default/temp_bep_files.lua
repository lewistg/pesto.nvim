---@class pesto.TempBepFiles
local TempBepFiles = {}
TempBepFiles.__index = TempBepFiles

function TempBepFiles:new()
  local o = setmetatable({}, TempBepFiles)
  return o
end

---@return string
function TempBepFiles:get_temp_bep_file()
  local temp_dirs = require('pesto.util.temp_dirs')
  local basename = string.format('%d_bep.json', vim.fn.rand())
  return vim.fs.joinpath(temp_dirs.BEP_DIR, basename)
end

---@param files_to_keep table<string, any> Basename of temp bep files that should be kept
function TempBepFiles:delete_old_files(files_to_keep)
  local temp_dirs = require('pesto.util.temp_dirs')
  local temp_bep_files_to_delete = vim.fs.find(function(name, _)
    return files_to_keep[name] == nil
  end, { limit = math.huge, type = 'file', path = temp_dirs.BEP_DIR })

  local logger = require('pesto.logger')
  logger.debug(string.format('cleaning up temp BEP %d file(s)', #temp_bep_files_to_delete))

  vim.iter(temp_bep_files_to_delete):each(function(temp_bep_file)
    vim.fn.delete(temp_bep_file)
  end)
end

return TempBepFiles
