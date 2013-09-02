-- http://www.onicos.com/staff/iz/formats/gif.html
-- http://www.w3.org/Graphics/GIF/spec-gif89a.txt
-- http://www.eecis.udel.edu/~amer/CISC651/lzw.and.gif.explained.html

local string_byte = string.byte
local string_char = string.char
local string_sub = string.sub
local string_len = string.len
local string_rep = string.rep
local math_max = math.max
local math_min = math.min
local math_ceil = math.ceil
local math_floor = math.floor
local math_log = math.log
local table_concat = table.concat
local table_insert = table.insert
local _assert = assert
local _dxSetPixelColor = dxSetPixelColor

local function hasbit ( x, p )
	return x % (p + p) >= p
end

local function GifInitStream ( str )
	return { str, 1 }
end

local function GifGetBytes ( stream, count )
	local ret = string_sub ( stream[1], stream[2], stream[2] + count - 1 )
	stream[2] = stream[2] + count
	return ret
end

local function GifStrToWord ( str )
	return string_byte ( str, 1 ) + ( 2 ^ 8 ) * string_byte ( str, 2 )
end

local function GifWordToStr ( dw )
	return string_char (
		dw % ( 2 ^ 8 ), math_floor ( dw / ( 2 ^ 8 ) ) % ( 2 ^ 8 ) )
end

function GifGetByte ( stream )
	local str = GifGetBytes ( stream, 1 )
	return str and string_byte ( str )
end

function GifGetWord ( stream )
	local str = GifGetBytes ( stream, 2 )
	return str and GifStrToWord ( str )
end

-- i is indexed from 0
function GifGetBits ( stream, i, c )
	--_assert ( c > 0 )
	
	local byte_begin = math_floor ( i / 8 ) + 1
	local byte_end = math_floor ( ( i + c - 1 ) / 8 ) + 1
	
	local ret, j = 0, 0
	for i = byte_begin, byte_end, 1 do
		ret = ret + string_byte ( stream[1], i ) * ( 2 ^ j )
		j = j + 8
	end
	
	ret = math_floor ( ret / ( 2 ^ ( i % 8 ) ) )
	ret = ret % ( 2 ^ c )
	
	return ret
end

local function GifCreateDict ( min_code_size )
	local dict = {}
	for i = 0, 2 ^ min_code_size - 1, 1 do
		dict[i] = string_char ( i )
	end
	
	local cc = 2 ^ min_code_size
	local eoi = 2 ^ min_code_size + 1
	dict[cc] = false
	dict[eoi] = false
	
	return dict, cc, eoi
end

local function GifDecompress ( data, min_code_size )
	local ret_tbl = {}
	local dict, cc, eoi = GifCreateDict ( min_code_size )
	
	local i, bits = 0, string_len ( data ) * 8
	local code_size = min_code_size + 1
	local old_code = false
	
	local stream = GifInitStream ( data )
	_assert ( GifGetBits ( stream, i, code_size ) == cc )
	
	while ( i + code_size <= bits ) do
		local code = GifGetBits ( stream, i, code_size )
		i = i + code_size
		
		if ( code == cc ) then
			dict = GifCreateDict ( min_code_size )
			code_size = min_code_size + 1
			old_code = false
		elseif ( code == eoi ) then
			break
		elseif ( old_code ) then
			local prefix = dict[old_code]
			local trans = dict[code]
			local k
			
			if ( trans ) then
				k = string_sub ( trans, 1, 1 )
				ret_tbl[#ret_tbl + 1] = trans
			else
				k = string_sub ( prefix, 1, 1 )
				ret_tbl[#ret_tbl + 1] = prefix..k
				--assert ( #dict + 1 == code, ( #dict + 1 ).." vs "..code )
			end
			
			dict[#dict + 1] = prefix..k
			if ( #dict == 2^code_size - 1 ) then
				code_size = math_min ( code_size + 1, 12 )
				--DbgPrint ( "code_size %u", code_size )
			end
			
			old_code = code
		else -- first code
			local trans = dict[code]
			--_assert ( trans, "code "..code )
			ret_tbl[#ret_tbl + 1] = trans
			old_code = code
		end
	end
	
	return table_concat ( ret_tbl )
end

local function GifLoadColorTable ( stream, size )
	local tbl = {}
	for i = 0, size - 1, 1 do
		local data = GifGetBytes ( stream, 3 )
		if ( not data or string_len ( data ) ~= 3 ) then
			outputDebugString ( "color with invalid length", 1 )
			return false
		end
		
		tbl[i] = { string_byte ( data, 1, 3 ) }
	end
	
	return tbl
end

local function GifFixColorTable ( tbl, tr_idx )
	if ( not tr_idx ) then
		return tbl
	end
	
	local ret = {}
	for i = 0, #tbl, 1 do
		ret[i] = tbl[i]
	end
	
	ret[tr_idx] = false
	--DbgPrint ( "%u is transparent", tr_idx )
	
	return ret
end

local function GifLoadDataStram ( stream )
	local tbl = {}
	
	while ( true ) do
		local size = GifGetByte ( stream ) or 0
		if ( size == 0 ) then -- terminator
			break
		end
		
		local data = GifGetBytes ( stream, size )
		tbl[#tbl + 1] = data
	end
	
	return table_concat ( tbl )
end

local function GifFixRows ( rows, interflace )
	local new_rows = {}
	local i = 0
	local passes = { { 8, 0 }, { 8, 4 }, { 4, 2 }, { 2, 1 } }
	local h = #rows + 1
	
	for j, pass in ipairs ( passes ) do
		for y = pass[2], h - 1, pass[1] do
			new_rows[y] = rows[i]
			i = i + 1
		end
	end
	
	return new_rows
end

local function GifOnDestroy ()
	local gif = getElementData ( source, "gif" )
	for i, frame in ipairs ( gif.frames ) do
		destroyElement ( frame.tex )
	end
end

function GifLoad ( str, is_string )
	if ( not getElementByID ( "TXC413b9d90" ) ) then return false end
	
	DbgPerfInit ( 1 )
	local stream
	
	if ( not is_string ) then
		DbgPrint ( "Loading "..str )
		local file = fileOpen ( str, true )
		if ( not file ) then
			outputDebugString ( "fileOpen failed: "..str, 1 )
			return false
		end
		
		str = fileRead ( file, fileGetSize ( file ) )
		fileClose ( file )
	end
	
	stream = GifInitStream ( str )
	
	local sig = GifGetBytes ( stream, 3 )
	if ( sig ~= "GIF" ) then
		outputDebugString ( "Wrong signature "..sig, 1 )
		return false
	end
	
	local ver = GifGetBytes ( stream, 3 )
	if ( ver ~= "87a" and ver ~= "89a" ) then
		outputDebugString ( "Unknown version "..ver, 1 )
		return false
	end
	
	local gif = { frames = {}, time = 0 }
	local def_gc = { tr_idx = false, delay = 0, disp = 0 }
	local gc = def_gc
	
	local scr_w = GifGetWord ( stream ) or 0
	local scr_h = GifGetWord ( stream ) or 0
	local flags = GifGetByte ( stream ) or 0
	local bkgnd = GifGetByte ( stream ) or 0
	local aspect = GifGetByte ( stream ) or 0
	
	gif.w, gif.h = scr_w, scr_h
	
	DbgPrint ( "header: w %u h %u f %x, bg %u aspect %u", scr_w, scr_h, flags, bkgnd, aspect )
	
	-- Note: size should be power of 2
	local ln2 = math_log ( 2 )
	local texW = 2 ^ ( math_ceil ( math_log ( scr_w ) / ln2 ) ) -- round up to power of 2
	local texH = 2 ^ ( math_ceil ( math_log ( scr_h ) / ln2 ) ) -- round up to power of 2
	
	-- Note: MTA fails to display properly images with w <> h
	local maxWH = math.max ( texW, texH )
	texW, texH = maxWH, maxWH
	
	DbgPrint ( "texture size: w %u h %u", texW, texH )
	
	local gct = false
	if ( hasbit ( flags, 128 ) ) then -- GCTF
		local gct_size = 2 ^ ( 1 + flags % ( 2 ^ 3 ) ) -- flags & 7
		
		--DbgPrint ( "GCT %u", gct_size )
		gct = GifLoadColorTable ( stream, gct_size )
	end
	
	local emptyTex = dxCreateTexture(texW, texH, "argb")
	local pixels = dxGetTexturePixels(emptyTex)
	--local pixels = string_rep ( "\0\0\0\0", texW * texH )..GifWordToStr ( texW )..GifWordToStr ( texH )
	local frame = false
	local x, y, w, h
	
	while ( true ) do
		DbgPerfInit ( 2 )
		local intr = GifGetByte ( stream ) or 0
		
		if ( intr == 0x2c ) then -- Image Block
			DbgPerfInit ( 3 )
			
			if ( frame and frame.disp >= 2 ) then -- previous frame
				if(x == 0 and y == 0 and w == scr_w and h == scr_h) then
					-- Shortcut ;)
					pixels = dxGetTexturePixels(emptyTex)
				else
					-- clear background
					for x2 = x, w - 1, 1 do
						for y2 = y, h - 1, 1 do
							local ret = _dxSetPixelColor ( pixels, x2, y2, 0, 0, 0, 0 )
							--_assert ( ret )
						end
					end
				end
				
				DbgPerfCp ( "Clearing frame", 3 )
			end
			
			x = GifGetWord ( stream ) or 0
			y = GifGetWord ( stream ) or 0
			w = GifGetWord ( stream ) or 0
			h = GifGetWord ( stream ) or 0
			local flags = GifGetByte ( stream ) or 0
			DbgPrint ( "Image Block #%u: x %u y %u w %u h %u f %x", #gif.frames + 1, x, y, w, h, flags )
			
			local lct = false
			if ( hasbit ( flags, 128 ) ) then -- LCTF
				local lct_size = 2 ^ ( 1 + flags % ( 2 ^ 3 ) ) -- flags & 7
				
				--DbgPrint ( "LCT %u", lct_size )
				lct = GifLoadColorTable ( stream, lct_size )
			end
			
			local min_code_size = GifGetByte ( stream ) or 0
			--DbgPrint ( "min_code_size 0x%X", min_code_size )
			
			local data = GifLoadDataStram ( stream )
			
			DbgPerfCp ( "Reading image data", 3 )
			
			local data_dec = GifDecompress ( data, min_code_size )
			_assert ( #data_dec == w * h )
			
			DbgPerfCp ( "Decompressing data", 3 )
			
			local clr_tbl = GifFixColorTable ( lct or gct, gc.tr_idx )
			local image_rows = {}
			
			for y = 0, h - 1, 1 do
				local row = { string_byte ( data_dec, y * w + 1, y * w + w ) }
				--_assert ( #row == w )
				image_rows[y] = row
			end
			
			if ( hasbit ( flags, 64 ) ) then -- interflace
				DbgPrint ( "interflace 0x%x", flags )
				image_rows = GifFixRows ( image_rows )
			end
			
			DbgPerfCp ( "Processing indicates", 3 )
			
			frame = {} -- new frame
			frame.delay = gc.delay
			frame.disp = gc.disp
			
			for x2 = 0, w - 1, 1 do
				for y2 = 0, h - 1, 1 do
					local idx = image_rows[y2][x2 + 1]
					--_assert ( idx and idx >= 0 and idx <= #clr_tbl ) -- tostring ( idx ).." "..#clr_tbl.." ("..x2.." "..y2..")" )
					
					local clr = clr_tbl[idx]
					
					if ( clr ) then
						local ret = _dxSetPixelColor ( pixels, x + x2, y + y2, clr[1], clr[2], clr[3] )
						--_assert ( ret ) -- "x "..x2.." y "..y2.." w "..scr_w.." h "..scr_h )
					end
				end
			end
			
			frame.tex = dxCreateTexture ( pixels, "argb", false )
			
			DbgPerfCp ( "Creating texture %u", 3, string_len ( pixels or "" ) )
			
			gif.time = gif.time + frame.delay
			gif.frames[#gif.frames + 1] = frame
			
			gc = def_gc -- reset Graphic Control
		elseif ( intr == 0x21 ) then -- Extension Block
			local label = GifGetByte ( stream )
			--DbgPrint ( "Extension Block: label 0x%X", label )
			local data = GifLoadDataStram ( stream )
			
			if ( label == 0xf9 ) then -- Graphic Control Extension Block
				_assert ( string_len ( data ) == 4 )
				
				gc = {}
				local flags = string_byte ( data, 1 )
				gc.tr_idx = hasbit ( flags, 1 ) and string_byte ( data, 4 )
				gc.delay = GifStrToWord ( string_sub ( data, 2, 3 ) ) * 10
				gc.disp = math_floor ( flags / ( 2 ^ 2 ) ) % ( 2 ^ 3 )
				
				if ( gc.delay == 0 ) then
					gc.delay = 100
				end
				
				DbgPrint ( "Graphic Control Extension Block delay %u disp %u", gc.delay, gc.disp )
			end
		elseif ( intr == 0x3b ) then -- trailer
			break
		else -- unknown
			outputDebugString ( "Unknown block "..intr, 2 )
			break
		end
		
		DbgPerfCp ( "Block 0x%X", 2, intr )
	end
	
	destroyElement(emptyTex)
	
	DbgPerfCp ( "GIF loading", 1 )
	
	gif.res = sourceResource
	
	local gif_el = createElement ( "gif" )
	setElementData ( gif_el, "gif", gif, false )
	addEventHandler ( "onElementDestroy", gif_el, GifOnDestroy )
	
	return gif_el
end

function GifRender ( x, y, w, h, gif_el, ... )
	local gif = getElementData ( gif_el, "gif" )
	local ticks = getTickCount ()
	local t = gif.time > 0 and ticks % gif.time or 0
	
	for i, frame in ipairs ( gif.frames ) do
		t = t - frame.delay
		if ( t <= 0 ) then
			dxDrawImageSection ( x, y, w, h, 0, 0, gif.w, gif.h, frame.tex, ... )
			--dxDrawText ( "frame #"..i.." ("..gif.w.." "..gif.h..")", x, y + h + 5, x + w, 0, tocolor ( 255, 255, 255 ), 1, "default", "center" )
			break
		end
	end
end

function GifGetSize ( gif_el )
	local gif = getElementData ( gif_el, "gif" )
	return gif.w, gif.h
end

local function GifOnResStop ( res )
	for i, gif_el in ipairs ( getElementsByType ( "gif" ) ) do
		local gif = getElementData ( gif_el, "gif" )
		if ( gif.res == res ) then
			destroyElement ( gif_el )
			outputDebugString ( "GIF parent resource died", 3 )
		end
	end
end

addEventHandler ( "onClientResourceStop", resourceRoot, GifOnResStop )
