local func = require("only.func")

local M = {}

M.new = function(bufnr, tag)
	return setmetatable({
		bufnr = bufnr,
		tag = tag,
		to_pending = {},
		must_check = {},
	}, { __index = M })
end

-- find 'describe' or 'it' top level functions,
-- which are under the root ('chunk') and do NOT contain the 'tag'
function M:find_top_level_funcs()
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

			if n:desc():match(self.tag) then
				table.insert(self.to_pending, n)
			else
				table.insert(self.must_check, n)
			end
			-- HIGHLIGHT
			-- elseif capture_name == "desc" then
			-- 	local hl = "Search"
			-- 	local ns = 0
			-- 	local line, cs, _, ce = node:range()
			-- 	print("--" .. line .. " " .. cs .. " " .. ce)
			-- 	vim.api.nvim_buf_add_highlight(bufnr, ns, hl, line, cs, ce)
		end
	end

	return self
end

return M
