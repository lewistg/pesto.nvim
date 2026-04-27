---@class pesto.QueryTargetsOpts
---@field run_bazel_context pesto.RunBazelContext
---@field on_success fun(labels: string[])
---@field on_error fun(err: string, stderr_lines)

---@class pesto.BuildSubcommand: pesto.Subcommand
---@field _settings pesto.InternalSettings
local BuildSubcommand = {}
BuildSubcommand.__index = BuildSubcommand

BuildSubcommand.name = 'build'

---@param settings pesto.InternalSettings
---@return pesto.BuildSubcommand
function BuildSubcommand:new(settings)
  local o = setmetatable({}, BuildSubcommand)

  o._settings = settings

  o.execute = function(opts)
    o:_execute(opts)
  end

  return o
end

---@param opts pesto.SubcommandExecuteOpts
function BuildSubcommand:_execute(opts)
  local logger = require('pesto.logger')

  -- Run the query
  vim.notify('Pesto: Querying targets...')

  local runner = require('pesto.runner.runner')
  local context = runner.get_run_bazel_context()
  self:_query_targets({
    run_bazel_context = context,
    on_success = function(labels)
      -- This callback calls some "non-fast" functions
      vim.schedule(function()
        logger.trace(string.format('successfully queried targets: %s', table.concat(labels, ',')))

        if #labels == 0 then
          vim.notify("Pesto: Query didn't return any targets", vim.log.levels.ERROR)
          return
        end
        local bazel_command = {
          self._settings:get_bazel_command(),
          'build',
          unpack(labels),
        }
        self._settings:get_bazel_runner()({
          bazel_command = bazel_command,
          context = context,
        })
      end)
    end,
    on_error = function(err, stderr)
      vim.schedule(function()
        vim.notify('Pesto: Target query failed. See logs for more details', vim.log.levels.ERROR)
        logger.error(string.format('bazel query failed. error=%s, stderr=%s', err, stderr))
      end)
    end,
  })
end

---@param opts pesto.QueryTargetsOpts
function BuildSubcommand:_query_targets(opts)
  if opts.run_bazel_context.package_dir == nil then
    opts.on_error('failed to resolve package directory')
  end

  local bazel_repo = require('pesto.bazel.repo')
  local package_label = bazel_repo.get_package_label()

  ---@type string[]
  local query_command = {
    self._settings:get_bazel_command(),
    'query',
    string.format('kind(rule, %s:*)', package_label),
  }

  local logger = require('pesto.logger')
  logger.trace(string.format('running query: %s', table.concat(query_command, ' ')))

  vim.system(query_command, {
    cwd = opts.run_bazel_context.workspace_dir,
    text = true,
  }, function(result)
    if result.code ~= 0 then
      opts.on_error(
        string.format('query exited with non-zero exit code: %d', result.code),
        result.stderr
      )
      return
    elseif result.stdout == nil then
      opts.on_success({})
      return
    end
    local lines = vim
      .iter(string.gmatch(result.stdout, '([^\n]*)\n'))
      :filter(function(line)
        return line:len() > 0
      end)
      :totable()
    opts.on_success(lines)
  end)
end

return BuildSubcommand
