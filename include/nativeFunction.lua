-- Include guard
#if(includeGuard()) then return end

local function isNativeFunction(func)
	local info = debug.getinfo(func, 'S')
	return info.what == 'C'
end

local function areNativeFunctions(tbl)
	for name, func in pairs(tbl) do
		if(not isNativeFunction(func)) then
			return false
		end
	end
	return true
end
