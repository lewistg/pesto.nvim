local M = {}

---@param config pesto.Config
function M.setup(config)
  vim.g.pesto = config
end

return M
