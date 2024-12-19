local assert = require("luassert")
local f = require("only.func")

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
