local namespace = vim.api.nvim_create_namespace("OnlyPendingNS")

vim.api.nvim_set_hl(
	namespace,
	"OnlyPendingHighlight",
	{ fg = "black", bg = "#d6a525", italic = true, bold = true, strikethrough = true }
)

local M = { highlights = {} }

-- HIGHLIGHT for all nodes, which a should converted to pending
-- the node needs two methods:
--	- range() (line and start column)
--	- the name() of the node/function
M.highlight = function(bufnr, funcs)
	local on = M.highlights[bufnr] or false
	vim.api.nvim_set_hl_ns(namespace)

	for _, f in pairs(funcs) do
		local line, cstart = f:range()
		if on == false then
			local cend = cstart + #f:name()
			vim.api.nvim_buf_add_highlight(bufnr, namespace, "OnlyPendingHighlight", line, cstart, cend)
			M.highlights[bufnr] = true
		else
			vim.api.nvim_buf_clear_namespace(bufnr, namespace, line, line + 1)
			M.highlights[bufnr] = false
		end
	end
end

return M
