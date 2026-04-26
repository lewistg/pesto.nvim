---@class pesto.BuildSubcommand: pesto.Subcommand
local BuildSubcommand = {}
BuildSubcommand.__index = BuildSubcommand

BuildSubcommand.name = 'build'

---@return pesto.BuildSubcommand
function BuildSubcommand:new()
  local o = setmetatable({}, BuildSubcommand)

  o.execute = function(opts)
    o:_execute(opts)
  end

  return o
end

---@param opts pesto.SubcommandExecuteOpts
function BuildSubcommand:_execute(opts)
  vim.notify('todo')
end

return BuildSubcommand
