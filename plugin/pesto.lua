local cli = require("pesto.cli")

if vim.g.pesto_loaded then
	return
end
vim.g.pesto_loaded = true

vim.api.nvim_create_user_command("Pesto", cli.run_command, {
	nargs = "*",
	range = true,
	complete = cli.complete,
})
