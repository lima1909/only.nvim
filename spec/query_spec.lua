local assert = require("luassert")
local q = require("only.query")
local f = require("only.format")

describe("query", function()
	local bufnr
	local lines

	before_each(function()
		local input = [[
--  i1 -> pending it-function: i1
  describe("d0", function()
	it("i0 only", function() end)
	it("i1", function() end)
	it("i2 only", function() end)
  end)

pending("p0", function()
	it("i2 only", function() end)
end)

--  i1, i2 -> pending describe function
describe("d1", function()
	it("i1", function() end)
	it("i2", function() end)
end)


describe("d2 only", function()
	describe("d21 only", function()
		it("i1", function() end)
		it("i2 only", function() end)
	end)
end)

  it("i3", function() end)
]]

		bufnr = vim.api.nvim_create_buf(false, false)
		vim.api.nvim_set_current_buf(bufnr)
		lines = vim.split(input, "\n")
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
	end)

	it("find not only functions", function()
		local start = vim.loop.hrtime()
		local funcs = q.new(bufnr, "only"):find_top_level_funcs()
		print(f.duration_to_str(vim.loop.hrtime() - start))

		assert.are.same(1, #funcs.to_pending)
		assert.are.same({ desc = "d2 only", row = 18, col = 0, name = "describe" }, funcs.to_pending[1]:info())

		local must_check = funcs.must_check
		assert.are.same(3, #must_check)
		assert.are.same({ desc = "d0", row = 1, col = 2, name = "describe" }, must_check[1]:info())
		assert.are.same({ desc = "d1", row = 12, col = 0, name = "describe" }, must_check[2]:info())
		assert.are.same({ desc = "i3", row = 25, col = 2, name = "it" }, must_check[3]:info())
	end)

	it("find only child functions", function()
		local start = vim.loop.hrtime()
		local funcs = q.new(bufnr, "only"):find_top_level_funcs()
		print(f.duration_to_str(vim.loop.hrtime() - start))

		assert.are.same(3, #funcs.must_check)

		local d0 = funcs.must_check[1]:children()
		assert.are.same(3, #d0)
		assert.are.same({ desc = "i0 only", row = 2, col = 1, name = "it" }, d0[1]:info())
		assert.are.same({ desc = "i1", row = 3, col = 1, name = "it" }, d0[2]:info())
		assert.are.same({ desc = "i2 only", row = 4, col = 1, name = "it" }, d0[3]:info())

		local d1 = funcs.must_check[2]:children()
		assert.are.same(2, #d1)
		assert.are.same({ desc = "i1", row = 13, col = 1, name = "it" }, d1[1]:info())
		assert.are.same({ desc = "i2", row = 14, col = 1, name = "it" }, d1[2]:info())

		local i3 = funcs.must_check[3]:children()
		assert.are.same({}, i3)
	end)
end)
