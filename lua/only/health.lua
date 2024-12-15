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
		vim.health.error("Plenary busted is missing. Pleas install it.")
	end
	-- Additional checks
	vim.health.info("Only.nvim is healthy.")
end

return M
