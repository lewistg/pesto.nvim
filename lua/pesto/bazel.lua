local bazel = {}

--[[
-- Gets the package for the current source file
--]]
function bazel.get_package_label(args)
    local build_file_path  = bazel.find_build_file()
    local package_dir_path = vim.fn.fnamemodify(build_file_path, ':p:h')
    local root_dir_path = bazel.find_project_root_dir()
    local relative_package_path = string.gsub(package_dir_path, '^' .. root_dir_path .. '//?', '//')
    return relative_package_path
end

--[[
-- Finds the corresponding build file
--]]
function bazel.find_build_file()
    -- note: BUILD.bazel takes precedence over BUILD [1]
    -- [1]: https://bazel.build/concepts/build-files  
    local buffer_dir = vim.fn.expand('%:p:h')
    local filenames = {'BUILD.bazel', 'BUILD'}
    for _, filename in ipairs(filenames) do
        build_file = vim.fn.findfile(filename, buffer_dir .. ';')
        if build_file then
            build_file = vim.fn.fnamemodify(build_file, ':p')
            return build_file
        end
    end
    error('could not find BUILD.bazel or BUILD file')
end

--[[
-- Finds the repo's root directory
--]]
function bazel.find_project_root_dir()
    local root_marker_file = bazel.find_project_root_marker_file()
    local root_dir = vim.fn.fnamemodify(root_marker_file, ':p:h')
    return root_dir
end

--[[
-- Finds the repo's root marker file
--]]
function bazel.find_project_root_marker_file()
    local buffer_dir = vim.fn.expand('%:p:h')
    local root_marker_filenames = {'MODULE.bazel', 'WORKSPACE'}
    for _, filename in ipairs(root_marker_filenames) do
        root_marker_file = vim.fn.findfile(filename, buffer_dir .. ';')
        if root_marker_file  and string.len(root_marker_file) > 0 then
            return root_marker_file
        end
    end
    error('could not find a repo root marker file')
end

return bazel
