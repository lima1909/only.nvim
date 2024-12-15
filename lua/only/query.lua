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

	local funcs = {}
	local current

	for id, node, _ in query:iter_captures(root, bufnr) do
		local capture_name = query.captures[id]
		if capture_name == "func" then
			-- has no parent, root functions
			-- if not node:parent():parent() then
			local row, col = node:range()
			current = { row = row, col = col }
			-- else
			-- reset current, if it is not a root function
			-- current = nil
			-- end
		elseif capture_name == "fname" and current then
			current.name = vim.treesitter.get_node_text(node, bufnr)
		elseif capture_name == "desc" and current then
			current.desc = vim.treesitter.get_node_text(node, bufnr)
			table.insert(funcs, current)
		end
	end

	return funcs
end

return M
