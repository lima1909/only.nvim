local M = {}

M.duration_to_str = function(duration)
	if not duration then
		return "no time avialable"
	end

	local duration_in_sec = duration / 1e9

	if duration_in_sec >= 1 then
		return string.format("%.2f s", duration_in_sec)
	elseif duration_in_sec >= 0.001 then
		return string.format("%.2f ms", duration_in_sec * 1000)
	elseif duration_in_sec >= 0.000001 then
		return string.format("%.2f µs", duration_in_sec * 1e6)
	else
		return string.format("%.2f ns", duration_in_sec * 1e9)
	end
end

return M
