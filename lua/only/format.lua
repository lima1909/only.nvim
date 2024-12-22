local M = {}

M.duration_to_str = function(duration)
	if not duration then
		return "no time avialable"
	end

	local duration_in_sec = duration / 1e9

	if duration_in_sec >= 1 then
		return string.format("%.2f s", duration_in_sec)
	elseif duration_in_sec >= 0.001 then
		return string.format("%.2f ms", duration_in_sec * 1000)
	elseif duration_in_sec >= 0.000001 then
		return string.format("%.2f µs", duration_in_sec * 1e6)
	else
		return string.format("%.2f ns", duration_in_sec * 1e9)
	end
end

-- HIGHLIGHT for all nodes, which a should converted to pending
-- the node needs two methods:
--	- range() (line and start column)
--	- the name() of the node/function
M.highlight_to_pending_nodes = function(to_pending_nodes, bufnr)
	bufnr = bufnr or 0
	local highlight = "Constant"
	local namespace = 0

	for _, n in pairs(to_pending_nodes) do
		local line, cstart = n:range()
		local cend = cstart + #n:name()
		vim.api.nvim_buf_add_highlight(bufnr, namespace, highlight, line, cstart, cend)
	end
end

return M
