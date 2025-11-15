local M = {}

function M.check()
	vim.health.report_start("pesto.nvim")

	local logger = require("pesto.logger")
	vim.health.report_info(string.format("Log file: %s", logger.log_path))
end

return M
