local M = {}

---@class pesto.OptionInjectionResult
---@field existing_option_value string|nil
---@field injected_option_value string|nil

---@class pesto.FindBazelOptionResult
---@field name string
---@field value string|nil

---@class pesto.BazelOptionSpec
---@field long_name string
---@field short_name string|nil
---@field has_value boolean|nil
---@field is_boolean boolean|nil

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
---@param option_spec pesto.BazelOptionSpec
---@return pesto.FindBazelOptionResult|nil
function M.find_option(bazel_command, option_spec)
  ---@param part_index number
  ---@param name string
  ---@return {name: string, value: string|nil}|nil
  local function parse_option(part_index, name)
    ---@type string
    local pattern
    if name:len() > 1 then
      pattern = '%-%-' .. name
    elseif name:len() == 1 then
      pattern = '%-' .. name
    else
      error(string.format('invalid option name: %s', name))
    end

    if not string.match(bazel_command[part_index], pattern) then
      return
    end
    local ret = {
      name = name,
    }
    if option_spec.has_value then
      ret.value = bazel_command[part_index + 1]
    end
    return ret
  end

  ---@param part_index number
  ---@param name string
  ---@return {name: string, value: string|nil}|nil
  local function parse_option_with_eq(part_index, name)
    if not option_spec.has_value then
      return
    end

    ---@type string
    local pattern
    if name:len() > 1 then
      pattern = '%-%-' .. name .. '=(.+)'
    elseif name:len() == 1 then
      pattern = '%-' .. name .. '=(.+)'
    else
      error(string.format('invalid option name: %s', name))
    end

    local _, value = string.match(bazel_command[part_index], pattern)
    if not value then
      return
    end
    return {
      name = name,
      value = value,
    }
  end

  ---@param part_index number
  ---@param name string
  ---@return {name: string, value: string|nil}|nil
  local function parse_no_option(part_index, name)
    if not option_spec.is_boolean then
      return
    end

    ---@type string
    local pattern
    if name:len() > 1 then
      pattern = '%-%-no' .. name
    else
      error(string.format('invalid option name: %s', name))
    end

    if string.match(bazel_command[part_index], pattern) then
      return {
        name = name,
        value = 'no',
      }
    end
  end

  ---@type {name: string, value: string|nil}|nil
  local ret
  for i, _ in ipairs(bazel_command) do
    ret = parse_option(i, option_spec.long_name)
      or (option_spec.short_name and parse_option(i, option_spec.short_name))
    if not ret and (option_spec.has_value or option_spec.is_boolean) then
      ret = parse_option_with_eq(i, option_spec.long_name)
        or (option_spec.short_name and parse_option_with_eq(i, option_spec.short_name))
    end
    if not ret and option_spec.is_boolean then
      ret = parse_no_option(i, option_spec.long_name)
    end
    if ret then
      break
    end
  end
  return ret
end

---@param bazel_command string[]
---@param bep_file fun(): string Lazy value of the temp BEP file to use if needed
---@return pesto.OptionInjectionResult
function M.inject_bep_option(bazel_command, bep_file)
  local subcommand_index = find_bazel_subcommand_index(bazel_command)
  if subcommand_index == nil then
    return {}
  end

  for _, arg in ipairs(bazel_command) do
    if vim.startswith(arg, BUILD_EVENT_JSON_FILE_OPTION) then
      -- Do not override this option if it's already defined by the user
      return {}
    end
  end

  local _bep_file = bep_file()
  table.insert(bazel_command, subcommand_index + 1, BUILD_EVENT_JSON_FILE_OPTION)
  table.insert(bazel_command, subcommand_index + 2, _bep_file)
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
