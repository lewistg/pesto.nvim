---@class pesto.QueryTargetsOpts
---@field run_bazel_context pesto.RunBazelContext
---@field query_fn fun(context: pesto.RunBazelContext): string
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
  local query_ids = vim.tbl_keys(self._settings:get_build_queries())
  return cli_util.get_completion_candidates(opts.arg_lead, query_ids)
end

---@param opts pesto.SubcommandExecuteOpts
function BuildSubcommand:_execute(opts)
  local logger = require('pesto.logger')

  ---@type string|nil
  local query_id = opts.fargs[1]

  local settings = require('pesto.settings')
  local build_queries = self._settings:get_build_queries()

  ---@type (fun(context: pesto.RunBazelContext): string)|nil
  local query_fn
  if query_id ~= nil then
    query_fn = build_queries[query_id]
    if query_fn == nil then
      vim.notify(string.format("Pesto: No query with ID '%s'", query_id), vim.log.levels.ERROR)
      return
    end
  else
    query_fn = settings.DEFAULT_BUILD_QUERIES['all']
    assert(query_fn ~= nil, "default, 'all' query is undefined")
  end

  -- Run the query
  vim.notify('Pesto: Querying targets...')

  local runner = require('pesto.runner.runner')
  local context = runner.get_run_bazel_context()
  self:_query_targets({
    query_fn = query_fn,
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
  if opts.run_bazel_context.package_label == nil then
    opts.on_error('failed to resolve package directory')
  end

  local logger = require('pesto.logger')

  local bazel_query = opts.query_fn(opts.run_bazel_context)

  ---@type string[]
  local query_command = {
    self._settings:get_bazel_command(),
    'query',
    bazel_query,
  }

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
