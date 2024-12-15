--[[

(
   function_call
    name: (identifier) @fname
    (#any-of? @fname "describe" "it")
  

    arguments: (arguments 
  	(
	 string 
	 content: (string_content) @name)
	 (#not-match? @name ".*only.*")
	) 
) @funcs

--]]

local M = {}

return M
