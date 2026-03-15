local M = {}

--- This method returns a callback method that can be used passed as a handler
--- for one of vim.fn.jobstart's output handlers (e.g., stdout). It's useful
--- for cases where you'd rather operate on emitted lines instead of emitted
--- partial line chunks.
---
--- For more details see :help channel-bytes
---@param callback fun(chan_id: number, line: string)
function M.jobstart_get_on_line_completed(callback)
	---@type string
	local partial_line = ""
	return function(chan_id, chunks)
		if chunks == nil then
			chunks = { "" }
		end
		if #chunks == 1 then
			if chunks[1] == "" then
				callback(chan_id, partial_line .. chunks[1])
			else
				partial_line = partial_line .. chunks[1]
			end
		elseif #chunks > 1 then
			callback(chan_id, partial_line .. chunks[1])
			for i = 2, #chunks - 1 do
				callback(chan_id, chunks[i])
			end
			partial_line = chunks[#chunks]
		end
	end
end

--- This method returns a callback method that can be used passed as a handler
--- for one of vim.system's output handlers (e.g., stdout). It's useful
--- for cases where you'd rather operate on emitted lines instead of emitted
--- partial line chunks.
---@param callback fun(err: number, line: string)
function M.system_get_on_line_completed(callback)
	---@type string
	local partial_line = ""
	return function(err, data)
		if data == nil then
			callback(err, partial_line)
			return
		end

		if not data:find("\n") then
			partial_line = partial_line .. data
		else
			local lines = vim.split(data, "\n")
			callback(err, partial_line .. lines[1])
			for i = 2, #lines - 1 do
				callback(err, lines[i])
			end
			partial_line = lines[#lines]
		end
	end
end

return M
