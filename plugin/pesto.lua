if vim.g.pesto_loaded then
	return
end
vim.g.pesto_loaded = true

-- Note: `require`s are inlined to avoid initializing components until they are needed.

vim.api.nvim_create_user_command("Pesto", function(opts)
	---@type Components
	local components = require("pesto.components")
	components.pesto_cli.run_command(opts)
end, {
	nargs = "*",
	range = true,
	complete = function(arg_lead, cmd_line, cursor_pos)
		---@type Components
		local components = require("pesto.components")
		return components.pesto_cli.complete(arg_lead, cmd_line, cursor_pos)
	end,
})

vim.api.nvim_set_keymap("n", "<Plug>pesto-compile-on-dep", ":Pesto compile-one-dep<CR>", {})
