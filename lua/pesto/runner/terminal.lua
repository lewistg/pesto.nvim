local terminal = {}

local pesto_terminal_buf = nil

function terminal.run(opts)
	if pesto_terminal_buf == nil or not vim.api.nvim_buf_is_valid(pesto_terminal_buf) then
		vim.cmd.new()
		vim.cmd.lcd(opts.workspace_root)
		vim.cmd.terminal()
		pesto_terminal_buf = vim.api.nvim_get_current_buf()
	else
		vim.cmd.new()
		vim.cmd.buffer(pesto_terminal_buf)
	end
	local channel_id = vim.bo[pesto_terminal_buf].channel
	vim.fn.chansend(channel_id, table.concat(opts.bazel_command, " ") .. "\n")
end

return terminal
