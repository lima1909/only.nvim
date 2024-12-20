local M = {}

local function find_first_parent_func_node(node, source)
	while node do
		if node:type() == "function_call" then
			local name = node:field("name")[1]
			local txt = vim.treesitter.get_node_text(name, source)
			if txt == "describe" or txt == "it" then
				return node
			end
		end

		node = node:parent()
	end

	return nil
end

-- create a wrapper for an TSNode, to get ease access to the methods:
-- - range
-- - name of the function
-- - text of the description
--
M.new = function(tsnode, source)
	return setmetatable({
		inner = tsnode,
		source = source or 0,
	}, { __index = M })
end

-- create a wrapper for the TSNode, which is founded at the cursor position
M.node_at_cursor = function(source)
	source = source or 0

	local node = find_first_parent_func_node(vim.treesitter.get_node({ lang = "lua" }), source)
	if not node then
		error("no funcion node found", 0)
	end

	return M.new(node, source)
end

function M:range()
	return self.inner:range()
end

function M:name()
	if self.inner:type() == "function_call" then
		local name = self.inner:field("name")[1]
		return vim.treesitter.get_node_text(name, self.source)
	else
		error("this node is not an function_call: " .. self.inner:type(), 0)
	end
end

function M:desc()
	if self.inner:type() == "function_call" then
		local arg = self.inner:field("arguments")[1]
		local desc = arg:child(1):field("content")[1]
		return vim.treesitter.get_node_text(desc, self.source)
	else
		error("this node is not an function_call: " .. self.inner:type(), 0)
	end
end

local function find_first_child_func_node(parent_node)
	for child in parent_node:iter_children() do
		if child:type() == "function_call" then
			return child
		end

		local result = find_first_child_func_node(child)
		if result then
			return result
		end
	end

	return nil
end

function M:children()
	local children = {}

	local child_func = find_first_child_func_node(self.inner)
	while child_func do
		table.insert(children, M.new(child_func, self.source))
		child_func = child_func:next_sibling()
	end

	return children
end

function M:info()
	local r, c = self:range()
	return { row = r, col = c, name = self:name(), desc = self:desc() }
end

return M
