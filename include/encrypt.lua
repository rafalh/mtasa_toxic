local function encrypt(str, key)
	local strBytes = {str:byte(1, #str)}
	local keyBytes = {key:byte(1, #key)}
	
	-- First simple XOR encryption
	for i, byte in ipairs(strBytes) do
		local keyByte = keyBytes[(i - 1) % #keyBytes + 1]
		strBytes[i] = bitXor(byte, keyByte)
	end
	
	-- Now reorder bytes
	local keyIdx = 0
	local result = ""
	while(#strBytes > 0) do
		local keyByte = keyBytes[keyIdx + 1]
		keyIdx = (keyIdx + 1) % #keyBytes
		
		local strIdx = keyByte % #strBytes
		local strByte = table.remove(strBytes, strIdx + 1)
		result = result..string.char(strByte)
	end
	
	return result
end
