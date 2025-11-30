describe("concat", function()
	local table_util = require("pesto.util.table_util")
	it("returns a list with all of the given lists concatentated together", function()
		local concatenated = table_util.concat({ 1, 2, 3 }, { 4 }, { 5, 6 }, { 7, 8, 9 })
		assert.are.same({ 1, 2, 3, 4, 5, 6, 7, 8, 9 }, concatenated)
	end)
end)

describe("flat_map", function()
	local table_util = require("pesto.util.table_util")
	it("returns a list with all of the given lists concatentated together", function()
		local nums = { 1, 2, 3, 4, 5 }
		local flat_mapped = table_util.flat_map(function(num)
			return { num, num }
		end, nums)
		assert.are.same({ 1, 1, 2, 2, 3, 3, 4, 4, 5, 5 }, flat_mapped)
	end)
end)
