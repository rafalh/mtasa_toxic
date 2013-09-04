-- http://www.onicos.com/staff/iz/formats/gif.html
-- http://www.w3.org/Graphics/GIF/spec-gif89a.txt
-- http://www.eecis.udel.edu/~amer/CISC651/lzw.and.gif.explained.html

#USE_BIT_API = true

local string_byte = string.byte
local string_char = string.char
local string_sub = string.sub
local string_len = string.len
local string_rep = string.rep
local string_reverse = string.reverse
local math_max = math.max
local math_min = math.min
local math_ceil = math.ceil
local math_floor = math.floor
local math_log = math.log
local math_huge = math.huge
local table_concat = table.concat
local table_insert = table.insert
local _assert = assert
local _dxSetPixelColor = dxSetPixelColor

local DEF_GC = {tr_idx = false, delay = 0, disp = 0}
local g_GifMap = {}

#if(USE_BIT_API) then
	local _bitTest = bitTest
	local _bitExtract = bitExtract
#else
	local function _bitTest(x, p)
		return x % (p + p) >= p
	end
#end

local function GifInitStream(str)
	return {str, 1}
end

local function GifGetBytes(stream, count)
	local ret = string_sub(stream[1], stream[2], stream[2] + count - 1)
	stream[2] = stream[2] + count
	return ret
end

local function GifStrToWord(str)
	return string_byte(str, 1) + (2 ^ 8) * string_byte(str, 2)
end

local function GifWordToStr(dw)
# if(USE_BIT_API) then
	return string_char(bitAnd(dw, 0xFF), bitRShift(dw, 8))
# else
	return string_char(
		dw % (2 ^ 8), math_floor(dw / (2 ^ 8)) % (2 ^ 8))
# end
end

function GifGetByte(stream)
	local str = GifGetBytes(stream, 1)
	return str and string_byte(str)
end

function GifGetWord(stream)
	local str = GifGetBytes(stream, 2)
	return str and GifStrToWord(str)
end

-- i is indexed from 0
function GifGetBits(stream, i, c)
	--_assert(c > 0)
# if(USE_BIT_API) then
	--_assert(c <= 12)
	local byteBegin = math_floor(i / 8) + 1
	local b1, b2, b3 = string_byte(stream[1], byteBegin, byteBegin + 2)
	local x = b1 + ((b2 or 0) + ((b3 or 0)*256))*256
	return _bitExtract(x, i % 8, c)
# else
	local byteBegin = math_floor(i / 8) + 1
	local byteEnd = math_floor((i + c - 1) / 8) + 1
	
	local ret, j = 0, 0
	for i = byteBegin, byteEnd, 1 do
		ret = ret + string_byte(stream[1], i) * (2 ^ j)
		j = j + 8
	end
	
	ret = math_floor(ret / (2 ^ (i % 8)))
	ret = ret % (2 ^ c)
	
	return ret
# end
end

local function GifCreateDict(minCodeSize)
	local dict = {}
	for i = 0, 2 ^ minCodeSize - 1, 1 do
		dict[i] = string_char(i)
	end
	
	local cc = 2 ^ minCodeSize
	local eoi = 2 ^ minCodeSize + 1
	dict[cc] = false
	dict[eoi] = false
	
	return dict, cc, eoi
end

local function GifDecompress(data, minCodeSize)
	local ret_tbl = {}
	local dict, cc, eoi = GifCreateDict(minCodeSize)
	
	local i, bits = 0, string_len(data) * 8
	local codeSize = minCodeSize + 1
	local oldCode = false
	
	local stream = GifInitStream(data)
	_assert(GifGetBits(stream, i, codeSize) == cc)
	
	while(i + codeSize <= bits) do
		local code = GifGetBits(stream, i, codeSize)
		i = i + codeSize
		
		if(code == cc) then
			dict = GifCreateDict(minCodeSize)
			codeSize = minCodeSize + 1
			oldCode = false
		elseif(code == eoi) then
			break
		elseif(oldCode) then
			local prefix = dict[oldCode]
			local trans = dict[code]
			local k
			
			if(trans) then
				k = string_sub(trans, 1, 1)
				ret_tbl[#ret_tbl + 1] = trans
			else
				k = string_sub(prefix, 1, 1)
				ret_tbl[#ret_tbl + 1] = prefix..k
				--assert(#dict + 1 == code, (#dict + 1)..' vs '..code)
			end
			
			dict[#dict + 1] = prefix..k
			if(#dict == 2^codeSize - 1) then
				codeSize = math_min(codeSize + 1, 12)
				--DbgPrint('codeSize %u', codeSize)
			end
			
			oldCode = code
		else -- first code
			local trans = dict[code]
			--_assert(trans, 'code '..code)
			ret_tbl[#ret_tbl + 1] = trans
			oldCode = code
		end
	end
	
	return table_concat(ret_tbl)
end

local function GifLoadColorTable(stream, size)
	local tbl = {}
	for i = 0, size - 1, 1 do
		local data = GifGetBytes(stream, 3)
		if(not data or string_len(data) ~= 3) then
			outputDebugString('color with invalid length', 1)
			return false
		end
		
		tbl[i] = string_reverse(data)..'\255'
	end
	
	return tbl
end

local function GifFixColorTable(tbl, trIdx)
	if(not trIdx) then
		return tbl
	end
	
	local ret = {}
	for i = 0, #tbl do
		ret[i] = tbl[i]
	end
	
	ret[trIdx] = false
	--DbgPrint('%u is transparent', trIdx)
	
	return ret
end

local function GifLoadDataStram(stream)
	local tbl = {}
	
	while(true) do
		local size = GifGetByte(stream) or 0
		if(size == 0) then -- terminator
			break
		end
		
		local data = GifGetBytes(stream, size)
		tbl[#tbl + 1] = data
	end
	
	return table_concat(tbl)
end

local function GifFixRows(rows, interflace)
	local newRows = {}
	local i = 1
	local passes = { {8, 0}, {8, 4}, {4, 2}, {2, 1} }
	local h = #rows
	
	for j, pass in ipairs(passes) do
		for y = pass[2], h - 1, pass[1] do
			newRows[y + 1] = rows[i]
			i = i + 1
		end
	end
	
	return newRows
end

local function GifOnDestroy()
	local gif = g_GifMap[source]
	for i, frame in ipairs(gif.frames) do
		destroyElement(frame.tex)
	end
	g_GifMap[source] = nil
end

function GifLoad(str, isString)
	if(not getElementByID('TXC413b9d90')) then return false end
	
	DbgPerfInit(1)
	
	if(not isString) then
		DbgPrint('Loading '..str)
		local file = fileOpen(str, true)
		if(not file) then
			outputDebugString('fileOpen failed: '..str, 1)
			return false
		end
		
		str = fileRead(file, fileGetSize(file))
		fileClose(file)
	end
	
	local stream = GifInitStream(str)
	
	local sig = GifGetBytes(stream, 3)
	if(sig ~= 'GIF') then
		outputDebugString('Wrong signature '..sig, 1)
		return false
	end
	
	local ver = GifGetBytes(stream, 3)
	if(ver ~= '87a' and ver ~= '89a') then
		outputDebugString('Unknown version '..ver, 1)
		return false
	end
	
	local gif = {frames = {}, time = 0}
	local gc = DEF_GC
	
	local scrW = GifGetWord(stream) or 0
	local scrH = GifGetWord(stream) or 0
	local flags = GifGetByte(stream) or 0
	local bgClrIdx = GifGetByte(stream) or 0
	local aspectRatio = GifGetByte(stream) or 0
	
	gif.w, gif.h = scrW, scrH
	
	DbgPrint('header: w %u h %u f %x, bg %u aspect %u', scrW, scrH, flags, bgClrIdx, aspectRatio)
	
	-- Note: size should be power of 2 (dxCreateTexture works with such images)
	local ln2 = math_log(2)
	local texW = 2 ^ (math_ceil(math_log(scrW) / ln2)) -- round up to power of 2
	local texH = 2 ^ (math_ceil(math_log(scrH) / ln2)) -- round up to power of 2
	
	-- Note: MTA fails to display properly images with w <> h
	--local maxWH = math.max(texW, texH)
	--texW, texH = maxWH, maxWH
	
	DbgPrint('texture size: w %u h %u', texW, texH)
	
	local gct = false
	if(_bitTest(flags, 128)) then -- GCTF
		local gctSize = 2 ^ (1 + flags % (2 ^ 3)) -- flags & 7
		
		--DbgPrint('GCT %u', gctSize)
		gct = GifLoadColorTable(stream, gctSize)
	end
	
	local bgClr = '\0\0\0\0' -- gct and gct[bgClrIdx] or '\0\0\0\0'
	
	local frame = false
	local oldImgRows = false
	local cleanRow = string_rep(bgClr, texW)
	
	while(true) do
		DbgPerfInit(2)
		local intr = GifGetByte(stream) or 0
		
		if(intr == 0x2c) then -- Image Block
			DbgPerfInit(3)
			
			local frameX = GifGetWord(stream) or 0
			local frameY = GifGetWord(stream) or 0
			local frameW = GifGetWord(stream) or 0
			local frameH = GifGetWord(stream) or 0
			local flags = GifGetByte(stream) or 0
			DbgPrint('Image Block #%u: x %u y %u w %u h %u f %x', #gif.frames + 1, frameX, frameY, frameW, frameH, flags)
			
			local lct = false
			if(_bitTest(flags, 128)) then -- LCTF
				local lctSize = 2 ^ (1 + flags % (2 ^ 3)) -- flags & 7
				
				--DbgPrint('LCT %u', lctSize)
				lct = GifLoadColorTable(stream, lctSize)
			end
			
			local minCodeSize = GifGetByte(stream) or 0
			--DbgPrint('minCodeSize 0x%X', minCodeSize)
			
			local data = GifLoadDataStram(stream)
			
			DbgPerfCp('Reading image data', 3)
			
			local dataDec = GifDecompress(data, minCodeSize)
			_assert(#dataDec == frameW * frameH)
			
			DbgPerfCp('Decompressing data', 3)
			
			local clrTbl = GifFixColorTable(lct or gct, gc.tr_idx)
			local imageRows = {}
			local usePrevFrame = (frame and frame.disp <= 1)
			
			for y = 0, texH - 1 do
				local oldRow = oldImgRows and oldImgRows[y + 1] or cleanRow
				local row
				if(y >= frameY and y < frameY + frameH) then
					row = ''
					if(frameX > 0) then
						row = string_sub(oldRow, 1, frameX)
					end
					
					local rowTbl = {string_byte(dataDec, (y - frameY) * frameW + 1, (y - frameY) * frameW + frameW)}
					for x = 0, frameW - 1 do
						local idx = rowTbl[x + 1]
						--_assert(idx and idx >= 0 and idx <= #clrTbl) -- tostring(idx)..' '..#clrTbl..' ('..x..' '..y..')')
						
						local clr = clrTbl[idx]
						if(not clr) then
							if(usePrevFrame) then
								clr = string_sub(oldRow, x*4 + 1, x*4 + 4)
							else
								clr = bgClr
							end
						end
						rowTbl[x + 1] = clr
					end
					row = row..table.concat(rowTbl)
					
					if(frameX + frameW < texW) then
						row = row..string_sub(oldRow, (frameX + frameW)*4 + 1)
					end
				else
					row = oldRow
				end
				
				--_assert(string_len(row) == texW*4)
				imageRows[y + 1] = row
			end
			_assert(#imageRows == texH)
			
			if(_bitTest(flags, 64)) then -- interflace
				DbgPrint('interflace 0x%x', flags)
				imageRows = GifFixRows(imageRows)
			end
			
			DbgPerfCp('Processing indicates', 3)
			
			frame = {} -- new frame
			frame.delay = gc.delay
			frame.disp = gc.disp
			
			table.insert(imageRows, GifWordToStr(texW)..GifWordToStr(texH))
			local pixels = table.concat(imageRows)
			oldImgRows = imageRows
			
			_assert(string_len(pixels) == texW*texH*4 + 4)
			frame.tex = dxCreateTexture(pixels, 'argb', false)
			if(not frame.tex) then return false end
			
			DbgPerfCp('Creating texture %u', 3, string_len(pixels or ''))
			
			gif.time = gif.time + frame.delay
			gif.frames[#gif.frames + 1] = frame
			
			gc = DEF_GC -- reset Graphic Control
		elseif(intr == 0x21) then -- Extension Block
			local label = GifGetByte(stream)
			--DbgPrint('Extension Block: label 0x%X', label)
			local data = GifLoadDataStram(stream)
			
			if(label == 0xf9) then -- Graphic Control Extension Block
				_assert(string_len(data) == 4)
				
				gc = {}
				local flags = string_byte(data, 1)
				gc.tr_idx = _bitTest(flags, 1) and string_byte(data, 4)
				gc.delay = GifStrToWord(string_sub(data, 2, 3)) * 10
#if(USE_BIT_API) then
				gc.disp = _bitExtract(flags, 2, 3)
#else
				gc.disp = math_floor(flags / (2 ^ 2)) % (2 ^ 3)
#end
				
				if(gc.delay == 0) then
					gc.delay = 100
				end
				
				DbgPrint('Graphic Control Extension Block delay %u disp %u', gc.delay, gc.disp)
			end
		elseif(intr == 0x3b) then -- trailer
			break
		else -- unknown
			outputDebugString('Unknown block '..intr, 2)
			break
		end
		
		DbgPerfCp('Block 0x%X', 2, intr)
	end
	
	DbgPerfCp('GIF loading', 1)
	
	gif.res = sourceResource
	
	local gifEl = createElement('gif')
	g_GifMap[gifEl] = gif
	addEventHandler('onElementDestroy', gifEl, GifOnDestroy)
	
	return gifEl
end

function GifRender(x, y, w, h, gifEl, ...)
	DbgPerfInit(1)
	local gif = g_GifMap[gifEl]
	local ticks = getTickCount()
	local t = gif.time > 0 and ticks % gif.time or 0
	
	for i, frame in ipairs(gif.frames) do
		t = t - frame.delay
		if(t <= 0) then
			dxDrawImageSection(x, y, w, h, 0, 0, gif.w, gif.h, frame.tex, ...)
			--dxDrawImage(x, y, w, h, frame.tex, ...)
			--dxDrawText('frame #'..i..' ('..gif.w..' '..gif.h..')', x, y + h + 5, x + w, 0, tocolor(255, 255, 255), 1, 'default', 'center')
			break
		end
	end
	DbgPerfCp('GifRender', 1)
end

function GifGetSize(gifEl)
	local gif = g_GifMap[gifEl]
	return gif.w, gif.h
end

local function GifOnResStop(res)
	DbgPerfInit(1)
	for i, gifEl in ipairs(getElementsByType('gif')) do
		local gif = g_GifMap[gifEl]
		if(gif.res == res) then
			destroyElement(gifEl)
			g_GifMap[gifEl] = nil
			outputDebugString('GIF parent resource died', 3)
		end
	end
	DbgPerfCp('GifOnResStop', 1)
end

addEventHandler('onClientResourceStop', resourceRoot, GifOnResStop)
