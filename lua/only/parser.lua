local func = require("only.func")

local M = {}

M.to_pending_with_tags = function(bufnr, tags)
	return M.new(bufnr, M.tag_filter(tags)):_find_all_to_pending_funcs()
end

M.to_pending_with_node = function(bufnr, search_node)
	return M.new(bufnr, M.node_filter(search_node)):_find_all_to_pending_funcs()
end

M.new = function(bufnr, filter)
	return setmetatable({
		bufnr = bufnr or 0,
		filter = filter,
		to_pending = {},
	}, { __index = M })
end

-- find 'describe' or 'it' top level functions,
-- which are under the root ('chunk') and do NOT contain the 'tag'
function M:_find_all_to_pending_funcs()
	local parser = vim.treesitter.get_parser(self.bufnr, "lua")
	local tree = parser:parse()[1]
	local root = tree:root()

	local query = vim.treesitter.query.parse(
		"lua",
		-- chunk means only the functions which are direct under the root node
		[[
(chunk 
( function_call name: (identifier) @fname (#any-of? @fname "describe" "it")) @func
)
]]
	)

	for id, node, _ in query:iter_captures(root, self.bufnr) do
		local capture_name = query.captures[id]
		if capture_name == "func" then
			local n = func.new(node, self.bufnr)

			if self.filter(n) == false then
				if #n:children() > 0 then
					self:_children_walker(n)
				else
					table.insert(self.to_pending, n)
				end
			end
		end
	end

	return self.to_pending
end

function M:_children_walker(parent_node)
	if not parent_node then
		return
	end

	-- if no child matched, than add the parent-node to_pending
	local not_match = false
	-- if one child matched, than parent-node NOT add to_pending
	local at_least_one_match = false

	local temp_children = {}
	for _, child in ipairs(parent_node:children()) do
		if self.filter(child) == false then
			not_match = true

			if #child:children() > 0 then
				not_match = false
				self:_children_walker(child)
			else
				table.insert(temp_children, child)
			end
		else
			at_least_one_match = true
		end
	end

	if at_least_one_match == false and not_match == true then
		table.insert(self.to_pending, parent_node)
	elseif at_least_one_match == true and not_match == false then
		return
	else
		for _, c in ipairs(temp_children) do
			table.insert(self.to_pending, c)
		end
	end
end

function M.tag_filter(tag)
	local tags = tag
	if type(tag) == "string" then
		tags = { tag }
	end

	return function(func_node)
		if not tags or not func_node then
			return false
		end

		local desc = func_node:desc()
		if not desc then
			return false
		end

		for _, t in ipairs(tags) do
			if desc:match(t) then
				return true
			end
		end

		return false
	end
end

function M.node_filter(search_node)
	return function(func_node)
		if not search_node or not func_node then
			return false
		end

		local srow, scol = search_node:range()
		local frow, fcol = func_node:range()
		local result = srow == frow and scol == fcol
		return result
	end
end

return M
