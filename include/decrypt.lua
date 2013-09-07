local string_char = string.char
local table_concat = table.concat
local table_remove = table.remove

#if(isLoaded()) then
 local bitXor = bit32 and bit32.bxor or require('bit').bxor
 
 function decrypt(str, key)
#else
 local function decrypt(str, key)
#end
	local strLen = #str
	local keyLen = #key
	local strBytes = {str:byte(1, strLen)}
	local keyBytes = {key:byte(1, keyLen)}
	
	-- Fix order
	local keyIdx = 0
	local holesCnt = strLen
	local resultBytes = {}
	
	local indices = {}
	for i = 1, 256 do
		indices[i] = i
	end
	
	for i = 1, strLen do
		local keyByte = keyBytes[keyIdx + 1]
		keyIdx = (keyIdx + 1) % keyLen
		
		local holeIdx = keyByte % holesCnt
		local resultIdx = indices[holeIdx + 1] - 1
		table_remove(indices, holeIdx + 1)
		indices[256] = indices[255] + 1
		resultBytes[resultIdx + 1] = strBytes[i]
		holesCnt = holesCnt - 1
	end
	
	--assert(holesCnt == 0)
	
	-- Simple XOR decryption
	for i = 1, strLen do
		local keyByte = keyBytes[(i - 1) % keyLen + 1]
		resultBytes[i] = string_char(bitXor(resultBytes[i], keyByte))
	end
	
	return table_concat(resultBytes)
end
