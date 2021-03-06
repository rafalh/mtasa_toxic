-- Include guard
#if(includeGuard()) then return end

#local bitXor = bit32 and bit32.bxor or require('bit').bxor

#local function encode(str)
#	local outputBytes = {}
#	local inputBytes = {str:byte(1, str:len())}
#	for i, byte in ipairs(inputBytes) do
#		table.insert(outputBytes, bitXor(byte, (outputBytes[i-1] or str:len())))
#	end
#	
#	return string.char(unpack(outputBytes))
#end

#local function binToLuaStr(str)
#	return str:gsub('[^%w]', function(ch)
#		return ('\\%03u'):format(ch:byte())
#	end)
#end

local function KfU1dnqiSU(str) -- decode
	local outputBytes = {}
	local inputBytes = {str:byte(1, str:len())}
	for i, byte in ipairs(inputBytes) do
		table.insert(outputBytes, bitXor(byte, (inputBytes[i-1] or str:len())))
	end
	
	return string.char(unpack(outputBytes))
end

#function OBFUSCATE(str)
#	return 'KfU1dnqiSU(\''..binToLuaStr(encode(str))..'\')'
#end
