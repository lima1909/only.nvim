local assert = require("luassert")
local p = require("only.parser")

local function create_node_mock(val)
	return setmetatable({
		desc = function()
			return val
		end,
		range = function()
			return val[1], val[2]
		end,
	}, { __index = {} })
end

describe("filter:", function()
	describe("tag:", function()
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

		it("node is nil", function()
			assert.is_false(p.tag_filter()(nil))
			assert.is_false(p.tag_filter("bar")(nil))
			assert.is_false(p.tag_filter(nil)(nil))
		end)
	end)

	describe("node:", function()
		it("equals", function()
			local search_node = create_node_mock({ 2, 2 })
			local node = create_node_mock({ 2, 2 })
			assert.is_true(p.node_filter(search_node)(node))
		end)

		it("not equals", function()
			local search_node = create_node_mock({ 2, 2 })
			local node = create_node_mock({ 1, 2 })
			assert.is_false(p.node_filter(search_node)(node))

			node = create_node_mock({ 2, 1 })
			assert.is_false(p.node_filter(search_node)(node))

			node = create_node_mock({ 1, 3 })
			assert.is_false(p.node_filter(search_node)(node))
		end)

		it("node is nil", function()
			assert.is_false(p.node_filter(nil)(nil))

			local node = create_node_mock({ 1, 3 })
			assert.is_false(p.node_filter(node)(nil))
			assert.is_false(p.node_filter(nil)(node))
		end)
	end)
end)
