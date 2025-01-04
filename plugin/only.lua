vim.api.nvim_create_user_command("OnlyTestFile", function(args)
	if args and #args.fargs > 0 then
		local only = require("only")

		local opts = {}

		if args.fargs[1] == "tags" then
			local tags = args.args:sub(5) -- cut the 'tags ' command
			opts.tags = vim.trim(tags)
		elseif args.fargs[1] == "at_cursor" then
			opts.at_cursor = true
		end

		local bufnr = vim.api.nvim_get_current_buf()
		only.run(bufnr, opts)

		-- local hl = require("only.highlight")
		-- local p = require("only.parser")
		-- local f = require("only.fnode")
		--
		-- if args.fargs[1] == "tags" then
		-- 	local input = args.args:sub(5) -- cut the 'tags ' command
		-- 	input = vim.trim(input)
		-- 	local tags = vim.split(input, ",")
		-- 	local _, funcs = p.selected_with_tags(bufnr, tags)
		-- 	hl.highlight(bufnr, funcs)
		-- 	return
		-- elseif args.fargs[1] == "reset" then
		-- 	hl.highlight(bufnr)
		-- 	return
		-- elseif args.fargs[1] == "cursor" then
		-- 	local func = f.node_at_cursor(bufnr)
		-- 	if not func then
		-- 		vim.api.nvim_echo({ { "invalid cursor position, no function found", "Error" } }, false, {})
		-- 	else
		-- 		hl.highlight(bufnr, { func })
		-- 	end
		-- end
	end
end, {
	nargs = "*", -- one or none argument
	range = true,
	desc = "Run a Only command",
	-- complete = cmd.complete,
})
