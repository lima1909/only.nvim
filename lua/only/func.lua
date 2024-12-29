local M = {}

local function find_first_parent_func_node(tsnode, source)
	while tsnode do
		local node, err = M.new(tsnode, source)
		if not err then
			return node
		end

		tsnode = tsnode:parent()
	end

	return nil
end

-- create a wrapper for an TSNode, to get ease access to the methods:
-- - range: row and col
-- - name of the function
-- - text of the description
--
M.new = function(tsnode, source)
	if tsnode:type() ~= "function_call" then
		return nil, "type is not a function_call: " .. tsnode:type()
	end

	local args = tsnode:field("arguments")
	if #args == 0 then
		return nil, "arguments are missing"
	end

	-- child(0) == '(' and child(1) is the correct argument
	-- child_count must be greater then 1
	local args_child_count = args[1]:child_count()
	if args_child_count == 0 then
		return nil, "missing arguments childs"
	elseif args_child_count == 1 then
		local txt = vim.treesitter.get_node_text(args[1]:child(0), source)
		return nil, "invalid argument child: '" .. txt .. "'. Expected: '('"
	end

	local c = args[1]:child(1)
	local desc
	if c:type() == "string" then
		local d = c:field("content")[1]
		desc = vim.treesitter.get_node_text(d, source)
	elseif c:type() == "identifier" then
		desc = vim.treesitter.get_node_text(c, source)
	else
		return nil, "invalid argument type: " .. c:type()
	end

	local row, col = tsnode:range()
	local name = tsnode:field("name")[1]
	local n = {
		desc = desc,
		name = vim.treesitter.get_node_text(name, source),
		row = row,
		col = col,
		inner = tsnode,
		source = source or 0,
	}

	return setmetatable(n, { __index = M })
end

-- create a wrapper for the TSNode, which is founded at the cursor position
M.node_at_cursor = function(source)
	source = source or 0

	local node = find_first_parent_func_node(vim.treesitter.get_node({ lang = "lua" }), source)
	if not node then
		error("no function node found", 0)
	end

	return node
end

function M:_find_first_child_func_node(tsparent_node)
	for child in tsparent_node:iter_children() do
		local _, err = M.new(child, self.source)
		if not err then
			return child
		end

		local result = self:_find_first_child_func_node(child)
		if result then
			return result
		end
	end

	return nil
end

function M:children()
	local children = {}

	local child_func = self:_find_first_child_func_node(self.inner)
	while child_func do
		local node, err = M.new(child_func, self.source)
		if not err then
			table.insert(children, node)
		end
		child_func = child_func:next_sibling()
	end

	return children
end

function M:info()
	return { row = self.row, col = self.col, name = self.name, desc = self.desc }
end

return M
