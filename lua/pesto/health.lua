local M = {}

local function get_enabled_str(is_enabled)
  if is_enabled then
    return 'enabled'
  else
    return 'disabled'
  end
end

local function check_bazel_command()
  local components = require('pesto.components')
  local bazel_command = components.settings:get_bazel_command()
  local command_line = '\t- command: ' .. tostring(bazel_command)
  if vim.fn.executable(bazel_command) == 1 then
    local lines = {
      'Bazel command found',
      command_line,
    }
    vim.health.ok(table.concat(lines, '\n'))
  else
    local lines = {
      'Bazel command not found',
      command_line,
    }
    vim.health.error(table.concat(lines, '\n'))
  end
end

local function check_bazel_bash_completion()
  local components = require('pesto.components')

  local completion_settings = components.settings:get_cli_completion_settings()

  if completion_settings.mode == 'lua' then
    vim.health.info('Bash Bazel completion : ' .. get_enabled_str(false))
  else
    local bazel_bash_completion_client = components.bazel_bash_completion_client
    local health_check_result = bazel_bash_completion_client:check_health()
    if health_check_result.loads then
      local lines = {
        'Bash Bazel completion script loads',
        '\t- script: ' .. tostring(health_check_result.completion_script),
      }
      vim.health.ok(table.concat(lines, '\n'))
    else
      local lines = {
        'Bash Bazel completion script does not load',
        '\t- completion script: ' .. tostring(health_check_result.completion_script),
        "\t- note: check pesto.nvim's logs for specific errors",
      }
      vim.health.error(table.concat(lines, '\n'))
    end
  end
end

function M.check()
  vim.health.start('pesto.nvim')

  if vim.version.cmp(vim.version(), { major = 0, minor = 11, patch = 0 }) >= 0 then
    vim.health.ok('Neovim >= 0.11.0')
  else
    vim.health.error('Neovim >= 0.11.0 required')
  end

  check_bazel_command()
  check_bazel_bash_completion()

  local logger = require('pesto.logger')
  vim.health.info(string.format('Log file: %s', logger.LOG_FILE_PATH))
end

return M
