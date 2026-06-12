---@class pesto.LoadQuickfixSubcommand: pesto.Subcommand
---@field private _build_event_json_loader pesto.BuildEventJsonLoader
---@field private _quickfix_loader pesto.QuickfixLoader
local LoadQuickfixSubcommand = {}
LoadQuickfixSubcommand.__index = LoadQuickfixSubcommand

LoadQuickfixSubcommand.name = 'load-quickfix'

---@param build_event_json_loader pesto.BuildEventJsonLoader
---@param quickfix_loader pesto.QuickfixLoader
function LoadQuickfixSubcommand:new(build_event_json_loader, quickfix_loader)
  local o = setmetatable({}, LoadQuickfixSubcommand)

  o._build_event_json_loader = build_event_json_loader
  o._quickfix_loader = quickfix_loader

  o.execute = function(opts)
    o:_execute(opts)
  end

  return o
end

---@param opts pesto.SubcommandExecuteOpts
function LoadQuickfixSubcommand:_execute(opts)
  ---@type string|nil
  local bep_json_file = opts.fargs[1]

  if bep_json_file == nil then
    vim.notify("Pesto: Missing required argument '<bep-json-file>'", vim.log.levels.ERROR)
    return
  end

  local logger = require('pesto.logger')

  if not vim.uv.fs_stat(bep_json_file) then
    vim.notify(
      string.format('Pesto: BEP json file does not exist: %s', bep_json_file),
      vim.log.levels.ERROR
    )
    logger.error(string.format('BEP logs file does not exist: %s', bep_json_file))
    return
  end

  local build_event_tree = self._build_event_json_loader:load(bep_json_file)
  logger.debug(string.format('successfully loaded BEP JSON file: %s', bep_json_file))

  local bazel_repo = require('pesto.bazel.repo')
  local workspace_root = bazel_repo.find_project_root_dir()

  if workspace_root == nil then
    vim.notify(
      'Pesto: Failed to find workspace root. Is CWD in a Bazel workspace?',
      vim.log.levels.ERROR
    )
    return
  end

  self._quickfix_loader:load_quickfix({
    build_event_tree = build_event_tree,
    workspace_root = workspace_root,
    on_first_quickfix_loaded = function()
      vim.cmd.copen()
    end,
  })
end

return LoadQuickfixSubcommand
