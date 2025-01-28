local commands = {}

local bazel = require('pesto.bazel')
local bazel_query_drawer = require('pesto.query_drawer')

local function pesto_vs_build()
    local build_file_path = bazel.repo.find_build_file()
    vim.cmd.vsplit(build_file_path)
end

local function pesto_sp_build()
    local build_file_path = bazel.repo.find_build_file()
    vim.cmd.split(build_file_path)
end

local function pesto_yank_package_label()
    local package_label = bazel.repo.get_package_label()
    vim.fn.setreg('@', package_label .. '\n')
end

local function get_pesto_bazel_fn(settings)
    return function (opts)
        local run_opts = {
            bazel_command = { settings.bazel_command },
            workspace_root = bazel.repo.find_project_root_dir()
        }

        for _, arg in ipairs(opts.fargs) do
            table.insert(run_opts.bazel_command, arg)
        end
        bazel.cli.insert_or_expand_target_labels(run_opts.bazel_command)

        settings.bazel_runner(run_opts)
    end
end

---@param components Components
local function get_pesto_bazel_query_fn(components)
    return function (opts)
        local win_id = vim.api.nvim_get_current_win()
        local buf_nr = vim.api.nvim_get_current_buf()
        local line_range = {
            line1 = opts.line1 - 1,
            line2 = opts.line2,
        }
        components.query_drawer_manager:run_query(win_id, buf_nr, line_range)
    end
end

---@param components Components
function commands.create_commands(components)
    vim.api.nvim_create_user_command('PestoBazel', get_pesto_bazel_fn(components.settings), {
        nargs = '*',
        -- complete = run_bazel_complete,
    })

    -- Commands to open up the BUILD.bazel file corresponding to the file in
    -- the current buffer.
    vim.api.nvim_create_user_command('PestoOpenBuild', pesto_sp_build, {})
    vim.api.nvim_create_user_command('PestoSpBuild', pesto_sp_build, {})
    vim.api.nvim_create_user_command('PestoVsBuild', pesto_vs_build, {})

    vim.api.nvim_create_user_command('PestoYankPackageLabel', pesto_yank_package_label, {})

    -- Commands for running bazel queries
    vim.api.nvim_create_user_command('PestoBazelQuery', get_pesto_bazel_query_fn(components), {
        range = true,
    })
end

return commands
