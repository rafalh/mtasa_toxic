-- Defined
#local USE_LIST = false
#local USE_TABLE_REMOVE = false

-- Includes
#if(USE_LIST) then
# include 'list.lua'
#end

local string_char = string.char
local table_insert = table.insert
local table_remove = table.remove

#if(isLoaded()) then
 local bitXor = bit32 and bit32.bxor or require('bit').bxor
 
 function encrypt(str, key)
#else
 local function encrypt(str, key)
#end
	local strLen, keyLen = #str, #key
	local strBytes = {str:byte(1, strLen)}
	local keyBytes = {key:byte(1, keyLen)}
	
	-- First simple XOR encryption
	for i = 1, strLen do
		local keyByte = keyBytes[(i - 1) % keyLen + 1]
		strBytes[i] = bitXor(strBytes[i], keyByte)
	end
	
 #if(USE_LIST) then
	local strBytesList = listCreate(strBytes)
 #end
	
#if(not USE_TABLE_REMOVE and not USE_LIST) then
	local indices = {}
	for i = 1, 256 do
		indices[i] = i
	end
#end
	
	-- Now reorder bytes
	local keyIdx = 0
	local resultTbl = {}
	while(strLen > 0) do
		local keyByte = keyBytes[keyIdx + 1]
		keyIdx = (keyIdx + 1) % keyLen
		
		--local strIdx = strLen - 1
		local strIdx = keyByte % strLen
		--local strIdx = 0
#if(USE_LIST) then
		local strByte = listRemove(strBytesList, strIdx + 1)
#elseif(USE_TABLE_REMOVE) then
		local strByte = table_remove(strBytes, strIdx + 1)
#else
		local strByte = strBytes[indices[strIdx + 1]]
		table_remove(indices, strIdx + 1)
		indices[256] = indices[255] + 1
#end
		strLen = strLen - 1
		table_insert(resultTbl, string_char(strByte))
	end
	
	return table.concat(resultTbl)
end
