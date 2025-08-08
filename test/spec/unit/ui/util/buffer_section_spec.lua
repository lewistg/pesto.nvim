local BufferSection = require("pesto.ui.util.buffer_section")

describe("pesto.BufferSection", function()
	---@type number
	local test_buf_id

	before_each(function()
		test_buf_id = vim.api.nvim_create_buf(false, true)
	end)

	after_each(function()
		vim.cmd.bd(test_buf_id)
	end)

	it("can do basic line edits in a buffer", function()
		---@type pesto.BufferSection
		local buffer_section = BufferSection:new({
			buf_id = test_buf_id,
			start_row = 0,
		})
		---@type string[]
		local section_lines = {
			"foo",
			"  bar",
			"    baz",
		}

		buffer_section:edit_lines({
			start_row = 0,
			end_row = -1,
			lines = section_lines,
		})
		local actual_lines = vim.api.nvim_buf_get_lines(test_buf_id, 0, -1, false)

		assert.are.same(section_lines, actual_lines)
		assert.are.same(0, buffer_section.start_row)
		assert.are.same(2, buffer_section:get_end_row())

		buffer_section:edit_lines({
			start_row = 1,
			end_row = 2,
			lines = { "qux" },
		})
		actual_lines = vim.api.nvim_buf_get_lines(test_buf_id, 0, -1, false)

		assert.are.same({ "foo", "qux", "    baz" }, actual_lines)
		assert.are.same(0, buffer_section.start_row)
		assert.are.same(2, buffer_section:get_end_row())

		buffer_section:edit_lines({
			start_row = 0,
			end_row = -1,
			lines = { "qux" },
		})
		actual_lines = vim.api.nvim_buf_get_lines(test_buf_id, 0, -1, false)

		assert.are.same({ "qux" }, actual_lines)
		assert.are.same(0, buffer_section.start_row)
		assert.are.same(0, buffer_section:get_end_row())
	end)

	it("can contain other child BufferSections", function()
		---@type pesto.BufferSection
		local buffer_section = BufferSection:new({
			buf_id = test_buf_id,
			start_row = 0,
		})

		---@type pesto.BufferSection
		local child_buffer_section = BufferSection:new({
			buf_id = test_buf_id,
			start_row = 0,
		})

		---@type pesto.BufferSection
		local grand_child_buffer_section = BufferSection:new({
			buf_id = test_buf_id,
			start_row = 0,
		})

		---@type (string|pesto.BufferSection)[]
		local section_lines = {
			"foo",
			"bar",
			"baz",
		}

		buffer_section:edit_lines({
			start_row = 0,
			end_row = -1,
			lines = section_lines,
		})
		local actual_lines = vim.api.nvim_buf_get_lines(test_buf_id, 0, -1, false)

		assert.are.same({ "foo", "bar", "baz" }, actual_lines)

		buffer_section:edit_lines({
			start_row = 1,
			end_row = 2,
			lines = child_buffer_section,
		})
		actual_lines = vim.api.nvim_buf_get_lines(test_buf_id, 0, -1, false)

		assert.are.same({ "foo", "", "baz" }, actual_lines)

		child_buffer_section:edit_lines({
			start_row = 0,
			end_row = -1,
			lines = { "a", "b", "c" },
		})
		actual_lines = vim.api.nvim_buf_get_lines(test_buf_id, 0, -1, false)

		assert.are.same({ "foo", "a", "b", "c", "baz" }, actual_lines)
		assert.are.same(0, buffer_section.start_row)
		assert.are.same(4, buffer_section:get_end_row())
		assert.are.same(1, child_buffer_section.start_row)
		assert.are.same(3, child_buffer_section:get_end_row())

		child_buffer_section:edit_lines({
			start_row = 3,
			end_row = -1,
			lines = grand_child_buffer_section,
		})

		grand_child_buffer_section:edit_lines({
			start_row = 0,
			end_row = -1,
			lines = { "x", "y", "z" },
		})
		actual_lines = vim.api.nvim_buf_get_lines(test_buf_id, 0, -1, false)

		assert.are.same({ "foo", "a", "b", "c", "x", "y", "z", "baz" }, actual_lines)
		assert.are.same(0, buffer_section.start_row)
		assert.are.same(7, buffer_section:get_end_row())
		assert.are.same(1, child_buffer_section.start_row)
		assert.are.same(6, child_buffer_section:get_end_row())
		assert.are.same(4, grand_child_buffer_section.start_row)
		assert.are.same(6, grand_child_buffer_section:get_end_row())
	end)

	it("can contain other child BufferSections", function()
		---@type pesto.BufferSection
		local buffer_section = BufferSection:new({
			buf_id = test_buf_id,
			start_row = 0,
		})

		---@type pesto.BufferSection
		local child_buffer_section = BufferSection:new({
			buf_id = test_buf_id,
			start_row = 0,
		})

		---@type pesto.BufferSection
		local grand_child_buffer_section = BufferSection:new({
			buf_id = test_buf_id,
			start_row = 0,
		})

		---@type (string|pesto.BufferSection)[]
		local section_lines = {
			"foo",
			"bar",
			"baz",
		}

		buffer_section:edit_lines({
			start_row = 0,
			end_row = -1,
			lines = section_lines,
		})
		local actual_lines = vim.api.nvim_buf_get_lines(test_buf_id, 0, -1, false)

		assert.are.same({ "foo", "bar", "baz" }, actual_lines)

		buffer_section:edit_lines({
			start_row = 1,
			end_row = 2,
			lines = child_buffer_section,
		})
		actual_lines = vim.api.nvim_buf_get_lines(test_buf_id, 0, -1, false)

		assert.are.same({ "foo", "", "baz" }, actual_lines)

		child_buffer_section:edit_lines({
			start_row = 0,
			end_row = -1,
			lines = { "a", "b", "c" },
		})
		actual_lines = vim.api.nvim_buf_get_lines(test_buf_id, 0, -1, false)

		assert.are.same({ "foo", "a", "b", "c", "baz" }, actual_lines)
		assert.are.same(0, buffer_section.start_row)
		assert.are.same(4, buffer_section:get_end_row())
		assert.are.same(1, child_buffer_section.start_row)
		assert.are.same(3, child_buffer_section:get_end_row())

		child_buffer_section:edit_lines({
			start_row = 3,
			end_row = -1,
			lines = grand_child_buffer_section,
		})

		grand_child_buffer_section:edit_lines({
			start_row = 0,
			end_row = -1,
			lines = { "x", "y", "z" },
		})
		actual_lines = vim.api.nvim_buf_get_lines(test_buf_id, 0, -1, false)

		assert.are.same({ "foo", "a", "b", "c", "x", "y", "z", "baz" }, actual_lines)
		assert.are.same(0, buffer_section.start_row)
		assert.are.same(7, buffer_section:get_end_row())
		assert.are.same(1, child_buffer_section.start_row)
		assert.are.same(6, child_buffer_section:get_end_row())
		assert.are.same(4, grand_child_buffer_section.start_row)
		assert.are.same(6, grand_child_buffer_section:get_end_row())
	end)
end)
