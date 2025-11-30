local table_util = require("pesto.util.table_util")

describe("filter", function()
	it("returns copy of table with filtered values removed", function()
		local t = { 0, 1, 2, 3, 4, 5, 6, 7, 8 }
		local filtered_t = vim.tbl_filter(function(x)
			return x % 2 == 0
		end, t)
		assert.are.same({ 0, 2, 4, 6, 8 }, filtered_t)
	end)
end)

describe("concat", function()
	it("returns a list with all of the given lists concatentated together", function()
		local concatenated = table_util.concat({ 1, 2, 3 }, { 4 }, { 5, 6 }, { 7, 8, 9 })
		assert.are.same({ 1, 2, 3, 4, 5, 6, 7, 8, 9 }, concatenated)
	end)
end)
