local M = {}

local CSI_PATTERN = '\027%[[^a-zA-Z]*[a-zA-Z]'

---Strips out the "control sequence introducer" commands [1].
---
---[1]: https://en.wikipedia.org/wiki/ANSI_escape_code#Control_Sequence_Introducer_commands
---@param str string
---@return string
function M.strip_csi_commands(str)
  local stripped_str, _ = string.gsub(str, CSI_PATTERN, '')
  return stripped_str
end

return M
