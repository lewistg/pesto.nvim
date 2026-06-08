local M = {}

---@class pesto.OptionInjectionResult
---@field option_value string
---@field was_injected boolean

---@class pesto.FindBazelOptionResult
---@field name string
---@field value string|nil

---@alias pesto.BazelSubcommandName
---| "build"
---| "test"
---| "run"
---| "clean"

---@class pesto.BazelOptionSpec
---@field long_name string
---@field short_name string|nil
---@field has_value boolean|nil
---@field is_boolean boolean|nil
---@field category "startup" | pesto.BazelSubcommandName | "common"

---@type pesto.BazelOptionSpec
M.BUILD_EVENT_JSON_FILE_OPTION_SPEC = {
  long_name = 'build_event_json_file',
  has_value = true,
  category = 'common',
}

---@type pesto.BazelOptionSpec
M.ASYNC_OPTION_SPEC = {
  long_name = 'async',
  category = 'clean',
  is_boolean = true,
}

---@type pesto.BazelOptionSpec
M.CURSES_OPTION_SPEC = {
  long_name = 'curses',
  has_value = true,
  category = 'build',
}

---@param bazel_command string[]
---@param names {[pesto.BazelSubcommandName]: boolean}
---@return number|nil
local function find_bazel_subcommand_index(bazel_command, names)
  -- Start at 2 since we assume the first element is "bazel"
  for i = 2, #bazel_command do
    if names[bazel_command[i]] then
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
      pattern = '^%-%-' .. name .. '$'
    elseif name:len() == 1 then
      pattern = '^%-' .. name .. '$'
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
    if not option_spec.has_value and not option_spec.is_boolean then
      return
    end

    ---@type string
    local pattern
    if name:len() > 1 then
      pattern = '^%-%-' .. name .. '=(.+)$'
    elseif name:len() == 1 then
      pattern = '^%-' .. name .. '=(.+)$'
    else
      error(string.format('invalid option name: %s', name))
    end

    local value = string.match(bazel_command[part_index], pattern)
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

---@param option_spec pesto.BazelOptionSpec
---@return {[pesto.BazelSubcommandName]: boolean}
local function get_applicable_commands(option_spec)
  if option_spec.category == 'build' or option_spec.category == 'common' then
    --- The "test" and and "run" subcommands inherit "build"'s options
    return { ['build'] = true, ['test'] = true, ['run'] = true }
  elseif option_spec.category == 'test' then
    return { ['test'] = true }
  elseif option_spec.category == 'run' then
    return { ['run'] = true }
  end
  return {
    [option_spec.category --[[ @as pesto.BazelSubcommandName ]]] = true,
  }
end

--- Note: We don't currently handle all of bazel's options
---@param bazel_command string[]
---@param option_spec pesto.BazelOptionSpec
---@param value fun(): string Lazy value of the temp BEP file to use if needed
---@return pesto.OptionInjectionResult|nil
function M.inject_option(bazel_command, option_spec, value)
  local find_result = M.find_option(bazel_command, option_spec)
  if find_result then
    return {
      option_value = find_result.value,
      was_injected = false,
    }
  end

  local _value = value()

  if option_spec.category == 'startup' then
    table.insert(bazel_command, 2, '--' .. option_spec.long_name)
    table.insert(bazel_command, 3, _value)

    return {
      option_value = _value,
      was_injected = true,
    }
  else
    local subcommand_index =
      find_bazel_subcommand_index(bazel_command, get_applicable_commands(option_spec))
    if subcommand_index == nil then
      return nil
    end

    table.insert(bazel_command, subcommand_index + 1, '--' .. option_spec.long_name)
    table.insert(bazel_command, subcommand_index + 2, _value)

    return {
      option_value = _value,
      was_injected = true,
    }
  end
end

return M
