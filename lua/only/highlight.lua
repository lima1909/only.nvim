local namespace = vim.api.nvim_create_namespace("OnlyPendingNS")

vim.api.nvim_set_hl(namespace, "OnlyPendingHighlight", { fg = "black", bg = "#d6a525", italic = false, bold = false })
vim.fn.sign_define("OnlyQuickfixMarker", { text = "=>", texthl = "Function" })

local M = { funcs = {} }

-- HIGHLIGHT for all nodes, which a should converted to pending
-- the node needs two methods:
--	- range() (line and start column)
--	- the name() of the node/function
M.highlight = function(bufnr, funcs)
	vim.api.nvim_set_hl_ns(namespace)
	local reset
	if funcs then
		M.funcs = funcs
		reset = false
	else
		funcs = M.funcs
		reset = true
	end

	for _, f in pairs(funcs) do
		local line, cstart = f:range()
		if reset == false then
			local cend = cstart + #f:name()
			vim.api.nvim_buf_add_highlight(bufnr, namespace, "OnlyPendingHighlight", line, cstart, cend)
			vim.fn.setqflist({
				{
					bufnr = bufnr,
					lnum = line + 1,
					col = 0,
					end_col = cstart,
					text = "only: " .. f:desc(),
					type = "I",
				},
			}, "a")
			vim.fn.sign_place(0, "OnlyQuickfixGroup", "OnlyQuickfixMarker", vim.fn.bufnr("%"), { lnum = line + 1 })
		else
			vim.api.nvim_buf_clear_namespace(bufnr, namespace, line, line + 1)
			vim.fn.setqflist({ { bufnr = bufnr, lnum = line + 1, col = cstart } }, "f")
			vim.fn.sign_unplace("OnlyQuickfixGroup")
		end
	end
end

return M
