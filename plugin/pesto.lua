local components = require("pesto.components")

if vim.g.pesto_loaded then
	return
end
vim.g.pesto_loaded = true

local pesto_cli = components.pesto_cli

vim.api.nvim_create_user_command("Pesto", pesto_cli.run_command, {
	nargs = "*",
	range = true,
	complete = pesto_cli.complete,
})
