local harness = require("only.harness")
local parser = require("only.parser")
local fnode = require("only.fnode")

local M = {}

M._prepare_run = function(bufnr, opts)
	bufnr = bufnr or 0
	opts = opts or {}

	local pendings

	if opts.tags then
		local tags = vim.split(opts.tags, ",")
		pendings = parser.to_pending_with_tags(bufnr, tags)
	elseif opts.at_cursor then
		local n = fnode.node_at_cursor(bufnr)
		if not n then
			vim.api.nvim_echo({ { "invalid cursor position, no test-function found", "Error" } }, false, {})
			return
		end

		pendings = parser.to_pending_with_node(bufnr, n)
	else
		vim.api.nvim_echo({ { "no run mode: 'tags' or 'at_cursor' set", "Error" } }, false, {})
		return
	end

	-- no pendings found, use the current file
	local count_pendings = vim.tbl_count(pendings)
	if count_pendings == 0 then
		require("plenary.test_harness").test_file(vim.api.nvim_buf_get_name(0))
		return
	end

	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local file = harness.new():remove_pendings(lines, pendings)

	return file, count_pendings
end

M.run = function(bufnr, opts)
	local file = M._prepare_run(bufnr, opts)
	require("plenary.test_harness").test_file(file)
end

return M
