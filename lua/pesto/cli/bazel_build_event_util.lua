local M = {}

---@type string
local BUILD_EVENT_JSON_FILE_OPTION = '--build_event_json_file'

local VALID_BAZEL_SUBCOMMANDS = {
  ['build'] = true,
  ['test'] = true,
  ['run'] = true,
}

---@param bazel_command string[]
---@return number|nil
local function find_bazel_subcommand_index(bazel_command)
  -- Start at 2 since we assume the first element is "bazel"
  for i = 2, #bazel_command do
    if VALID_BAZEL_SUBCOMMANDS[bazel_command[i]] then
      return i
    end
  end
  return nil
end

---@param bazel_command string[]
---@param temp_bep_file fun(): string Lazy value of the temp BEP file to use if needed
function M.inject_bep_option(bazel_command, temp_bep_file)
  local subcommand_index = find_bazel_subcommand_index(bazel_command)
  if subcommand_index == nil then
    return
  end

  for _, arg in ipairs(bazel_command) do
    if vim.startswith(arg, BUILD_EVENT_JSON_FILE_OPTION) then
      -- Do not override this option if it's already defined by the user
      return
    end
  end

  local bep_file = temp_bep_file()
  table.insert(bazel_command, subcommand_index + 1, BUILD_EVENT_JSON_FILE_OPTION)
  table.insert(bazel_command, subcommand_index + 2, bep_file)
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
