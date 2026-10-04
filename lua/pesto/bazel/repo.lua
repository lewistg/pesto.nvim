local M = {}

-- Note: BUILD.bazel takes precedence over BUILD [1]
-- [1]: https://bazel.build/concepts/build-files
local PACKAGE_MARKERS = {
  'BUILD.bazel',
  'BUILD',
}

local function normalize_path(path)
  return vim.fn.resolve(vim.fs.abspath(path))
end

---@param buf_nr number|nil
local function get_buffer_dir(buf_nr)
  local path = vim.api.nvim_buf_get_name(buf_nr or 0)
  path = normalize_path(path)
  if vim.fn.isdirectory(path) then
    return path
  else
    return vim.fs.dirname(path)
  end
end

-- Gets the label for the package that contains the file associated with the
-- given buffer.
--
---@param buf_nr number|nil
---@return string|nil label The package label
function M.get_package_label(buf_nr)
  local build_file_path = M.find_build_file(buf_nr)
  if build_file_path == nil then
    return nil
  end

  local package_dir_path = vim.fs.dirname(build_file_path)
  local root_dir_path = M.find_project_root_dir()
  if root_dir_path == nil then
    return nil
  end
  local package_rel_path = vim.fs.relpath(root_dir_path, package_dir_path)

  if package_rel_path == '.' then
    return '//'
  else
    return '//' .. package_rel_path
  end
end

-- Finds the corresponding build file for the source file in the given buffer.
--
---@param buf_nr number|nil
---@return string|nil
function M.find_build_file(buf_nr)
  local project_root_dir = M.find_project_root_dir(buf_nr)
  local buffer_dir = get_buffer_dir(buf_nr)
  local files = vim.fs.find(PACKAGE_MARKERS, {
    type = 'file',
    path = buffer_dir,
    upward = true,
    stop = vim.fs.joinpath(project_root_dir, '..'),
  })
  return files[1]
end

-- Finds the repo's root marker file
--
---@param buf_nr number|nil
function M.find_project_root_dir(buf_nr)
  local root_marker_file = M.find_project_root_marker_file(buf_nr)
  local root_dir = vim.fs.dirname(root_marker_file)
  return root_dir
end

-- Finds the repo's root marker file
--
---@param buf_nr number|nil
---@return string|nil
function M.find_project_root_marker_file(buf_nr)
  local buffer_dir = get_buffer_dir(buf_nr)

  local root_marker_filenames = { 'MODULE.bazel', 'REPO.bazel', 'WORKSPACE', 'WORKSPACE.bazel' }
  for _, filename in ipairs(root_marker_filenames) do
    local root_marker_file = vim.fn.findfile(filename, buffer_dir .. ';')
    if root_marker_file and string.len(root_marker_file) > 0 then
      return normalize_path(root_marker_file)
    end
  end
  return nil
end

---@param buf_nr number
---@return boolean
function M.is_in_bazel_repo(buf_nr)
  return M.find_project_root_marker_file(buf_nr) ~= nil
end

return M
