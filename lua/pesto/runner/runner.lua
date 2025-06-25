---@class RunBazelContext
---@field workspace_dir string
---@field package_dir string|nil

---@class RunBazelOpts
---@field bazel_command string[]
---@field context RunBazelContext

---@alias RunBazelFn fun(RunBazelOpts)
