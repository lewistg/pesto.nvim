local M = {}

function M.check()
	vim.health.start("pesto.nvim")

	if vim.version.cmp(vim.version(), { major = 0, minor = 11, patch = 0 }) >= 0 then
		vim.health.ok("Neovim >= 0.11.0")
	else
		vim.health.error("Neovim >= 0.11.0 required")
	end

	local logger = require("pesto.logger")
	vim.health.info(string.format("Log file: %s", logger.log_path))
end

return M
