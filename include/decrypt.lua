local function decrypt(str, key)
	local strBytes = {str:byte(1, #str)}
	local keyBytes = {key:byte(1, #key)}
	
	-- Fix order
	local keyIdx = 0
	local holesCnt = #strBytes
	local resultBytes = {}
	for i, byte in ipairs(strBytes) do
		local keyByte = keyBytes[keyIdx + 1]
		keyIdx = (keyIdx + 1) % #keyBytes
		
		local holeIdx = keyByte % holesCnt
		local resultIdx = 0
		while(true) do
			if(not resultBytes[resultIdx + 1]) then
				if(holeIdx == 0) then break end
				holeIdx = holeIdx - 1
			end
			resultIdx = resultIdx + 1
		end
		resultBytes[resultIdx + 1] = byte
		holesCnt = holesCnt - 1
	end
	
	--assert(holesCnt == 0)
	
	-- Simple XOR decryption
	local result = ""
	for i, byte in ipairs(resultBytes) do
		local keyByte = keyBytes[(i - 1) % #keyBytes + 1]
		resultBytes[i] = bitXor(byte, keyByte)
	end
	
	return string.char(unpack(resultBytes))
end
