-- http://www.onicos.com/staff/iz/formats/gif.html
-- http://www.w3.org/Graphics/GIF/spec-gif89a.txt
-- http://www.eecis.udel.edu/~amer/CISC651/lzw.and.gif.explained.html

#USE_BIT_API = false
#DEBUG_PERF = false

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
local table_remove = table.remove
local _ipairs = ipairs
local _assert = assert

local DEF_GC = {tr_idx = false, delay = 0, disp = 0}
local INTERLACE_PASSES = { {8, 0}, {8, 4}, {4, 2}, {2, 1} }
local g_GifMap = {}
local g_LoaderThread, g_LoaderTimer = false, false

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
	return (string_byte(str, 1) or 0) + 256 * (string_byte(str, 2) or 0)
end

local function GifWordToStr(dw)
# if(USE_BIT_API) then
	return string_char(bitAnd(dw, 0xFF), bitRShift(dw, 8))
# else
	return string_char(
		dw % 256, math_floor(dw / 256) % 256)
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
	--_assert(c <= 12)
	local byteIdx = math_floor(i / 8) + 1
	local b1, b2, b3 = string_byte(stream[1], byteIdx, byteIdx + 2)
	local x = b1 + ((b2 or 0) + ((b3 or 0)*256))*256
# if(USE_BIT_API) then
	return _bitExtract(x, i % 8, c)
# else
	return math_floor(x / (2 ^ (i % 8))) % (2^c)
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

local function GifCopyTable(tbl)
	local ret = {}
	for i = 0, #tbl do
		ret[i] = tbl[i]
	end
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

local function GifOnDestroy()
	local gif = g_GifMap[source]
	for i, frame in _ipairs(gif.frames) do
		destroyElement(frame.tex)
	end
	g_GifMap[source] = nil
end

local function GifLoadInternal(gif, stream)
	DbgPerfInit(1)
	
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
	--local maxWH = math_max(texW, texH)
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
	local imageRows = {}
	local cleanRow = string_rep(bgClr, texW)
	for y = scrH, texH - 1 do
		imageRows[y + 1] = cleanRow
	end
	
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
			
			local clrTbl
			if(not lct and gc.tr_idx) then
				clrTbl = GifCopyTable(gct)
			else
				clrTbl = lct or gct
			end
			
			-- Setup transparent color
			if(gc.tr_idx) then
				clrTbl[gc.tr_idx] = not usePrevFrame and bgClr
			end
			
			-- Load some flags into variables
			local usePrevFrame = (frame and frame.disp <= 1)
			local interlace = _bitTest(flags, 64)
			if(interlace) then
				DbgPrint('interlace 0x%x', flags)
			end
			
			-- Clean top and bottom rows if needed
			if(not usePrevFrame) then
				for y = 0, frameY - 1 do
					imageRows[y + 1] = cleanRow
				end
				for y = frameY + frameH, scrH - 1 do
					imageRows[y + 1] = cleanRow
				end
			end
			
			DbgPerfCp('Misc', 3)
			
			local interlacePass = 1
			local y = interlace and INTERLACE_PASSES[1][2] or 0
			
			for i = 0, frameH - 1 do
				-- Prepare row prefix and postfix
				local oldRow = imageRows[frameY + y + 1] or cleanRow
				local rowPrefix, rowPostfix = '', ''
				if(frameX > 0) then
					rowPrefix = string_sub(oldRow, 1, frameX*4)
				end
				if(frameX + frameW < texW) then
					rowPostfix = string_sub(oldRow, (frameX + frameW)*4 + 1)
				end
				
				-- Change indices into colors
				local rowTbl = {string_byte(dataDec, i * frameW + 1, i * frameW + frameW)}
				for x = 0, frameW - 1 do
					local idx = rowTbl[x + 1]
					--_assert(idx and idx >= 0 and idx <= #clrTbl) -- tostring(idx)..' '..#clrTbl..' ('..x..' '..y..')')
					
					local clr = clrTbl[idx]
					if(not clr) then
						clr = string_sub(oldRow, x*4 + 1, x*4 + 4)
					end
					rowTbl[x + 1] = clr
				end
				
				-- Build row string
				local row = rowPrefix..table_concat(rowTbl)..rowPostfix
				
				--_assert(string_len(row) == texW*4)
				imageRows[frameY + y + 1] = row
				
				-- Move to the next row
				if(interlace) then
					y = y + INTERLACE_PASSES[interlacePass][1]
					if(y > frameH) then -- if y == frameH, its end of this image
						interlacePass = interlacePass + 1
						y = INTERLACE_PASSES[interlacePass][2]
					end
				else
					y = y + 1
				end
			end
			
			_assert(#imageRows == texH)
			
			DbgPerfCp('Building raw string', 3)
			
			frame = {} -- new frame
			frame.delay = gc.delay
			frame.disp = gc.disp
			
			table_insert(imageRows, GifWordToStr(texW)..GifWordToStr(texH))
			local pixels = table_concat(imageRows)
			table_remove(imageRows)
			
			_assert(string_len(pixels) == texW*texH*4 + 4)
			frame.tex = dxCreateTexture(pixels, 'argb', false)
			if(not frame.tex) then return false end
			
			DbgPerfCp('Creating texture %u', 3, string_len(pixels or ''))
			
			gif.time = gif.time + frame.delay
			gif.frames[#gif.frames + 1] = frame
			
			gc = DEF_GC -- reset Graphic Control
# if(not DEBUG_PERF) then
			coroutine.yield()
# end
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
				
				DbgPrint('Graphic Control Extension Block tr_idx %d delay %u disp %u', gc.tr_idx or -1, gc.delay, gc.disp)
			end
		elseif(intr == 0x3b) then -- trailer
			break
		else -- unknown
			outputDebugString('Unknown block '..intr, 2)
			break
		end
		
		DbgPerfCp('Block 0x%X', 2, intr)
	end
	
	gif.loaded = true
	gif.stream = false
	DbgPerfCp('GIF loading', 1)
end

local function GifLoaderProc()
	while(true) do
		for el, gif in pairs(g_GifMap) do
			if(not gif.loaded) then
				GifLoadInternal(gif, gif.stream)
			end
		end
		coroutine.yield(true)
	end
end

local function GifWakeUpLoader(isTimer)
	-- If timer exists, let him do the job
	if(not isTimer and g_LoaderTimer) then return end
	g_LoaderTimer = false
	
	local startTicks = getTickCount()
	while(true) do
		local status, err
		if(g_LoaderThread) then
			-- Resume GIF loading
			status, err = coroutine.resume(g_LoaderThread)
		else
			-- Found new GIF to load
			for el, gif in pairs(g_GifMap) do
				if(not gif.loaded) then
					g_LoaderThread = coroutine.create(GifLoadInternal)
					status, err = coroutine.resume(g_LoaderThread, gif, gif.stream)
					break
				end
			end
			
			if(not g_LoaderThread) then
				return -- All images are loaded
			end
		end
		
		_assert(g_LoaderThread)
		if(coroutine.status(g_LoaderThread) == 'dead') then
			-- GIF has been loaded
			if(not status) then
				outputDebugString('Failed to load GIF: '..err, 2)
			end
			g_LoaderThread = false
		end
		
		-- Check if we should pause for a moment
		local dt = getTickCount() - startTicks
		if(dt > 20) then
			g_LoaderTimer = setTimer(GifWakeUpLoader, 50, 1, true)
			return
		end
	end
end

function GifLoad(str, isString)
	if(not getElementByID('TXC413b9d90')) then return false end
	
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
	gif.res = sourceResource
	gif.loaded = false
	gif.stream = stream
	
	local gifEl = createElement('gif')
	g_GifMap[gifEl] = gif
	addEventHandler('onElementDestroy', gifEl, GifOnDestroy)
	
	GifWakeUpLoader()
	
	return gifEl
end

function GifRender(x, y, w, h, gifEl, ...)
	DbgPerfInit(1)
	local gif = g_GifMap[gifEl]
	if(not gif.loaded) then return end
	
	local ticks = getTickCount()
	local t = gif.time > 0 and ticks % gif.time or 0
	
	for i, frame in _ipairs(gif.frames) do
		t = t - frame.delay
		if(t <= 0) then
			if(frame.tex) then
				dxDrawImageSection(x, y, w, h, 0, 0, gif.w, gif.h, frame.tex, ...)
			end
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
	for i, gifEl in _ipairs(getElementsByType('gif')) do
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
