function RcEncodeTrace(rec)
	local longFmtCnt = 0
	local buf = ''
	for i, data in ipairs(rec) do
		local dticks, model = tonumber(data[1]), tonumber(data[8])
		local dx, dy, dz = tonumber(data[2]), tonumber(data[3]), tonumber(data[4])
		local drx, dry, drz = tonumber(data[5]), tonumber(data[6]), tonumber(data[7])
		
		if(not dticks or not dx or not dy or not dz or not drx or not dry or not drz) then
			outputDebugString('Invalid rec', 2)
			return false
		end
		
		if(drx > 180)      then drx = drx - 360
		elseif(drx < -180) then drx = drx + 360 end
		if(dry > 180)      then dry = dry - 360
		elseif(dry < -180) then dry = dry + 360 end
		if(drz > 180)      then drz = drz - 360
		elseif(drz < -180) then drz = drz + 360 end
		
		local longFmt = model or dticks > 65000 or
			math.abs(dx) > 32000 or math.abs(dy) > 32000 or math.abs(dz) > 32000 or
			math.abs(drx) > 127 or math.abs(dry) > 127 or math.abs(drz) > 127
		
		if(longFmt) then
			longFmtCnt = longFmtCnt + 1
			buf = buf..'\1'..uintToBin(dticks, 4)..
				intToBin(dx, 4)..intToBin(dy, 4)..intToBin(dz, 4)..
				intToBin(drx, 2)..intToBin(dry, 2)..intToBin(drz, 2)..uintToBin(model or 0, 2)
		else
			buf = buf..'\0'..uintToBin(dticks, 2)..
				intToBin(dx, 2)..intToBin(dy, 2)..intToBin(dz, 2)..
				intToBin(drx, 1)..intToBin(dry, 1)..intToBin(drz, 1)
		end
	end
	
	if(longFmtCnt*10 > #rec) then
		outputDebugString('Too bad '..longFmtCnt..'/'..#rec, 2)
	end
	
	return buf
end

function RcDecodeTrace(buf)
	local rec = {}
	local i = 1
	while(i <= buf:len()) do
		local flags = buf:byte(i)
		assert(flags <= 1)
		local data = {}
		if(flags == 1) then -- long format
			assert(i + 24 <= buf:len())
			data[1] = binToUint(buf:sub(i + 1, i + 4)) -- dticks
			data[2] = binToInt(buf:sub(i + 5, i + 8)) -- dx
			data[3] = binToInt(buf:sub(i + 9, i + 12)) -- dy
			data[4] = binToInt(buf:sub(i + 13, i + 16)) -- dz
			data[5] = binToInt(buf:sub(i + 17, i + 18)) -- drx
			data[6] = binToInt(buf:sub(i + 19, i + 20)) -- dry
			data[7] = binToInt(buf:sub(i + 21, i + 22)) -- drz
			data[8] = binToUint(buf:sub(i + 23, i + 24)) -- model
			if(data[8] == 0) then data[8] = false end
			i = i + 25
		else
			assert(i + 11 <= buf:len())
			data[1] = binToUint(buf:sub(i + 1, i + 2)) -- dticks
			data[2] = binToInt(buf:sub(i + 3, i + 4)) -- dx
			data[3] = binToInt(buf:sub(i + 5, i + 6)) -- dy
			data[4] = binToInt(buf:sub(i + 7, i + 8)) -- dz
			data[5] = binToInt(buf:sub(i + 9, i + 9)) -- drx
			data[6] = binToInt(buf:sub(i + 10, i + 10)) -- dry
			data[7] = binToInt(buf:sub(i + 11, i + 11)) -- drz
			i = i + 12
		end
		
		table.insert(rec, data)
	end
	
	return rec
end
