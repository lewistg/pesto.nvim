---@class pesto.MnemonicErrorformatResolver
---@field private _internal_config pesto.InternalConfig
local MnemonicErrorformatResolver = {}
MnemonicErrorformatResolver.__index = MnemonicErrorformatResolver

---@param internal_config pesto.InternalConfig
---@return pesto.MnemonicErrorformatResolver
function MnemonicErrorformatResolver:new(internal_config)
  local o = setmetatable({}, MnemonicErrorformatResolver)

  o._internal_config = internal_config

  return o
end

---@param action_mnemonic string
---@return pesto.ActionErrorformat|nil
function MnemonicErrorformatResolver:get_errorformat(action_mnemonic)
  return vim.iter(self._internal_config:get_errorformats()):find(function(action_errorformat)
    ---@type string[]
    local mnemonic_patterns
    if type(action_errorformat.action_mnemonic) == 'string' then
      mnemonic_patterns = { action_errorformat.action_mnemonic }
    else
      mnemonic_patterns = action_errorformat.action_mnemonic
    end
    return vim.iter(mnemonic_patterns):any(function(mnemonic_pattern)
      return string.match(action_mnemonic, mnemonic_pattern)
    end)
  end)
end

return MnemonicErrorformatResolver
