local assert = require("luassert")
local p = require("only.parser")

local function create_node_mock(val)
	return setmetatable({
		range = function()
			return val[1], val[2]
		end,
	}, { __index = {} })
end

describe("parse:", function()
	local function create_buffer(input)
		local bufnr = vim.api.nvim_create_buf(false, false)
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(input, "\n"))
		vim.api.nvim_set_current_buf(bufnr)
		return bufnr
	end

	describe("tags:", function()
		it("no pending funcs", function()
			local bufnr = create_buffer([[ pending("d1", function() end) ]])
			local funcs = p.to_pending_with_tags(bufnr, "only")
			assert.are.same(0, #funcs)
		end)

		it("one node with no match is pending", function()
			local bufnr = create_buffer([[ it("i1", function() end) ]])
			local funcs, sel = p.to_pending_with_tags(bufnr, "only")
			assert.are.same(1, #funcs)
			assert.are.same({ desc = "i1", row = 0, col = 1, name = "it" }, funcs[1]:info())
			assert.are.same(0, #sel)
		end)

		it("foo: no tag found, all nodes are pending", function()
			local bufnr = create_buffer([[
describe("d1 only", function()
	it("i11", function() end)
	it("i21", function() end)
end)
]])
			local funcs, sel = p.to_pending_with_tags(bufnr, "foo")
			assert.are.same(1, #funcs)
			assert.are.same({ desc = "d1 only", row = 0, col = 0, name = "describe" }, funcs[1]:info())
			assert.are.same(0, #sel)
		end)

		it("parent is tagged -> children too (inherit)", function()
			local bufnr = create_buffer([[
describe("d1 only", function()
	it("i11", function() end)
	it("i21", function() end)
end)
]])
			local funcs, sel = p.to_pending_with_tags(bufnr, "only")
			assert.are.same(0, #funcs)
			assert.are.same(1, #sel)
			assert.are.same({ desc = "d1 only", row = 0, col = 0, name = "describe" }, sel[1]:info())
		end)

		it("parent and children not tagged, all pending", function()
			local bufnr = create_buffer([[
describe("d1", function()
	it("i11", function() end)
	it("i21", function() end)
end)
]])
			local funcs, sel = p.to_pending_with_tags(bufnr, "only")
			assert.are.same(1, #funcs)
			assert.are.same({ desc = "d1", row = 0, col = 0, name = "describe" }, funcs[1]:info())
			assert.are.same(0, #sel)
		end)

		it("one child i21 is pending", function()
			local bufnr = create_buffer([[
describe("d1", function()
	it("i11 only", function() end)
	it("i21", function() end)
end)
]])
			local funcs, sel = p.to_pending_with_tags(bufnr, "only")
			assert.are.same(1, #funcs)
			assert.are.same({ desc = "i21", row = 2, col = 1, name = "it" }, funcs[1]:info())
			assert.are.same(1, #sel)
			assert.are.same({ desc = "i11 only", row = 1, col = 1, name = "it" }, sel[1]:info())
		end)

		it("all children are pending", function()
			local bufnr = create_buffer([[
describe("d1", function()
	it("i11 only", function() end)
	it("i21 only", function() end)
end)
]])
			local funcs, sel = p.to_pending_with_tags(bufnr, "only")
			assert.are.same(0, #funcs)
			assert.are.same(2, #sel)
			assert.are.same({ desc = "i11 only", row = 1, col = 1, name = "it" }, sel[1]:info())
			assert.are.same({ desc = "i21 only", row = 2, col = 1, name = "it" }, sel[2]:info())
		end)

		it("child of child, select one child", function()
			local bufnr = create_buffer([[
describe("d1", function()
  describe("d11 only", function()
	it("i11", function() end)
	it("i21", function() end)
  end)
end)
]])
			local funcs, sel = p.to_pending_with_tags(bufnr, "only")
			assert.are.same(0, #funcs)
			assert.are.same(1, #sel)
			assert.are.same({ desc = "d11 only", row = 1, col = 2, name = "describe" }, sel[1]:info())
		end)

		it("child of child, select one child for different parents", function()
			local bufnr = create_buffer([[
describe("d1", function()
  describe("d11", function()
	it("i11 only", function() end)
	it("i12", function() end)
  end)

  describe("d21", function()
	it("i21", function() end)
	it("i22 only", function() end)
  end)
end)
]])
			local funcs, sel = p.to_pending_with_tags(bufnr, "only")
			assert.are.same(2, #funcs)
			assert.are.same({ desc = "i12", row = 3, col = 1, name = "it" }, funcs[1]:info())
			assert.are.same({ desc = "i21", row = 7, col = 1, name = "it" }, funcs[2]:info())
			assert.are.same(2, #sel)
			assert.are.same({ desc = "i11 only", row = 2, col = 1, name = "it" }, sel[1]:info())
			assert.are.same({ desc = "i22 only", row = 8, col = 1, name = "it" }, sel[2]:info())
		end)
	end)

	describe("search_node:", function()
		it("no pending funcs", function()
			local bufnr = create_buffer([[ pending("d1", function() end) ]])
			local search_node = create_node_mock({ 0, 1 })
			local funcs, sel = p.to_pending_with_node(bufnr, search_node)
			assert.are.same(0, #funcs)
			assert.are.same(0, #sel)
		end)

		it("ignore pending funcs", function()
			local bufnr = create_buffer([[ pending("d1", function() end) ]])
			local search_node = create_node_mock({ 0, 5 })
			local funcs = p.to_pending_with_node(bufnr, search_node)
			assert.are.same(0, #funcs)
		end)

		it("one node with match with no pending", function()
			local bufnr = create_buffer([[ it("i1", function() end) ]])
			local search_node = create_node_mock({ 0, 1 })
			local funcs, sel = p.to_pending_with_node(bufnr, search_node)
			assert.are.same(0, #funcs)
			assert.are.same(1, #sel)
			assert.are.same({ desc = "i1", row = 0, col = 1, name = "it" }, sel[1]:info())
		end)

		it("one node with no match is pending", function()
			local bufnr = create_buffer([[ it("i1", function() end) ]])
			local search_node = create_node_mock({ 0, 5 })
			local funcs, sel = p.to_pending_with_node(bufnr, search_node)
			assert.are.same(1, #funcs)
			assert.are.same({ desc = "i1", row = 0, col = 1, name = "it" }, funcs[1]:info())
			assert.are.same(0, #sel)
		end)

		it("select parent node, no pending", function()
			local bufnr = create_buffer([[
describe("d1", function()
	it("i11", function() end)
	it("i21", function() end)
end)
]])
			local search_node = create_node_mock({ 0, 0 })
			local funcs, sel = p.to_pending_with_node(bufnr, search_node)
			assert.are.same(0, #funcs)
			assert.are.same(1, #sel)
			assert.are.same({ desc = "d1", row = 0, col = 0, name = "describe" }, sel[1]:info())
		end)

		it("select one child, other child is pending", function()
			local bufnr = create_buffer([[
describe("d1", function()
	it("i11", function() end)
	it("i21", function() end)
end)
]])
			local search_node = create_node_mock({ 1, 1 })
			local funcs, sel = p.to_pending_with_node(bufnr, search_node)
			assert.are.same(1, #funcs)
			assert.are.same({ desc = "i21", row = 2, col = 1, name = "it" }, funcs[1]:info())
			assert.are.same(1, #sel)
			assert.are.same({ desc = "i11", row = 1, col = 1, name = "it" }, sel[1]:info())
		end)

		it("select describe without it", function()
			local bufnr = create_buffer([[
describe("d1", function()
  describe("d11", function()
  end)
end)
]])
			local search_node = create_node_mock({ 1, 2 })
			local funcs, sel = p.to_pending_with_node(bufnr, search_node)
			assert.are.same(0, #funcs)
			assert.are.same(1, #sel)
			assert.are.same({ desc = "d11", row = 1, col = 2, name = "describe" }, sel[1]:info())
		end)

		it("child of child, select parent child", function()
			local bufnr = create_buffer([[
describe("d1", function()
  describe("d11", function()
	it("i11", function() end)
	it("i21", function() end)
  end)
end)
]])
			local search_node = create_node_mock({ 1, 2 })
			local funcs, sel = p.to_pending_with_node(bufnr, search_node)
			assert.are.same(0, #funcs)
			assert.are.same(1, #sel)
			assert.are.same({ desc = "d11", row = 1, col = 2, name = "describe" }, sel[1]:info())
		end)

		it("child of child, select one it child, other child is pending", function()
			local bufnr = create_buffer([[
describe("d1", function()
  describe("d11", function()
	it("i11", function() end)
	it("i21", function() end)
  end)
end)
]])
			local search_node = create_node_mock({ 3, 1 })
			local funcs, sel = p.to_pending_with_node(bufnr, search_node)
			assert.are.same(1, #funcs)
			assert.are.same({ desc = "i11", row = 2, col = 1, name = "it" }, funcs[1]:info())
			assert.are.same(1, #sel)
			assert.are.same({ desc = "i21", row = 3, col = 1, name = "it" }, sel[1]:info())
		end)

		it("select one it child, with other func, means, no describe or it", function()
			local bufnr = create_buffer([[
describe("d11", function()
  local function foo(input) end
  it("i11", function() end)
  ohter_func(function() end)
end)
]])
			local search_node = create_node_mock({ 2, 2 })
			local funcs, sel = p.to_pending_with_node(bufnr, search_node)
			assert.are.same(0, #funcs)
			assert.are.same(1, #sel)
			assert.are.same({ desc = "i11", row = 2, col = 2, name = "it" }, sel[1]:info())
		end)
	end)
end)
