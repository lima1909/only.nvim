local M = {}

M.to_pending_with_tags = function(bufnr, tags)
	return M.new(bufnr, M.tag_filter(tags)):_find_fnodes()
end

M.selected_with_tags = function(bufnr, tags)
	return M.new(bufnr, M.tag_filter(tags)):_find_fnodes()
end

M.to_pending_with_node = function(bufnr, search_node)
	return M.new(bufnr, M.node_filter(search_node)):_find_fnodes()
end

M.new = function(bufnr, filter)
	return setmetatable({
		bufnr = bufnr or 0,
		filter = filter,
		to_pending = {},
		selected = {},
	}, { __index = M })
end

-- find 'describe' or 'it' top level functions,
-- which are under the root ('chunk') and do NOT contain the 'tag'
function M:_find_fnodes()
	local parser = vim.treesitter.get_parser(self.bufnr, "lua")
	local tree = parser:parse()[1]
	local root = tree:root()

	local query = vim.treesitter.query.parse(
		"lua",
		-- chunk means only the functions which are direct under the root node
		[[
( chunk 
( function_call name: (identifier) @fname (#any-of? @fname "describe" "it")) @func
)
]]
	)

	for id, node, _ in query:iter_captures(root, self.bufnr) do
		local capture_name = query.captures[id]
		if capture_name == "func" then
			local err, new_fnode = require("only.fnode").check_tsnode(node, self.bufnr)
			-- ignore not valid function node
			if not err then
				local n = new_fnode()

				if self.filter(n) == false then
					if #n.children > 0 then
						self:_children_walker(n)
					else
						table.insert(self.to_pending, n)
					end
				else
					table.insert(self.selected, n)
				end
			end
		end
	end

	return self.to_pending, self.selected
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
	for _, child in ipairs(parent_node.children) do
		if self.filter(child) == false then
			not_match = true

			if #child.children > 0 then
				not_match = false
				self:_children_walker(child)
			else
				table.insert(temp_children, child)
			end
		else
			at_least_one_match = true
			table.insert(self.selected, child)
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

	return function(fnode)
		if not tags or not fnode then
			return false
		end

		if not fnode.desc then
			return false
		end

		for _, t in ipairs(tags) do
			if fnode.desc:match(t) then
				return true
			end
		end

		return false
	end
end

function M.node_filter(search_node)
	return function(fnode)
		if not search_node or not fnode then
			return false
		end

		return search_node.row == fnode.row and search_node.col == fnode.col
	end
end

return M
