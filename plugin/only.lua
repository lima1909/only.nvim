local f = require("only.fnode")
local p = require("only.parser")
local hl = require("only.highlight")

vim.api.nvim_create_user_command("OnlyShow", function(args)
	local bufnr = vim.api.nvim_get_current_buf()

	if args and #args.fargs > 0 then
		if args.fargs[1] == "tags" then
			local input = args.args:sub(5) -- cut the 'tags ' command
			input = vim.trim(input)
			local tags = vim.split(input, ",")
			-- local funcs = p.to_pending_with_tags(bufnr, tags)
			local _, funcs = p.selected_with_tags(bufnr, tags)
			hl.highlight(bufnr, funcs)
			return
		elseif args.fargs[1] == "reset" then
			hl.highlight(bufnr)
			return
		end

		vim.api.nvim_echo({ { "invalid Only command: " }, { args.fargs[1], "Error" } }, false, {})
		-- else
		-- 	local func = f.node_at_cursor(bufnr)
		-- 	hl.highlight(bufnr, { func })
	end
end, {
	nargs = "*", -- one or none argument
	range = true,
	desc = "Run a Only command",
	-- complete = cmd.complete,
})
