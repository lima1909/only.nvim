local assert = require("luassert")
local f = require("only.fnode")

local parse_string = function(input)
	local parser = vim.treesitter.get_string_parser(input, "lua", {})
	local tree = parser:parse()[1]
	local chunk = tree:root()
	local first_child = chunk:child(0)
	local err, new_fnode = f.check_tsnode(first_child, input)
	if err then
		print("Hint: " .. tostring(err))
		return {}, err
	end

	return new_fnode(), err
end

local function info(n)
	return { row = n.row, col = n.col, name = n.name, desc = n.desc }
end

describe("node at cursor:", function()
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
		local n = f.node_at_cursor(bufnr)
		assert.is_nil(n)

		bufnr = create_win_and_set_cursor(input, { 3, 1 })
		n = f.node_at_cursor(bufnr)
		assert.is_nil(n)

		bufnr = create_win_and_set_cursor(input, { 4, 1 })
		n = f.node_at_cursor(bufnr)
		assert.is_nil(n)
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

describe("fnode:", function()
	it("onyl root node", function()
		local input = [[ 
describe("example", function() end)
]]
		local n = parse_string(input)
		assert.are.same("describe", n.name)
		assert.are.same("example", n.desc)
		assert.are.same({}, n.children)
	end)

	it("func with children", function()
		local input = [[
describe("example", function()
  it("first", function() end)
  it("second", function() end)
end)
]]
		local n, hint = parse_string(input)
		assert.is_nil(hint)
		assert.are.same("describe", n.name)
		assert.are.same("example", n.desc)

		assert.are.same(2, #n.children)
		assert.are.same("first", n.children[1].desc)
		assert.are.same("second", n.children[2].desc)
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
		assert.are.same({ desc = "parent", row = 0, col = 0, name = "describe" }, info(n))

		assert.are.same(1, #n.children)
		assert.are.same({ desc = "child", row = 1, col = 2, name = "describe" }, info(n.children[1]))

		local child_child = n.children[1].children
		assert.are.same(1, #child_child)
		assert.are.same({ desc = "child-child", row = 2, col = 4, name = "it" }, info(child_child[1]))
	end)

	it("func with child, two children", function()
		local input = [[
describe("parent", function()
  describe("child1", function()
    it("child11", function() end)
  end)

  describe("child2", function()
    it("child21", function() end)
    it("child22", function() end)
  end)
end)
]]
		local n, err = parse_string(input)
		assert.is_nil(err)
		assert.are.same({ desc = "parent", row = 0, col = 0, name = "describe" }, info(n))

		assert.are.same(2, #n.children)
		assert.are.same({ desc = "child1", row = 1, col = 2, name = "describe" }, info(n.children[1]))
		assert.are.same({ desc = "child2", row = 5, col = 2, name = "describe" }, info(n.children[2]))

		local child11 = n.children[1].children
		assert.are.same(1, #child11)
		assert.are.same({ desc = "child11", row = 2, col = 4, name = "it" }, info(child11[1]))

		local child21 = n.children[2].children
		assert.are.same(2, #child21)
		assert.are.same({ desc = "child21", row = 6, col = 4, name = "it" }, info(child21[1]))
		assert.are.same({ desc = "child22", row = 7, col = 4, name = "it" }, info(child21[2]))
	end)

	it("is not a string parameter, is an identifier", function()
		local input = [[ 
describe(example, function() end)
]]
		local n, err = parse_string(input)
		assert.is_nil(err)
		assert.are.same({ desc = "example", row = 1, col = 0, name = "describe" }, info(n))
	end)
end)

describe("fnode errors:", function()
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
		local foo = n.children[1]
		assert.is_nil(foo)
	end)

	it("1 is not valid parameter", function()
		local input = [[ 
describe(1, function() end)
]]
		local _, err = parse_string(input)
		assert.is_not_nil(err)
	end)

	it("is not valid function_call", function()
		local input = [[ 
function("test", function() end)
]]
		local _, err = parse_string(input)
		assert.is_not_nil(err)
	end)

	it("no parameters", function()
		local input = [[ 
describe()
]]
		local _, err = parse_string(input)
		assert.is_not_nil(err)
	end)
end)
