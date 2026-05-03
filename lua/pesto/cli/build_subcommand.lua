---@class pesto.QueryTargetsOpts
---@field query string
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

  o.complete = function(opts)
    return o:_complete(opts)
  end

  return o
end

---@param opts pesto.SubcommandCompleteOpts
---@return string[]
function BuildSubcommand:_complete(opts)
  local cli_util = require('pesto.util.cli')
  local query_ids = vim.tbl_keys(self._settings:get_build_target_resolvers())
  return cli_util.get_completion_candidates(opts.arg_lead, query_ids)
end

---@param opts pesto.SubcommandExecuteOpts
function BuildSubcommand:_execute(opts)
  local logger = require('pesto.logger')

  ---@type string|nil
  local resolver_id = opts.fargs[1]

  local settings = require('pesto.settings')
  local build_target_resolvers = self._settings:get_build_target_resolvers()

  ---@type pesto.TargetResolver|nil
  local target_resolver
  if resolver_id ~= nil then
    target_resolver = build_target_resolvers[resolver_id]
    if target_resolver == nil then
      vim.notify(
        string.format("Pesto: No resolver with ID '%s'", resolver_id),
        vim.log.levels.ERROR
      )
      return
    end
  else
    target_resolver = settings.DEFAULT_TARGET_RESOLVERS[settings.DEFAULT_TARGET_RESOLVER_ID]
    assert(target_resolver ~= nil, 'default target resolver is undefined')
  end

  local runner = require('pesto.runner.runner')
  local context = runner.get_run_bazel_context()
  local target_resolver_result = target_resolver(context)

  if target_resolver_result.query ~= nil then
    -- Run the query
    vim.notify('Pesto: Querying targets...')

    self:_query_targets({
      query = target_resolver_result.query,
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
  elseif target_resolver_result.targets ~= nil then
    if #target_resolver_result.targets == 0 then
      vim.notify(
        'Pesto: The "targets" result returned an empty list of targets',
        vim.log.levels.ERROR
      )
    else
      local bazel_command = {
        self._settings:get_bazel_command(),
        'build',
        unpack(target_resolver_result.targets),
      }
      self._settings:get_bazel_runner()({
        bazel_command = bazel_command,
        context = context,
      })
    end
  else
    vim.notify('Pesto: Invalid response from target resolver', vim.log.levels.ERROR)
  end
end

---@param opts pesto.QueryTargetsOpts
function BuildSubcommand:_query_targets(opts)
  if opts.run_bazel_context.package_label == nil then
    opts.on_error('failed to resolve package directory')
    return
  end

  ---@type string[]
  local query_command = {
    self._settings:get_bazel_command(),
    'query',
    opts.query,
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
