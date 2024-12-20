local assert = require("luassert")
local f = require("only.func")

describe("get func node:", function()
	local function create_win_and_set_cursor(input, cursor)
		local bufnr = vim.api.nvim_create_buf(false, false)
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(input, "\n"))
		vim.api.nvim_set_current_buf(bufnr)

		vim.api.nvim_open_win(bufnr, false, { relative = "win", row = 10, col = 30, width = 12, height = 30 })
		local winnr = vim.api.nvim_get_current_win()

		vim.api.nvim_win_set_cursor(winnr, cursor)

		return bufnr
	end

	it("func not found", function()
		local input = [[
-- comment
describe("describe test-func", function() end)

before_each(function() end)
]]
		local bufnr = create_win_and_set_cursor(input, { 1, 1 })
		local ok = pcall(f.node_at_cursor, bufnr)
		assert.is_false(ok)

		bufnr = create_win_and_set_cursor(input, { 3, 1 })
		ok = pcall(f.node_at_cursor, bufnr)
		assert.is_false(ok)

		bufnr = create_win_and_set_cursor(input, { 4, 1 })
		ok = pcall(f.node_at_cursor, bufnr)
		assert.is_false(ok)
	end)

	it("func found", function()
		local bufnr = create_win_and_set_cursor(
			[[
-- comment
describe("describe test-func", function() end)
]],
			{ 2, 1 }
		)

		local func = f.node_at_cursor(bufnr)
		assert.are.same("describe test-func", func:desc())
	end)

	it("func found", function()
		local input = [[
-- comment
describe("describe", function()
  it("it test-func", function()
    before_each(function() end)
  end)
end)
]]
		local bufnr = create_win_and_set_cursor(input, { 3, 3 })
		local func = f.node_at_cursor(bufnr)
		assert.are.same("it test-func", func:desc())

		bufnr = create_win_and_set_cursor(input, { 4, 6 })
		func = f.node_at_cursor(bufnr)
		assert.are.same("it test-func", func:desc())

		bufnr = create_win_and_set_cursor(input, { 5, 3 })
		func = f.node_at_cursor(bufnr)
		assert.are.same("it test-func", func:desc())

		bufnr = create_win_and_set_cursor(input, { 2, 3 })
		func = f.node_at_cursor(bufnr)
		assert.are.same("describe", func:desc())

		bufnr = create_win_and_set_cursor(input, { 6, 3 })
		func = f.node_at_cursor(bufnr)
		assert.are.same("describe", func:desc())
	end)
end)

describe("func nodes:", function()
	local parse_string = function(input)
		local parser = vim.treesitter.get_string_parser(input, "lua", {})
		local tree = parser:parse()[1]
		local chunk = tree:root()
		return f.new(chunk, input)
	end

	it("onyl root node", function()
		local input = [[ 
describe("example", function() end)
]]
		local chunk = parse_string(input)
		local desc = chunk:children()[1]
		assert.are.same("describe", desc:name())
		assert.are.same("example", desc:desc())
		assert.are.same({}, desc:children())
	end)

	it("func with children", function()
		local input = [[
describe("example", function()
  it("first", function() end)
  it("second", function() end)
end)
]]
		local chunk = parse_string(input)
		local desc = chunk:children()[1]
		assert.are.same("describe", desc:name())
		assert.are.same("example", desc:desc())

		local children = desc:children()
		assert.are.same(2, #children)
		assert.are.same("first", children[1]:desc())
		assert.are.same("second", children[2]:desc())
	end)

	it("func with child, child", function()
		local input = [[
describe("parent", function()
  describe("child", function()
    it("child-child", function() end)
  end)
end)
]]
		local chunk = parse_string(input)
		local desc = chunk:children()[1]
		assert.are.same({ desc = "parent", row = 0, col = 0, name = "describe" }, desc:info())

		local children = desc:children()
		assert.are.same(1, #children)
		assert.are.same({ desc = "child", row = 1, col = 2, name = "describe" }, children[1]:info())

		local child_child = desc:children()[1]:children()
		assert.are.same(1, #child_child)
		assert.are.same({ desc = "child-child", row = 2, col = 4, name = "it" }, child_child[1]:info())
	end)
end)
