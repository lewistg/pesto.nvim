local M = {}

---@param match TSQueryMatch
---@param query vim.treesitter.Query
---@return {[string]: TSNode}[]
function M.get_match_captures_by_name(match, query)
  local parsed_match = {}
  for id, nodes in pairs(match) do
    local capture_name = query.captures[id]
    parsed_match[capture_name] = nodes[1]
  end
  return parsed_match
end

return M
