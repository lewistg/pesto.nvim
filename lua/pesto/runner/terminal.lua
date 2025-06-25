local terminal = {}

---@class PestoTerminalBufInfo
---@field exit_code boolean|nil

terminal.PESTO_TERMINAL_BUF = "PESTO_TERMINAL_BUF"

---@return integer|nil The window ID
local function get_or_create_terminal_window()
	---@type integer
	local terminal_win_id = nil

	for _, win_id in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		local buf_id = vim.api.nvim_win_get_buf(win_id)
		local is_build_terminal_win = pcall(vim.api.nvim_buf_get_var, buf_id, terminal.PESTO_TERMINAL_BUF)
		if is_build_terminal_win then
			terminal_win_id = win_id
			break
		end
	end

	if terminal_win_id == nil then
		vim.cmd.sp()
		terminal_win_id = vim.api.nvim_get_current_win()
	end

	return terminal_win_id
end

---@param tab_id integer|nil
---@return integer|nil
function terminal.find_build_window(tab_id)
	for _, win_id in ipairs(vim.api.nvim_tabpage_list_wins(tab_id or 0)) do
		local buf_id = vim.api.nvim_win_get_buf(win_id)
		local is_build_terminal_win = pcall(vim.api.nvim_buf_get_var, buf_id, terminal.PESTO_TERMINAL_BUF)
		if is_build_terminal_win then
			return win_id
		end
	end
	return nil
end

---@param buf_id integer|nil
---@return PestoTerminalBufInfo|nil
function terminal.get_build_info(buf_id)
	local _, build_info = pcall(vim.api.nvim_buf_get_var, buf_id or 0, terminal.PESTO_TERMINAL_BUF)
	return build_info
end

---@type RunBazelFn
---@param opts RunBazelOpts
function terminal.run(opts)
	local terminal_win_id = get_or_create_terminal_window()
	if terminal_win_id == nil then
		error("Failed to get or create terminal window")
	end

	local buf_id = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_var(buf_id, terminal.PESTO_TERMINAL_BUF, {})
	vim.api.nvim_buf_set_option(buf_id, "bufhidden", "delete")

	vim.api.nvim_set_current_win(terminal_win_id)
	vim.api.nvim_win_set_buf(terminal_win_id, buf_id)

	local bazel_command = table.concat(opts.bazel_command, " ")
	local command = string.format("(cd %s && %s)", opts.context.package_dir, bazel_command)
	vim.fn.termopen(command, {
		on_exit = function(job_id, exit_code, event_type)
			---@type PestoTerminalBufInfo|nil
			local pesto_terminal_buf_info = vim.api.nvim_buf_get_var(buf_id, terminal.PESTO_TERMINAL_BUF) or {}
			pesto_terminal_buf_info.exit_code = exit_code
			vim.api.nvim_buf_set_var(buf_id, terminal.PESTO_TERMINAL_BUF, pesto_terminal_buf_info)
		end,
	})
end

return terminal
