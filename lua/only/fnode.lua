local M = {}

-- create a wrapper for the TSNode, which is founded at the cursor position
M.node_at_cursor = function(source)
	source = source or 0

	local tsnode = vim.treesitter.get_node({ lang = "lua" })
	-- find first parent valid fnode
	while tsnode do
		local err, new_fnode = M.check_tsnode(tsnode, source)
		if not err then
			return new_fnode()
		end

		tsnode = tsnode:parent()
	end
end

local function find_first_child_fnode(tsparent, source)
	for child in tsparent:iter_children() do
		local err = M.check_tsnode(child, source)
		if not err then
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
		local err, new_fnode = M.check_tsnode(tschild, source)
		if not err then
			table.insert(children, new_fnode())
		end
		tschild = tschild:next_sibling()
	end

	return children
end

local function hint(tsnode, source, msg)
	local row, col = tsnode:range()

	local name = ""
	local fname = tsnode:field("name")[1]
	if fname then
		name = "function '" .. vim.treesitter.get_node_text(fname, source) .. "': "
	end

	return setmetatable({
		row = row,
		col = col,
		msg = msg,
	}, {
		__tostring = function(s)
			return name .. s.msg .. ": [" .. s.row .. ":" .. s.col .. "]"
		end,
	})
end

-- check the tsnode, is it a valid fnode
-- if yes, then return name and description, otherwise a reason, why not
M.check_tsnode = function(tsnode, source)
	if tsnode:type() ~= "function_call" then
		return hint(tsnode, source, "type is not a function_call, is from type: '" .. tsnode:type() .. "'")
	end

	local args = tsnode:field("arguments")
	if #args == 0 then
		return hint(tsnode, source, "arguments are missing")
	end

	-- child(0) == '(' and child(1) is the correct argument
	-- child_count must be greater then 1
	local args_child_count = args[1]:child_count()
	if args_child_count == 0 then
		return hint(tsnode, source, "missing arguments childs")
	elseif args_child_count == 1 then
		local txt = vim.treesitter.get_node_text(args[1]:child(0), source)
		return hint(tsnode, source, "invalid argument child: '" .. txt .. "'. Expected: '('")
	end

	local c = args[1]:child(1)
	local desc
	if c:type() == "string" then
		local d = c:field("content")[1]
		desc = vim.treesitter.get_node_text(d, source)
	elseif c:type() == "identifier" then
		desc = vim.treesitter.get_node_text(c, source)
	else
		return hint(tsnode, source, "invalid argument type: '" .. c:type() .. "' Expected 'string' or 'identifier'.")
	end

	local fname = tsnode:field("name")[1]
	local name = vim.treesitter.get_node_text(fname, source)
	if name ~= "describe" and name ~= "it" then
		return hint(tsnode, source, "function name must be 'describe' or 'it', but is: '" .. name .. "'")
	end

	return nil,
		-- create a wrapper for an TSNode, to get ease access to the methods:
		-- - range: row and col
		-- - name of the function
		-- - text of the description
		function()
			local row, col = tsnode:range()

			return {

				name = name,
				desc = desc,
				row = row,
				col = col,
				children = find_children(tsnode, source),
			}
		end
end

return M
