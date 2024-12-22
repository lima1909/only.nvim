local f = require("only.format")
local p = require("only.parser")

vim.api.nvim_create_user_command("Only", function(args)
	if args and #args.fargs > 0 then
		if args.fargs[1] == "m" then
			-- local input = args.args:sub(2) -- cut the 'm' command
			local bufnr = vim.api.nvim_get_current_buf()
			-- print("only .." .. bufnr)
			local to_pending_nodes = p.to_pending_with_tags(bufnr, "only")
			f.highlight_to_pending_nodes(to_pending_nodes, bufnr)
			return
		end

		vim.api.nvim_echo({ { "invalid Only command: " }, { args.fargs[1], "Error" } }, false, {})
	end
end, {
	nargs = "*", -- one or none argument
	range = true,
	desc = "Run a Only command",
	-- complete = cmd.complete,
})
