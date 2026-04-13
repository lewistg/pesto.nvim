local M = {}

---@param settings pesto.Settings
function M.setup(settings)
    vim.g.pesto = settings
end

return M
