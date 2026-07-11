local M = {}

local NAME_PATTERN = '^%s*name%s*=%s*"([^"]*)"%s*,?$'

--- This method extracts the name attribute value in apparent rule calls such as this:
--- ```
--- java_library(
---    name = "LcovMergerTestUtils",
---    srcs = [ ... ],
---    deps = [ ... ],
--- )
--- ```
--- In this case this function returns "LcovMergerTestUtils"
---@param build_file string
---@return string[]
function M.guess_target_names(build_file)
  local status, lines = pcall(vim.fn.readfile, tostring(build_file))
  if not status then
    return {}
  end

  ---@type string[]
  local names = {}
  for _, line in ipairs(lines) do
    local _, _, name = string.find(line, NAME_PATTERN)
    if name then
      table.insert(names, name)
    end
  end
  return names
end

---@type vim.treesitter.Query|nil
local _rule_target_query

--- Some users may not have the starlark grammar installed, so we parse the
--- rule target query lazily instead of at the module-require time, which would
--- error.
---@return vim.treesitter.Query
local function get_rule_target_query()
  if _rule_target_query ~= nil then
    return _rule_target_query
  end
  _rule_target_query = vim.treesitter.query.parse(
    'starlark',
    [[
    (
      (expression_statement
        (call
          function: (identifier) @ruleTarget.functionIdentifier
          arguments: (argument_list
            (keyword_argument
              name: (identifier) @ruleTarget.argKeyword
              value: (string
                      (string_content) @ruleTarget.nameArgValue))))) @ruleTarget.wholeExpression
      (#eq? @ruleTarget.argKeyword "name")
    )
    ]]
  )
  return _rule_target_query
end

---@param buf_id number|nil
---@param position [number, number]|nil 0-indexed row, column indexes
---@return {rule_name: string, name: string}[]
function M.infer_rule_target_name_by_ts_query(buf_id, position)
  if vim.treesitter.language.add('starlark') ~= true then
    return {}
  end

  if buf_id == nil then
    buf_id = 0
  end

  -- Side effect: calling parse ensures the tree is up to date (see :help vim.treesitter.get_node())
  local status, ret = pcall(function()
    return vim.treesitter.get_parser(buf_id):parse()[1]
  end)
  if not status then
    return {}
  end
  ---@type TSTree
  local tree = ret

  local rule_target_query = get_rule_target_query()

  local treesitter_util = require('pesto.util.treesitter_util')
  local parsed_matches = vim
    .iter(rule_target_query:iter_matches(tree:root(), 0, 0, -1))
    :map(function(_, match)
      return treesitter_util.get_match_captures_by_name(match, rule_target_query)
    end)
  if position ~= nil then
    local position_range = vim.iter({ position, position }):flatten():totable()
    parsed_matches = parsed_matches:filter(function(parsed_match)
      return vim.treesitter.node_contains(
        parsed_match['ruleTarget.wholeExpression'],
        position_range
      )
    end)
  end

  return parsed_matches
    :map(function(parsed_match)
      return {
        rule_name = vim.treesitter.get_node_text(
          parsed_match['ruleTarget.functionIdentifier'],
          buf_id
        ),
        name = vim.treesitter.get_node_text(parsed_match['ruleTarget.nameArgValue'], buf_id),
      }
    end)
    :totable()
end

return M
