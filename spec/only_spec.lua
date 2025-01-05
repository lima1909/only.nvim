local assert = require("luassert")
local only = require("only")

describe("only for fnode_spec:", function()
	local bufnr

	before_each(function()
		local file = "./spec/fnode_spec.lua"
		bufnr = vim.fn.bufadd(file)
		vim.fn.bufload(bufnr)

		vim.api.nvim_open_win(bufnr, true, {
			relative = "editor",
			width = 40,
			height = 10,
			row = 5,
			col = 5,
			style = "minimal",
		})
		local winnr = vim.api.nvim_get_current_win()
		vim.api.nvim_win_set_cursor(winnr, { 60, 1 })
	end)

	after_each(function()
		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)

	it("check tags", function()
		local file, count_pendings = only._prepare_run(bufnr, { tags = "#only" })
		assert.are.same(count_pendings, 7)
		assert.is_not_nil(vim.loop.fs_stat(file))
	end)

	it("check at_cursor", function()
		local file, count_pendings = only._prepare_run(bufnr, { at_cursor = true })
		assert.are.same(count_pendings, 4)
		assert.is_not_nil(vim.loop.fs_stat(file))
	end)
end)
