local function genRandomStr(len)
	local ret = ""
	for i = 1, len do
		ret = ret..string.char(math.random(0, 255))
	end
	return ret
end
