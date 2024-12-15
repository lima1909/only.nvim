local M = {}

-- create a wrapper for an TSNode, to get ease access to the methods:
-- - range
-- - name of the function
-- - text of the description
--
M.new = function(tsnode, bufnr)
	return setmetatable({
		inner = tsnode,
		bufnr = bufnr or 0,
	}, { __index = M })
end

function M:range()
	return self.inner:range()
end

function M:func_name()
	if self.inner:type() == "function_call" then
		local name = self.inner:field("name")[1]
		return vim.treesitter.get_node_text(name, self.bufnr)
	else
		error("this node is not an function_call: ", self.inner:type())
	end
end

function M:func_desc()
	if self.inner:type() == "function_call" then
		local arg = self.inner:field("arguments")[1]
		local desc = arg:child(1):field("content")[1]
		return vim.treesitter.get_node_text(desc, self.bufnr)
	else
		error("this node is not an function_call: ", self.inner:type())
	end
end

function M:info()
	local r, c = self:range()
	return { row = r, col = c, name = self:func_name(), desc = self:func_desc() }
end

return M
