local WIDTH = 400
local BG_COLOR = tocolor(255, 255, 255, 196)
local SHOWING_TICKS = 500
local VISIBLE_TICKS = 10000
local HIDING_TICKS = 500
local POST_GUI = false
local START_Y = g_ScreenSize[2] - 20
local WHITE = tocolor(255, 255, 255)
local HORZ_MARGIN, VERT_MARGIN = 10, 10
local DEFAULT_FONT = {face = 'default', clr = WHITE, scale = 1}
local SPECIAL_FONT = {face = 'default-bold', clr = tocolor(127, 255, 0), scale = 1}

local g_Items = {}
local g_TotalHeight = 0
local g_BgTex = false
local g_TexW, g_TexH

local function NfProcessText(x, y, item, render)
	local curX, curY = x, y
	local maxX = 0
	
	for i, line in ipairs(item) do
		for i, part in ipairs(line) do
			local text, font
			if(type(part) == 'table') then
				font = SPECIAL_FONT
				text = part[1]
			else
				font = DEFAULT_FONT
				text = part
			end
				
			if(render) then
				dxDrawText(text, curX, curY, curX, curY, font.clr, font.scale, font.face, "left", "top", false, false, POST_GUI)
			end
			curX = curX + dxGetTextWidth(text, font.scale, font.face)
		end
		
		maxX = math.max(maxX, curX)
		curX, curY = x, curY + dxGetFontHeight(DEFAULT_FONT.scale, DEFAULT_FONT.face)
	end
	
	return maxX - x, curY - y
end

local function NfParseText(fmt, ...)
	local ret = {}
	local args = {...}
	fmt = MuiGetMsg(fmt)
	local i, argi = 1, 1
	while(true) do
		local b, e = fmt:find('%%%d*%.?%d*l?h?[diuxXfs]', i)
		if(not b) then break end
		
		if(b > i) then
			table.insert(ret, fmt:sub(i, b - 1))
		end
		
		local str = fmt:sub(b, e):format(args[argi])
		argi = argi + 1
		table.insert(ret, {str})
		
		i = e + 1
	end
	
	if(i <= fmt:len()) then
		table.insert(ret, fmt:sub(i))
	end
	
	--outputChatBox(table.concat(ret, "|"))
	return ret
end

function NfAdd(item)
	table.insert(g_Items, 1, item)
	
	for i, line in ipairs(item) do
		item[i] = NfParseText(unpack(line))
	end
	
	if(not item.h or not item.w) then
		local minW, minH = NfProcessText(0, 0, item)
		item.h = math.max(item.h or 0, (item.icon and 42 or 0) + 2*VERT_MARGIN, minH + 2*VERT_MARGIN)
		item.w = math.max(item.w or 0, WIDTH, (item.icon and 42 or 0) + minW + 2*HORZ_MARGIN)
	end
	
	item.ticks = getTickCount()
	g_TotalHeight = g_TotalHeight + item.h
end

local function NfDrawBg(x, y, w, h)
	local srcW = {HORZ_MARGIN, g_TexW - 2*HORZ_MARGIN, HORZ_MARGIN}
	local srcH = {VERT_MARGIN, g_TexH - 2*VERT_MARGIN, VERT_MARGIN}
	local dstW = {HORZ_MARGIN, w - 2*HORZ_MARGIN, HORZ_MARGIN}
	local dstH = {VERT_MARGIN, h - 2*VERT_MARGIN, VERT_MARGIN}
	
	local srcOffsetX, srcOffsetY, dstOffsetX, dstOffsetY = 0, 0, 0, 0
	for idxY = 1, 3 do
		for idxX = 1, 3 do
			dxDrawImageSection(x + dstOffsetX, y + dstOffsetY, dstW[idxX], dstH[idxY], srcOffsetX, srcOffsetY, srcW[idxX], srcH[idxY], g_BgTex, 0, 0, 0, BG_COLOR, POST_GUI)
			srcOffsetX = srcOffsetX + srcW[idxX]
			dstOffsetX = dstOffsetX + dstW[idxX]
		end
		
		srcOffsetX = 0
		dstOffsetX = 0
		srcOffsetY = srcOffsetY + srcH[idxY]
		dstOffsetY = dstOffsetY + dstH[idxY]
	end
end

local function NfRenderItem(item, x, y)
	NfDrawBg(x, y, item.w, item.h)
	x = x + HORZ_MARGIN
	y = y + VERT_MARGIN
	
	if(item.icon) then
		dxDrawImage(x, y + 5, 32, 32, item.icon, 0, 0, 0, WHITE, POST_GUI)
		x = x + 42
	end
	
	NfProcessText(x, y, item, true)
end

local function NfRender()
	local y = START_Y - g_TotalHeight
	local ticks = getTickCount()
	
	local i = 1
	local lastItem = g_Items[#g_Items]
	if(lastItem and ticks - lastItem.ticks > SHOWING_TICKS + VISIBLE_TICKS) then
		if(lastItem.hideTicks) then
			local hidingProgress = math.min((ticks - lastItem.hideTicks) / HIDING_TICKS, 1)
			y = y + getEasingValue(hidingProgress, 'InQuad') * lastItem.h
			if(hidingProgress >= 1) then
				g_TotalHeight = g_TotalHeight - lastItem.h
				table.remove(g_Items)
			end
		else
			lastItem.hideTicks = ticks
		end
	end
	
	for i = 1, #g_Items do
		local item = g_Items[i]
		local dt = ticks - item.ticks
		local itemY = y
		if(dt < SHOWING_TICKS) then
			itemY = START_Y - (START_Y - itemY)*getEasingValue(dt/SHOWING_TICKS, 'InOutQuad')
		end
		
		local x = g_ScreenSize[1]/2 - item.w/2
		NfRenderItem(item, x, itemY)
		y = y + item.h
	end
end

local function NfInit()
	g_BgTex = dxCreateTexture('img/notify.png', 'argb', false)
	if(not g_BgTex) then return end
	
	g_TexW, g_TexH = dxGetMaterialSize(g_BgTex)
	
	addEventHandler('onClientRender', root, NfRender)
end

addEventHandler('onClientResourceStart', resourceRoot, NfInit)

-- TEST
#TEST = false
#if(TEST) then
	addCommandHandler('nftest', function()
		NfAdd{
			icon = 'img/no_img.png',
			{'Hej %s! Co slychac?', 'NOOOOOB'},
			{'Fajne to!', 'NOOOOOB'},
		}
	end, false, false)
#end
