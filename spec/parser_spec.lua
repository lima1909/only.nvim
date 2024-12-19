local assert = require("luassert")
local p = require("only.parser")
local f = require("only.format")

local function create_node_mock(desc)
	return setmetatable({
		desc = function()
			return desc
		end,
	}, { __index = {} })
end

describe("tag filter:", function()
	it("one", function()
		local node = create_node_mock("foo")
		assert.is_true(p.tag_filter("foo")(node))
		assert.is_false(p.tag_filter("bar")(node))
	end)

	it("list", function()
		local node = create_node_mock("foo")
		assert.is_true(p.tag_filter({ "foo", "bar" })(node))
		assert.is_false(p.tag_filter({ "bar", "baz" })(node))
	end)

	it("empty", function()
		local node = create_node_mock("")
		assert.is_true(p.tag_filter("")(node))
		assert.is_false(p.tag_filter("bar")(node))
	end)

	it("nil", function()
		local node = create_node_mock()
		assert.is_false(p.tag_filter()(node))
		assert.is_false(p.tag_filter("bar")(node))
	end)
end)

describe("parse:", function()
	local function create_buffer(input)
		local bufnr = vim.api.nvim_create_buf(false, false)
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(input, "\n"))
		vim.api.nvim_set_current_buf(bufnr)
		return bufnr
	end

	it("no pending funcs", function()
		local bufnr = create_buffer([[ pending("d1", function() end) ]])
		local start = vim.loop.hrtime()
		local funcs = p.find_all_to_pending_funcs(bufnr, "only")
		print(f.duration_to_str(vim.loop.hrtime() - start))

		assert.are.same({}, funcs)
	end)

	it("parent not tagged, but all children", function()
		local bufnr = create_buffer([[
describe("d1", function()
	it("i11", function() end)
	it("i21", function() end)
end)
]])
		local start = vim.loop.hrtime()
		local funcs = p.find_all_to_pending_funcs(bufnr, "only")
		print(f.duration_to_str(vim.loop.hrtime() - start))
		assert.are.same(1, #funcs)
		assert.are.same({ desc = "d1", row = 0, col = 0, name = "describe" }, funcs[1]:info())
	end)

	it("one child is pending", function()
		local bufnr = create_buffer([[
describe("d1", function()
	it("i11 only", function() end)
	it("i21", function() end)
end)
]])
		local start = vim.loop.hrtime()
		local funcs = p.find_all_to_pending_funcs(bufnr, "only")
		print(f.duration_to_str(vim.loop.hrtime() - start))
		assert.are.same(1, #funcs)
		assert.are.same({ desc = "i11 only", row = 1, col = 1, name = "it" }, funcs[1]:info())
	end)

	it("all children are pending", function()
		local bufnr = create_buffer([[
describe("d1", function()
	it("i11 only", function() end)
	it("i21 only", function() end)
end)
]])
		local start = vim.loop.hrtime()
		local funcs = p.find_all_to_pending_funcs(bufnr, "only")
		print(f.duration_to_str(vim.loop.hrtime() - start))
		assert.are.same(1, #funcs)
		assert.are.same({ desc = "d1", row = 0, col = 0, name = "describe" }, funcs[1]:info())
	end)
end)
