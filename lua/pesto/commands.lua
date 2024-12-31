local commands = {}

local bazel = require('pesto.bazel')

local function run_bazel(args)
    local bazel_command =  bazel.get_command(args)
end

local function pesto_vs_build()
    local build_file_path = bazel.find_build_file()
    vim.cmd.vsplit(build_file_path)
end

local function pesto_sp_build()
    local build_file_path = bazel.find_build_file()
    vim.cmd.split(build_file_path)
end

local function pesto_yank_package_label()
    local package_label = bazel.get_package_label()
    vim.fn.setreg('@', package_label .. '\n')
end

function commands.create_commands()
    vim.api.nvim_create_user_command('Bazel', run_bazel, {})

    -- Commands to open up the BUILD.bazel file corresponding to the file in
    -- the current buffer.
    vim.api.nvim_create_user_command('PestoOpenBuild', pesto_sp_build, {})
    vim.api.nvim_create_user_command('PestoSpBuild', pesto_sp_build, {})
    vim.api.nvim_create_user_command('PestoVsBuild', pesto_vs_build, {})

    vim.api.nvim_create_user_command('PestoYankPackageLabel', pesto_yank_package_label, {})
end

return commands
