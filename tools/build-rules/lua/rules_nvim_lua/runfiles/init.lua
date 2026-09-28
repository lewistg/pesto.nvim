local M = {}

-- Note: This library was loosely based off the Java runfiles library [1].
--
-- [1]: https://github.com/bazelbuild/rules_java/blob/master/java/runfiles/src/main/java/com/google/devtools/build/runfiles/Runfiles.java#L426

local RUNFILES_DIR = os.getenv('RUNFILES_DIR')
if RUNFILES_DIR == nil then
  error('RUNFILES_DIR environment variable is not set')
end

---@type {[string]: {[string]: string}}
local REPO_MAPPING

---@param key {source_repo: string, apparent_repo_name: string}
---@return string|nil
local function get_canonical_repo_name(key)
  if REPO_MAPPING == nil then
    REPO_MAPPING = {
      ['_main'] = {
        ['_main'] = '_main',
      },
    }
    local lines = vim.fn.readfile(vim.fs.joinpath(RUNFILES_DIR, '_repo_mapping'))
    vim.iter(lines):each(function(line)
      local source_repo, apparent_repo_name, canonical_repo_name = unpack(vim.split(line, ','))

      if source_repo == '' then
        source_repo = '_main'
      end

      if source_repo == nil or apparent_repo_name == nil or canonical_repo_name == nil then
        error('Invalid _repo_mapping entry: ' .. line)
      end

      if REPO_MAPPING[source_repo] == nil then
        REPO_MAPPING[source_repo] = {}
      end
      REPO_MAPPING[source_repo][apparent_repo_name] = canonical_repo_name
    end)
  end
  return vim.tbl_get(REPO_MAPPING, key.source_repo, key.apparent_repo_name)
end

---@return string
function M.rlocation(path)
  -- At the moment we only support getting runfiles from the main repo
  local source_repo = '_main'

  local segments = vim.split(path, '/')
  local apparent_repo_name = segments[1]

  local canonical_repo_name =
    get_canonical_repo_name({ source_repo = source_repo, apparent_repo_name = apparent_repo_name })
  if canonical_repo_name ~= nil then
    segments[1] = canonical_repo_name
  end

  return vim.fs.joinpath(RUNFILES_DIR, unpack(segments))
end

return M
