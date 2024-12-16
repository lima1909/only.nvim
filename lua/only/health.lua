local M = {}

function M.check()
	local nvim_version = vim.version()
	if nvim_version.minor >= 10 then
		vim.health.ok("Neovim version is compatible.")
	else
		vim.health.error("Neovim version is too old. Please update to 0.10 or newer.")
	end

	local has_busted = pcall(require, "plenary.busted")
	if has_busted == true then
		vim.health.ok("Plenary busted is installed.")
	else
		vim.health.error("Plenary busted is missing. Pleas install: 'nvim-lua/plenary.nvim'.")
	end

	local ts_parsers = require("nvim-treesitter.parsers")
	local lua_parser_installed = ts_parsers.has_parser("lua")
	if lua_parser_installed then
		print("Tree-sitter Lua parser is installed.")
		vim.health.ok("Treesitter for the LUA-parser is installed.")
	else
		print("Treesitter for the LUA-parser is not installed.")
	end

	-- Additional checks
	vim.health.info("'only.nvim' is HEALTHY.")
end

return M
