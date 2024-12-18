local func = require("only.func")

-- to_check can be for example the: tag
local function default_filter(node, to_check)
	to_check = to_check or "only"

	if not node:desc():match(to_check) then
		return false
	end

	return true
end

local M = {}

function M.find_all_to_pending_funcs(bufnr, tag)
	return M.new(bufnr, tag):_find_all_to_pending_funcs()
end

M.new = function(bufnr, tag)
	return setmetatable({
		bufnr = bufnr,
		tag = tag,
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

			-- TODO: change this to the filter function
			if n:desc():match(self.tag) then
				-- will be converted to pending function
				table.insert(self.to_pending, n)
			else
				self:_children_walker(n)
			end
		end
	end

	return self.to_pending
end

function M:_children_walker(parent_node, filter)
	if not parent_node then
		return self
	end

	filter = filter or default_filter
	-- if one child matched, than parent-node NOT add to_pending
	local parent_to_pending = true
	-- if no child matched, than add the parent-node to_pending
	local no_match = false

	local temp_children = {}
	for _, child in ipairs(parent_node:children()) do
		if filter(child) == true then
			parent_to_pending = false
			table.insert(temp_children, child)
		else
			no_match = true
		end

		self:_children_walker(child)
	end

	if (no_match == true and parent_to_pending == true) or (no_match == false and parent_to_pending == false) then
		table.insert(self.to_pending, parent_node)
	else
		for _, c in ipairs(temp_children) do
			table.insert(self.to_pending, c)
		end
	end

	return self
end

return M
