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
		local funcs = q.find_top_level_funcs(bufnr, "only")
		print(f.duration_to_str(vim.loop.hrtime() - start))

		assert.are.same(3, #funcs)
		assert.are.same({ desc = "d0", row = 1, col = 2, name = "describe" }, funcs[1]:info())
		assert.are.same({ desc = "d1", row = 11, col = 0, name = "describe" }, funcs[2]:info())
		assert.are.same({ desc = "i3", row = 24, col = 2, name = "it" }, funcs[3]:info())
	end)
end)
