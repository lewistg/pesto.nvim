if vim.g.pesto_loaded then
	return
end
vim.g.pesto_loaded = true

local components = require("pesto.components")
local pesto_cli = components.pesto_cli

vim.g.pesto_namespace = vim.api.nvim_create_namespace("pesto.nvim")

vim.api.nvim_create_user_command("Pesto", pesto_cli.run_command, {
	nargs = "*",
	range = true,
	complete = pesto_cli.complete,
})

vim.api.nvim_set_keymap("n", "<Plug>pesto-compile-on-dep", ":Pesto compile-one-dep<CR>", {})

vim.api.nvim_create_user_command("OpenPestoBuildSummary", function()
	local BuildEventsBuffer = require("lua.pesto.ui.build_events_buffer")
	local build_events_buffer = BuildEventsBuffer:new({})
	vim.cmd.new()
	vim.api.nvim_set_current_buf(build_events_buffer:get_buf_id())
end, {})
