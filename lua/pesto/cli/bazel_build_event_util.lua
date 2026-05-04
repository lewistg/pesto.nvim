local M = {}

---@type string
local BUILD_EVENT_JSON_FILE_OPTION = '--build_event_json_file'

---@param bazel_command string[]
---@param temp_bep_file fun(): string Lazy value of the temp BEP file to use if needed
function M.inject_bep_option(bazel_command, temp_bep_file)
  local option_name = BUILD_EVENT_JSON_FILE_OPTION
  for _, arg in ipairs(bazel_command) do
    if vim.startswith(arg, option_name) then
      -- Do not override this option if it's already defined by the user
      return
    end
  end
  local bep_file = temp_bep_file()
  table.insert(bazel_command, 3, option_name)
  table.insert(bazel_command, 4, bep_file)
end

---@param bazel_command string[]
---@return string|nil
function M.extract_bep_option(bazel_command)
  ---@type number|nil
  for i, value in ipairs(bazel_command) do
    if value == BUILD_EVENT_JSON_FILE_OPTION then
      return bazel_command[i + 1]
    end
  end
end

return M
