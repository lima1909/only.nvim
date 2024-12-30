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
		if reset == false then
			local cend = f.col + #f.name
			vim.api.nvim_buf_add_highlight(bufnr, namespace, "OnlyPendingHighlight", f.row, f.col, cend)
			vim.fn.setqflist({
				{
					bufnr = bufnr,
					lnum = f.row + 1,
					col = 0,
					end_col = f.col,
					text = "only: " .. f.desc,
					type = "I",
				},
			}, "a")
			vim.fn.sign_place(0, "OnlyQuickfixGroup", "OnlyQuickfixMarker", vim.fn.bufnr("%"), { lnum = f.row + 1 })
		else
			vim.api.nvim_buf_clear_namespace(bufnr, namespace, f.row, f.row + 1)
			vim.fn.setqflist({ { bufnr = bufnr, lnum = f.row + 1, col = f.col } }, "f")
			vim.fn.sign_unplace("OnlyQuickfixGroup")
		end
	end

	if funcs then
		vim.api.nvim_echo({ { "found: " .. #funcs .. " functions", "Info" } }, false, {})
	end
end

return M
