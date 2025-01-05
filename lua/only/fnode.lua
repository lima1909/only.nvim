-- create a wrapper for an TSNode, to get ease access to the methods:
-- - range: row and col
-- - name of the function
-- - text of the description
-- create a wrapper for an TSNode, to get ease access to the methods:
-- - range: row and col
-- - name of the function
-- - text of the description
local M = {}

-- create a wrapper for the TSNode, which is founded at the cursor position
M.node_at_cursor = function(source)
	source = source or 0

	local tsnode = vim.treesitter.get_node({ lang = "lua" })
	-- find first parent valid fnode
	while tsnode do
		local new_fnode = M.check_tsnode(tsnode, source)
		if new_fnode then
			return new_fnode()
		end

		tsnode = tsnode:parent()
	end
end

local function find_first_child_fnode(tsparent, source)
	for child in tsparent:iter_children() do
		local new_fnode = M.check_tsnode(child, source)
		if new_fnode then
			return child
		end

		local result = find_first_child_fnode(child, source)
		if result then
			return result
		end
	end

	return nil
end

local function find_children(tsparent, source)
	local children = {}

	local tschild = find_first_child_fnode(tsparent, source)
	while tschild do
		local new_fnode = M.check_tsnode(tschild, source)
		if new_fnode then
			table.insert(children, new_fnode())
		end
		tschild = tschild:next_sibling()
	end

	return children
end

-- check the tsnode, is it a valid fnode
-- if yes, then return name and description, otherwise a reason, why not
M.check_tsnode = function(tsnode, source)
	if tsnode:type() ~= "function_call" then
		return nil
	end

	local fname = tsnode:field("name")[1]
	local name = vim.treesitter.get_node_text(fname, source)
	if name ~= "describe" and name ~= "it" then
		return nil
	end

	local args = tsnode:field("arguments")
	if #args == 0 then
		return nil
	end

	-- child(0) == '(' and child(1) is the correct argument
	-- child_count must be greater then 1
	local args_child_count = args[1]:child_count()
	if args_child_count == 0 then
		return nil
	elseif args_child_count == 1 then
		return nil
	end

	local c = args[1]:child(1)
	local desc
	if c:type() == "string" then
		local d = c:field("content")[1]
		desc = vim.treesitter.get_node_text(d, source)
	elseif c:type() == "identifier" then
		desc = vim.treesitter.get_node_text(c, source)
	else
		return nil
	end

	-- create a wrapper for an TSNode, to get ease access to the methods:
	-- - range: row and col
	-- - name of the function
	-- - text of the description
	return function()
		local row, col, erow, ecol = tsnode:range()

		return {

			name = name,
			desc = desc,
			row = row + 1,
			col = col,
			erow = erow + 1,
			ecol = ecol,
			children = find_children(tsnode, source),
		}
	end
end

return M
