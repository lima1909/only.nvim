local file_name

local function create_temp_file()
	file_name = vim.fn.tempname()
	local file = io.open(file_name, "w")
	if not file then
		error("Failed to create temp file: " .. file_name)
	end

	return file
end

local M = {}

M.new = function(writer)
	if file_name then
		pcall(vim.fn.delete, file_name)
	end

	return setmetatable({
		writer = writer or create_temp_file(),
	}, { __index = M })
end

-- remove all pendings functions from the given lines
-- and return an run-function to execute the plenary tests for the created temp file
function M:remove_pendings(lines, pendings)
	local row = 1

	while row <= #lines do
		local fnode = pendings[row]
		if fnode then
			-- skip lines for pending functions
			row = fnode.erow
		else
			self.writer:write(lines[row] .. "\n")
		end
		row = row + 1
	end

	self.writer:close()

	return file_name
end

return M
