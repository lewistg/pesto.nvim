local repo =  {}

--[[
-- Gets the package for the current source file
--]]
function repo.get_package_label()
    local build_file_path  = repo.find_build_file()
    local package_dir_path = vim.fn.fnamemodify(build_file_path, ':p:h')
    local root_dir_path = repo.find_project_root_dir()
    local relative_package_path = string.gsub(package_dir_path, '^' .. root_dir_path .. '//?', '//')
    return relative_package_path
end

--[[
-- Finds the corresponding build file
--]]
function repo.find_build_file()
    -- note: BUILD.repo takes precedence over BUILD [1]
    -- [1]: https://repo.build/concepts/build-files  
    local buffer_dir = vim.fn.expand('%:p:h')
    local filenames = {'BUILD.repo', 'BUILD'}
    for _, filename in ipairs(filenames) do
        build_file = vim.fn.findfile(filename, buffer_dir .. ';')
        if build_file ~= '' then
            build_file = vim.fn.fnamemodify(build_file, ':p')
            return build_file
        end
    end
    error('could not find BUILD.repo or BUILD file')
end

--[[
-- Finds the repo's root directory
--]]
function repo.find_project_root_dir()
    local root_marker_file = repo.find_project_root_marker_file()
    local root_dir = vim.fn.fnamemodify(root_marker_file, ':p:h')
    return root_dir
end

--[[
-- Finds the repo's root marker file
--]]
function repo.find_project_root_marker_file()
    local buffer_dir = vim.fn.expand('%:p:h')
    local root_marker_filenames = {'MODULE.bazel', 'REPO.bazel', 'WORKSPACE', 'WORKSPACE.bazel'}
    for _, filename in ipairs(root_marker_filenames) do
        root_marker_file = vim.fn.findfile(filename, buffer_dir .. ';')
        if root_marker_file  and string.len(root_marker_file) > 0 then
            return root_marker_file
        end
    end
    error('could not find a repo root marker file')
end

return repo
