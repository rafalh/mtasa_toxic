local TEXT_COLOR = {255, 255, 255}
local BG_COLOR = {64, 64, 64}
local BORDER_COLOR = {196, 196, 196}
local ALPHA = 196
local BORDER_W = 1
local HPADDING, VPADDING = 3, 1
local SCALE = 1
local FONT = 'default'
local ANIM_TIME = 200
local WAIT_TIME = 500
local OFFSET_Y = 12

local g_Tooltips = {}
local g_TooltipsCount = 0
local g_FontH = dxGetFontHeight(SCALE, FONT)
local g_ScrW, g_ScrH = guiGetScreenSize()

local function TtDraw(tooltip)
	local alpha
	local dt = getTickCount() - tooltip.ticks
	local progress = math.min(dt/ANIM_TIME, 1)
	if(tooltip.state == 'hidding') then
		alpha = (1-progress)*tooltip.alpha
	else
		alpha = progress*ALPHA + (1-progress)*tooltip.alpha
	end
	
	-- Border
	local borderClr = tocolor(BORDER_COLOR[1], BORDER_COLOR[2], BORDER_COLOR[3], alpha)
	local left, top, right, bottom = tooltip.x, tooltip.y, tooltip.x + tooltip.textW + 2*HPADDING + BORDER_W, tooltip.y + g_FontH + 2*VPADDING + BORDER_W
	dxDrawLine(left, top, right, top, borderClr, BORDER_W, true)
	dxDrawLine(right, top, right, bottom, borderClr, BORDER_W, true)
	dxDrawLine(right, bottom, left, bottom, borderClr, BORDER_W, true)
	dxDrawLine(left, bottom, left, top, borderClr, BORDER_W, true)
	
	-- Background
	local bgClr = tocolor(BG_COLOR[1], BG_COLOR[2], BG_COLOR[3], alpha)
	dxDrawRectangle(tooltip.x + BORDER_W, tooltip.y + BORDER_W, tooltip.textW + 2*HPADDING, g_FontH + 2*VPADDING, bgClr, true)
	
	-- Text
	local textClr = tocolor(TEXT_COLOR[1], TEXT_COLOR[2], TEXT_COLOR[3], alpha)
	local textLeft, textRight = tooltip.x + BORDER_W + HPADDING, tooltip.x + BORDER_W + tooltip.textW + 2*HPADDING
	local textTop, textBottom = tooltip.y + BORDER_W + VPADDING, tooltip.y + BORDER_W + g_FontH + 2*VPADDING
	dxDrawText(tooltip.text, textLeft, textTop, textRight, textBottom, textClr, SCALE, FONT, 'left', 'top', false, true, true)
end

local function TtRenderAll()
	local ticks = getTickCount()
	for el, tooltip in pairs(g_Tooltips) do
		local dt = ticks - tooltip.ticks
		local visible = isElement(el) and guiGetVisible(el)
		local curX, curY = getCursorPosition() -- Note: isCursorShowing doesn't work
		if((tooltip.state == 'hidding' and dt > ANIM_TIME) or not visible or not curX) then
			g_Tooltips[el] = nil
			g_TooltipsCount = g_TooltipsCount - 1
			if(g_TooltipsCount == 0) then
				removeEventHandler('onClientRender', root, TtRenderAll)
			end
		elseif(tooltip.state ~= 'waiting') then
			TtDraw(tooltip)
		elseif(dt > WAIT_TIME) then
			tooltip.state = 'showing'
			tooltip.x, tooltip.y = curX*g_ScrW, curY*g_ScrH + OFFSET_Y
			tooltip.ticks = ticks
		end
	end
end

local function TtShow()
	local text = getElementData(source, 'tooltip')
	if not text or not getElementType(source):find('gui-', 1, true) then return end
	
	if(not g_Tooltips[source]) then
		g_Tooltips[source] = {}
		g_TooltipsCount = g_TooltipsCount + 1
		if(g_TooltipsCount == 1) then
			addEventHandler('onClientRender', root, TtRenderAll)
		end
	end
	local tooltip = g_Tooltips[source]
	tooltip.text = text
	tooltip.textW = dxGetTextWidth(text, SCALE, FONT)
	tooltip.state = 'waiting'
	tooltip.alpha = 0
	tooltip.ticks = getTickCount()
end

local function TtHide(el)
	if(not isElement(el)) then el = source end
	local tooltip = g_Tooltips[el]
	if(tooltip) then
		if(tooltip.state == 'waiting') then
			g_Tooltips[el] = nil
			g_TooltipsCount = g_TooltipsCount - 1
			if(g_TooltipsCount == 0) then
				removeEventHandler('onClientRender', root, TtRenderAll)
			end
		else
			local dt = getTickCount() - tooltip.ticks
			local progress = math.min(dt/ANIM_TIME, 1)
			tooltip.alpha = progress*ALPHA + (1-progress)*tooltip.alpha
			tooltip.state = 'hidding'
			tooltip.ticks = getTickCount()
		end
	end
end

addInitFunc(function()
	addEventHandler('onClientMouseEnter', root, TtShow)
	addEventHandler('onClientMouseLeave', root, TtHide)
	addEventHandler('onClientGUIClick', root, TtHide)
end)
