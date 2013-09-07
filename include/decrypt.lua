-- Includes
#include 'list.lua'

-- Options
#local USE_LIST = false

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
	--[[for i = 1, #strBytes do
		resultBytes[i] = false
	end]]
	
	local indices = {}
	for i = 1, 256 do
		indices[i] = i
	end
#if(USE_LIST) then
	indices = listCreate(indices)
#end
	
	for i = 1, strLen do
		local keyByte = keyBytes[keyIdx + 1]
		keyIdx = (keyIdx + 1) % keyLen
		
		local holeIdx = (keyByte % holesCnt) + 1
		
#if(USE_LIST) then
		local resultIdx = listRemove(indices, holeIdx)
		listInsert(indices, i + 256)
#else
		local resultIdx = table_remove(indices, holeIdx)
		indices[256] = indices[255] + 1
#end
		
		resultBytes[resultIdx] = strBytes[i]
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
