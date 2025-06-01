local table_util = require("pesto.util.table_util")

describe("map", function()
	it("transforms the values of a table", function()
		local mapped = table_util.map({ 0, 1, 2, 3 }, function(x)
			return x * x
		end)
		assert.are.same({ 0, 1, 4, 9 }, mapped)
	end)
end)

describe("filter", function()
	it("returns copy of table with filtered values removed", function()
		local t = { 0, 1, 2, 3, 4, 5, 6, 7, 8 }
		local filtered_t = table_util.filter(t, function(x)
			return x % 2 == 0
		end)
		assert.are.same({ 0, 2, 4, 6, 8 }, filtered_t)
	end)
end)
