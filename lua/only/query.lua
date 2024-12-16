local n = require("only.node")

local M = {}

-- find 'describe' or 'it' top level functions,
-- which are under the root ('chunk') and do NOT contain the 'tag'
M.find_top_level_funcs = function(bufnr, tag)
	bufnr = bufnr or 0

	local parser = vim.treesitter.get_parser(bufnr, "lua")
	local tree = parser:parse()[1]
	local root = tree:root()

	local query = vim.treesitter.query.parse(
		"lua",
		-- chunk means only the functions wich are direct under the root node
		string.format(
			[[
(chunk 
(
   function_call
    name: (identifier) @fname
    (#any-of? @fname "describe" "it")

    arguments: (arguments 
  	(
	 string 
	 content: (string_content) @desc)
	 (#not-match? @desc ".*%s.*")
	) 
) @func
)
]],
			tag
		)
	)

	local nodes = {}

	for id, node, _ in query:iter_captures(root, bufnr) do
		local capture_name = query.captures[id]
		if capture_name == "func" then
			table.insert(nodes, n.new(node, bufnr))
			-- elseif capture_name == "desc" then
			-- 	local hl = "Search"
			-- 	local ns = 0
			-- 	local line, cs, _, ce = node:range()
			-- 	print("--" .. line .. " " .. cs .. " " .. ce)
			-- 	vim.api.nvim_buf_add_highlight(bufnr, ns, hl, line, cs, ce)
		end
	end

	return nodes
end

return M
