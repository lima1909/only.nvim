---@diagnostic disable: need-check-nil

local assert = require("luassert")
local f = require("only.func")

describe("query", function()
	local function parse(input)
		local parser = vim.treesitter.get_string_parser(input, "lua", {})
		local tree = parser:parse()[1]
		return tree:root()
	end

	it("onyl root node", function()
		local input = [[ 
describe("example", function() end)
]]
		local chunk = parse(input)
		local desc = f.new(chunk:child(0), input)
		assert.are.same("describe", desc:name())
		assert.are.same("example", desc:desc())
		assert.is_nil(desc:children())
	end)

	it("func with children", function()
		local input = [[ 
describe("example", function()
  it("first", function() end)
  it("second", function() end)
end)
]]
		local chunk = parse(input)
		local desc = f.new(chunk:child(0), input)
		assert.are.same("describe", desc:name())
		assert.are.same("example", desc:desc())

		local children = desc:children()
		assert.are.same(2, #children)
		assert.are.same("first", children[1]:desc())
		assert.are.same("second", children[2]:desc())
	end)

	it("func with children, children", function()
		local input = [[ 
describe("parent", function()
  describe("child", function() 
    it("child-child", function() end)
  end)
end)
]]
		local chunk = parse(input)
		local desc = f.new(chunk:child(0), input)
		assert.are.same({ desc = "parent", row = 1, col = 0, name = "describe" }, desc:info())

		local children = desc:children()
		assert.are.same(1, #children)
		assert.are.same({ desc = "child", row = 2, col = 2, name = "describe" }, children[1]:info())

		local child_child = desc:children()[1]:children()
		assert.are.same(1, #child_child)
		assert.are.same({ desc = "child-child", row = 3, col = 4, name = "it" }, child_child[1]:info())
	end)
end)