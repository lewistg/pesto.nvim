local M = {}

local function check_bazel_executable()
  local components = require('pesto.components')
  local bazel_command = components.settings:get_bazel_executable()
  local header = 'Bazel executable: '
  local command_line = '\t- Executable: ' .. tostring(bazel_command)
  if vim.fn.executable(bazel_command) == 1 then
    local lines = {
      header .. 'found',
      command_line,
    }
    vim.health.ok(table.concat(lines, '\n'))
  else
    local lines = {
      header .. 'not found',
      command_line,
    }
    vim.health.error(table.concat(lines, '\n'))
  end
end

local function check_bazel_bash_completion()
  local components = require('pesto.components')

  local completion_settings = components.settings:get_cli_completion_settings()

  if completion_settings.mode == 'lua' then
    vim.health.info('Bash Bazel completion: disabled')
  else
    local bazel_bash_completion_client = components.bazel_bash_completion_client
    local health_check_result = bazel_bash_completion_client:check_health()
    local header = 'Bash Bazel completion: '
    if health_check_result.loads then
      local lines = {
        header .. 'loads',
        '\t- Script path: ' .. tostring(health_check_result.completion_script),
      }
      vim.health.ok(table.concat(lines, '\n'))
    else
      local lines = {
        header .. 'does not load',
        '\t- Script path: ' .. tostring(health_check_result.completion_script),
        "\t- Note: check pesto.nvim's logs for specific errors",
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

  check_bazel_executable()
  check_bazel_bash_completion()

  local logger = require('pesto.logger')
  vim.health.info(string.format('Log file: %s', logger.LOG_FILE_PATH))
end

return M
