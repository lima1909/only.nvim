---@diagnostic disable: need-check-nil

local assert = require("luassert")
local h = require("only.harness")
local p = require("only.parser")

local function writer()
	local w = {
		lines = {},
		write = function(s, line)
			table.insert(s.lines, vim.trim(line))
		end,
		close = function(_) end,
	}
	return setmetatable({}, { __index = w })
end

local function prepare_tests(lines, tags, w)
	local bufnr = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

	tags = vim.split(tags, ",")
	local pendings = p.to_pending_with_tags(bufnr, tags)
	return h.new(w):remove_pendings(lines, pendings)
end

local function file_content(file)
	-- reopen the file, to get the content
	local f = io.open(file, "r")
	local content = f:read("*a")
	f:close()

	return content
end

describe("harness with temp file:", function()
	it("only i11", function()
		local file, clear = prepare_tests({
			'describe("d1", function()',
			'	it("i11 #only", function()',
			"	  -- do the tests",
			"	end)",
			'	it("i21", function()',
			"	  -- do the tests",
			"	end)",
			"end)",
		}, "#only")

		assert.are.same(
			'describe("d1", function()	it("i11 #only", function()	  -- do the tests	end)end)',
			file_content(file)
		)

		clear()
	end)

	it("only i21", function()
		local file, clear = prepare_tests({
			'describe("d1", function()',
			'	it("i11", function()',
			"	  -- do the tests",
			"	end)",
			'	it("i21 #only", function()',
			"	  -- do the tests",
			"	end)",
			"end)",
		}, "#only")

		assert.are.same(
			'describe("d1", function()	it("i21 #only", function()	  -- do the tests	end)end)',
			file_content(file)
		)

		clear()
	end)
end)

describe("harness with own writer:", function()
	it("", function()
		local w = writer()
		prepare_tests({
			'describe("d1", function()',
			'	it("i11 #first", function()',
			"	  -- do the tests",
			"	end)",
			'	it("i21 #second", function() end)',
			"end)",
		}, "#first,#second", w)

		assert.are.same({
			'describe("d1", function()',
			'it("i11 #first", function()',
			"-- do the tests",
			"end)",
			'it("i21 #second", function() end)',
			"end)",
		}, w.lines)
	end)
end)
