local Path = require("pesto.util.path")
local table_util = require("pesto.util.table_util")
local busted_fixtures = require("busted.fixtures")

local FIXTURES_DIR = busted_fixtures.path("path_spec_fixtures") .. "/"

describe("Path", function()
	it("Path:new can construct a path from a string", function()
		local raw_path = "/foo/bar/baz"
		local path = Path:new(raw_path)
		assert.are.same(raw_path, tostring(path))
	end)

	describe("Path:join", function()
		local test_cases = {
			{
				paths = {
					"/foo/bar/baz",
					"qux/quux/quuz",
				},
				expected_path = "/foo/bar/baz/qux/quux/quuz",
			},
			{
				paths = {
					"/foo/bar/baz",
					"/qux/quux/quuz",
				},
				expected_path = "/qux/quux/quuz",
			},
			{
				paths = {
					"/",
					"//",
					"///",
					"/./././",
				},
				expected_path = "/",
			},
			{
				paths = {
					"/foo/bar",
					"../..",
					"baz",
				},
				expected_path = "/foo/bar/../../baz",
			},
		}
		for i, test_case in ipairs(test_cases) do
			it("test case #" .. i, function()
				local final_path = table_util.reduce(test_case.paths, function(acc, next_path)
					return acc:join(next_path)
				end, Path:new("."))
				assert.are.same(test_case.expected_path, tostring(final_path))
			end)
		end
	end)

	describe("Path:get_basename", function()
		local test_cases = {
			{
				path = "/",
				expected_path = "/",
			},
			{
				path = "/foo",
				expected_path = "foo",
			},
			{
				path = "/foo/bar",
				expected_path = "bar",
			},
		}
		for i, test_case in ipairs(test_cases) do
			it("test case #" .. i, function()
				local path = Path:new(test_case.path)
				local basename = path:get_basename()
				assert.are.same(test_case.expected_path, tostring(path:get_basename()))
			end)
		end
	end)

	describe("Path:get_dirname", function()
		local test_cases = {
			{
				path = "/",
				expected_path = "/",
			},
			{
				path = "/foo",
				expected_path = "/",
			},
			{
				path = "/foo/bar",
				expected_path = "/foo",
			},
		}
		for i, test_case in ipairs(test_cases) do
			it("test case #" .. i, function()
				local path = Path:new(test_case.path)
				local dirname = path:get_dirname()
				assert.are.same(test_case.expected_path, tostring(path:get_dirname()))
			end)
		end
	end)

	describe("Path:get_basename", function()
		local test_cases = {
			{
				path = "/foo/bar/baz",
				expected_path = "baz",
			},
			{
				path = "/",
				expected_path = "/",
			},
			{
				path = "../../baz",
				expected_path = "baz",
			},
		}
		for i, test_case in ipairs(test_cases) do
			it("test case #" .. i, function()
				local path = Path:new(test_case.path)
				local dirname = path:get_dirname()
				assert.are.same(test_case.expected_path, tostring(path:get_basename()))
			end)
		end
	end)

	describe("Path.get_relative", function()
		local test_cases = {
			{
				path_1 = FIXTURES_DIR .. "a/b",
				path_2 = FIXTURES_DIR .. "a/b/c/foo.txt",
				expected_path = "c/foo.txt",
			},
			{
				path_1 = FIXTURES_DIR .. "a/b/c/foo.txt",
				path_2 = FIXTURES_DIR .. "a/b",
				expected_path = "..",
			},
			{
				path_1 = FIXTURES_DIR .. "a/b/c/foo.txt",
				path_2 = FIXTURES_DIR .. "b/c/d/e/bar.txt",
				expected_path = "../../../b/c/d/e/bar.txt",
			},
		}
		for i, test_case in ipairs(test_cases) do
			it("test case #" .. i, function()
				local path_1 = Path:new(test_case.path_1)
				local path_2 = Path:new(test_case.path_2)
				local relative_path = Path.get_relative(path_1, path_2)
				assert.are.same(test_case.expected_path, tostring(relative_path))
			end)
		end
	end)
end)
