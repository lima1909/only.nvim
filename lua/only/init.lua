local harness = require("only.harness")
local parser = require("only.parser")
local fnode = require("only.fnode")

local M = {}

M.run = function(bufnr, opts)
	bufnr = bufnr or 0
	opts = opts or {}

	local pendings

	if opts.tags then
		local tags = vim.split(opts.run.tags, ",")
		pendings = parser.to_pending_with_tags(bufnr, tags)
	elseif opts.cursor then
		local n = fnode.node_at_cursor(bufnr)
		if not n then
			vim.api.nvim_echo({ { "invalid cursor position, no function found", "Error" } }, false, {})
			return
		end

		pendings = parser.to_pending_with_node(bufnr, n)
	else
		vim.api.nvim_echo({ { "no run mode set", "Error" } }, false, {})
		return
	end

	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local file, clear = harness.new():remove_pendings(lines, pendings)
	require("plenary.test_harness").test_file(file)
	clear()
end

return M
