describe("jobstart_get_on_line_completed", function()
	local job_util = require("pesto.util.job_util")
	it("calls the given callback for each completed lines from vim.fn.jobstart", function()
		---@type string[]
		local lines = {}

		local on_line = function(chan_id, line)
			table.insert(lines, line)
		end

		local exit_code = nil
		vim.fn.jobstart({ "printf", "foo\\nbar\\nbaz" }, {
			text = true,
			on_stdout = job_util.jobstart_get_on_line_completed(on_line),
			on_exit = function(chan_id, code)
				exit_code = code
			end,
		})
		vim.wait(100, function()
			return exit_code ~= nil
		end)

		assert.are.equal(0, exit_code)
		assert.are.same({ "foo", "bar", "baz" }, lines)
	end)

	it("calls the given callback for each completed lines with simulated lines", function()
		---@type string[]
		local lines = {}

		local on_line = function(chan_id, line)
			table.insert(lines, line)
		end

		-- The "simulated lines." Example lines based on an example given in :h channel-bytes
		---@type string[][]
		local chunks = {
			{ "foo", "bar", "" },
			{ "foo" },
			{ "", "bar", "" },
			{ "fo" },
			{ "o", "bar" },
			-- final EOF
			{ "" },
		}

		local on_stdout = job_util.jobstart_get_on_line_completed(on_line)
		for _, _chunks in ipairs(chunks) do
			on_stdout(1, _chunks)
		end

		assert.are.same({
			"foo",
			"bar",
			"foo",
			"bar",
			"foo",
			"bar",
		}, lines)
	end)
end)

describe("system_get_on_line_completed", function()
	local job_util = require("pesto.util.job_util")
	it("calls the given callback for each completed lines from vim.system", function()
		---@type string[]
		local lines = {}

		local on_line = function(chan_id, line)
			table.insert(lines, line)
		end

		local system_completed = vim.system({ "printf", "foo\\nbar\\nbaz" }, {
			text = true,
			stdout = job_util.system_get_on_line_completed(on_line),
		}):wait()

		assert.are.equal(0, system_completed.code)
		assert.are.same({ "foo", "bar", "baz" }, lines)
	end)

	it("calls the given callback for each completed lines with simulated lines", function()
		---@type string[]
		local lines = {}

		local on_line = function(err, line)
			table.insert(lines, line)
		end

		-- The "simulated lines." Example lines based on an example given in :h channel-bytes
		---@type string[]
		local datas = {
			"foo\nbar\n",
			"foo",
			"\nbar\n",
			"fo",
			"o\nbar",
		}

		local on_stdout = job_util.system_get_on_line_completed(on_line)
		for _, data in ipairs(datas) do
			on_stdout(nil, data)
		end
		-- Final EOF
		on_stdout(nil, nil)

		assert.are.same({
			"foo",
			"bar",
			"foo",
			"bar",
			"foo",
			"bar",
		}, lines)
	end)
end)
