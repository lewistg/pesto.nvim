local M = {}

function M.copy_dir(src_dir, dest_dir)
  src_dir = vim.fs.abspath(src_dir)

  if not vim.fn.isdirectory(vim.fn.resolve(src_dir)) then
    error(tostring(src_dir) .. ' is not a directory')
  end

  src_dir = vim.fs.abspath(src_dir)
  local src_dir_name = vim.fs.basename(src_dir)

  local function copy_file(name, path)
    local full_path = vim.fs.joinpath(path, name)

    local real_full_path = vim.fn.resolve(full_path)
    if vim.fn.isdirectory(real_full_path) == 1 then
      return
    end

    local rel_path = vim.fs.relpath(src_dir, full_path)

    local dest_file = vim.fs.joinpath(dest_dir, src_dir_name, rel_path)
    local dest_file_dir = vim.fs.dirname(dest_file)
    if string.len(dest_file_dir) > 0 then
      vim.fn.mkdir(dest_file_dir, 'p')
    end

    -- We want to copy the real file and not the symlink
    vim.fn.filecopy(real_full_path, dest_file)
  end

  vim.fs.find(copy_file, { limit = math.huge, type = 'file', path = src_dir })
  vim.fs.find(copy_file, { limit = math.huge, type = 'link', path = src_dir })

  return vim.fs.joinpath(dest_dir, src_dir_name)
end

return M
