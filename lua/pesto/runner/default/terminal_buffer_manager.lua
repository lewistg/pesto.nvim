local bazel_build_event_util = require("pesto.cli.bazel_build_event_util")
local terminal_buf_info = require("pesto.runner.default.terminal_buf_info")

-- The default Pesto bazel runner runs bazel in a terminal buffer. Since tabs
-- are somewhat considered workspaces Pesto dedicates one terminal buffer for
-- builds per tab. This class manages those buffers, including spinning them up
-- when a new bazel command needs to be executed.
--
---@class pesto.BuildTerminalManager
---@field private _terminal_buf_info {[number]: pesto.TerminalBufInfo}
local BuildTerminalManager = {}
BuildTerminalManager.__index = BuildTerminalManager

---@return pesto.BuildTerminalManager
function BuildTerminalManager:new()
	local o = setmetatable({}, BuildTerminalManager)

	o._terminal_buf_info = {}

	---@type number
	local autocmd_group = vim.api.nvim_create_augroup("pesto.BuildTerminalManager", { clear = true })
	vim.api.nvim_create_autocmd("TabClosed", {
		group = autocmd_group,
		callback = function(args)
			-- Note: args.file is id of the tab page being closed (see `h: TabClosed`)
			o:_on_tab_closed(args.file)
		end,
	})
	vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
		group = autocmd_group,
		callback = function(args)
			o:_on_buf_wipeout(args.buf)
		end,
	})

	return o
end

---@param tab_id number
---@return number|nil
function BuildTerminalManager:get_tab_id(tab_id)
	return self:_find_tab_terminal_buf(tab_id)
end

---@param tab_id number
function BuildTerminalManager:_on_tab_closed(tab_id)
	for buf_id, term_buf_info in pairs(self._terminal_buf_info) do
		if term_buf_info.tab_id == tab_id then
			vim.api.nvim_buf_delete(buf_id, { force = true })
		end
	end
end

---@param buf_id number
function BuildTerminalManager:_on_buf_wipeout(buf_id)
	self._terminal_buf_info[buf_id] = nil
end

---@param opts RunBazelOpts
---@return number
function BuildTerminalManager:run_bazel(opts)
	---@type number
	local tab_id = vim.api.nvim_get_current_tabpage()

	---@type number|nil
	local prev_term_buf_id = self:_find_tab_terminal_buf(tab_id)

	---@type number
	local new_term_buf_id = self:_create_term_buf(opts)

	if prev_term_buf_id ~= nil then
		for _, win_id in ipairs(vim.fn.win_findbuf(prev_term_buf_id)) do
			vim.api.nvim_win_set_buf(win_id, new_term_buf_id)
		end
		vim.api.nvim_buf_delete(prev_term_buf_id, {})
	end

	return new_term_buf_id
end

---@private
---@param tab_id number|nil
---@return number|nil
function BuildTerminalManager:_find_tab_terminal_buf(tab_id)
	if tab_id == 0 or tab_id == nil then
		tab_id = vim.api.nvim_get_current_tabpage()
	end
	for buf_id, term_buf_info in pairs(self._terminal_buf_info) do
		if term_buf_info.tab_id == tab_id then
			return buf_id
		end
	end
	return nil
end

---@param run_opts RunBazelOpts
---@return number
function BuildTerminalManager:_create_term_buf(run_opts)
	local tab_id = vim.api.nvim_get_current_tabpage()
	local buf_id = vim.api.nvim_create_buf(false, true)

	local bazel_command = table.concat(run_opts.bazel_command, " ")
	local command = string.format("(cd %s && %s)", run_opts.context.package_dir, bazel_command)

	self._terminal_buf_info[buf_id] = terminal_buf_info.init_terminal_buf_info(buf_id, tab_id)

	local term_buf_info = self._terminal_buf_info[buf_id]
	vim.api.nvim_buf_call(buf_id, function()
		vim.fn.termopen(command, {
			on_exit = function(job_id, exit_code, event_type)
				term_buf_info.exit_code = exit_code
				term_buf_info.bep_file = bazel_build_event_util.extract_bep_option(run_opts.bazel_command)
				if term_buf_info.exit_code == 0 then
					vim.notify("Pesto: Build succeeded", vim.log.levels.INFO)
				else
					vim.notify("Pesto: Build failed", vim.log.levels.ERROR)
				end
			end,
		})
	end)

	return buf_id
end

return BuildTerminalManager
