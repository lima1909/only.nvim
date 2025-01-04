local function create_temp_file()
	local tmp_file_name = vim.fn.tempname()
	local file = io.open(tmp_file_name, "w")
	if not file then
		error("Failed to create temp file: " .. tmp_file_name)
	end

	return file, tmp_file_name
end

local M = {}

M.new = function(writer)
	local file_name = "no-file-name"

	if not writer then
		writer, file_name = create_temp_file()
	end

	return setmetatable({
		writer = writer,
		file_name = file_name,
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
			self.writer:write(lines[row])
		end
		row = row + 1
	end

	self.writer:close()

	return self.file_name, function()
		pcall(vim.fn.delete, self.file_name)
	end
end

return M
