local M = {}

-- create a wrapper for an TSNode, to get ease access to the methods:
-- - range
-- - name of the function
-- - text of the description
--
M.new = function(tsnode, bufnr_or_code)
	return setmetatable({
		inner = tsnode,
		content = bufnr_or_code or 0,
	}, { __index = M })
end

function M:range()
	return self.inner:range()
end

function M:name()
	if self.inner:type() == "function_call" then
		local name = self.inner:field("name")[1]
		return vim.treesitter.get_node_text(name, self.content)
	else
		error("this node is not an function_call: " .. self.inner:type(), 0)
	end
end

function M:desc()
	if self.inner:type() == "function_call" then
		local arg = self.inner:field("arguments")[1]
		local desc = arg:child(1):field("content")[1]
		return vim.treesitter.get_node_text(desc, self.content)
	else
		error("this node is not an function_call: " .. self.inner:type(), 0)
	end
end

local function find_first_func_node(parent_node, content)
	for child in parent_node:iter_children() do
		if child:type() == "function_call" then
			return M.new(child, content)
		end

		local result = find_first_func_node(child, content)
		if result then
			return result
		end
	end

	return nil
end

function M:children()
	local child_func = find_first_func_node(self.inner, self.content)
	if not child_func then
		return nil
	end

	local children = { child_func }

	while true do
		local next = child_func.inner:next_sibling()
		if not next then
			return children
		end

		child_func = M.new(next, self.content)
		table.insert(children, child_func)
	end
end

function M:info()
	local r, c = self:range()
	return { row = r, col = c, name = self:name(), desc = self:desc() }
end

-- M.find_children = function(parent_node, results)
-- 	results = results or {}
--
-- 	if not parent_node then
-- 		return results
-- 	end
--
-- 	for child in parent_node:iter_children() do
-- 		if child:type() == "function_call" then
-- 			table.insert(results, child)
-- 		end
--
-- 		M.find_children(child, results)
-- 	end
--
-- 	return results
-- end

return M
