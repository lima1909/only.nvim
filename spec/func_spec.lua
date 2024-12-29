---@diagnostic disable: need-check-nil

local assert = require("luassert")
local f = require("only.func")

local parse_string = function(input)
	local parser = vim.treesitter.get_string_parser(input, "lua", {})
	local tree = parser:parse()[1]
	local chunk = tree:root()
	local first_child = chunk:child(0)
	local n, err = f.new(first_child, input)
	if err then
		print("Error: " .. err)
	end
	return n, err
end

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
			{ 2, 0 }
		)

		local func = f.node_at_cursor(bufnr)
		assert.are.same("describe test-func", func.desc)
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
		assert.are.same("it test-func", func.desc)

		bufnr = create_win_and_set_cursor(input, { 4, 6 })
		func = f.node_at_cursor(bufnr)
		assert.are.same("it test-func", func.desc)

		bufnr = create_win_and_set_cursor(input, { 5, 3 })
		func = f.node_at_cursor(bufnr)
		assert.are.same("it test-func", func.desc)

		bufnr = create_win_and_set_cursor(input, { 2, 3 })
		func = f.node_at_cursor(bufnr)
		assert.are.same("describe", func.desc)

		bufnr = create_win_and_set_cursor(input, { 6, 3 })
		func = f.node_at_cursor(bufnr)
		assert.are.same("describe", func.desc)
	end)
end)

describe("func nodes:", function()
	it("onyl root node", function()
		local input = [[ 
describe("example", function() end)
]]
		local n, err = parse_string(input)
		assert.is_nil(err)
		assert.are.same("describe", n.name)
		assert.are.same("example", n.desc)
		assert.are.same({}, n:children())
	end)

	it("func with children", function()
		local input = [[
describe("example", function()
  it("first", function() end)
  it("second", function() end)
end)
]]
		local n, err = parse_string(input)
		assert.is_nil(err)
		assert.are.same("describe", n.name)
		assert.are.same("example", n.desc)

		local children = n:children()
		assert.are.same(2, #children)
		assert.are.same("first", children[1].desc)
		assert.are.same("second", children[2].desc)
	end)

	it("func with child, child", function()
		local input = [[
describe("parent", function()
  describe("child", function()
    it("child-child", function() end)
  end)
end)
]]
		local n, err = parse_string(input)
		assert.is_nil(err)
		assert.are.same({ desc = "parent", row = 0, col = 0, name = "describe" }, n:info())

		local children = n:children()
		assert.are.same(1, #children)
		assert.are.same({ desc = "child", row = 1, col = 2, name = "describe" }, children[1]:info())

		local child_child = n:children()[1]:children()
		assert.are.same(1, #child_child)
		assert.are.same({ desc = "child-child", row = 2, col = 4, name = "it" }, child_child[1]:info())
	end)
end)

describe("func node errors:", function()
	it("missing open parentheses", function()
		local input = [[ 
describe"example", function() end)
]]
		local _, err = parse_string(input)
		assert.is_not_nil(err)
	end)

	it("is not describe or it function", function()
		local input = [[ 
describe("example", function()
  foo()
end)
]]
		local n, err = parse_string(input)
		assert.is_nil(err)
		local foo = n:children()[1]
		assert.is_nil(foo)
	end)
end)
