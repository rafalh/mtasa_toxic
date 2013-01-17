--------------
-- Includes --
--------------

#include "../../include/serv_verification.lua"
#include "../../include/widgets.lua"

---------------------
-- Local variables --
---------------------

local TEXT_COLOR = tocolor(0, 255, 0)
local BG_COLOR = tocolor(0, 0, 0, 64)
local USE_RENDER_TARGET = true

local g_Root = getRootElement ()
local g_Me = getLocalPlayer ()
local g_ScreenSize = { guiGetScreenSize () }
local g_ScreenSizeSqrt = { g_ScreenSize[1]^(1/2), g_ScreenSize[2]^(1/2) }
local g_Show, g_Size, g_Pos = false -- set in WG_RESET
local g_WidgetCtrl = {}
local g_WidgetName = {"Digital clock", pl = "Cyfrowy zegar"}
local g_Buffer = false
local g_UpdateTimer = false

local g_Digits = {
	[0] = { true,  true,  true,  false, true,  true,  true  },
	[1] = { false, false, false, false, false, true,  true  },
	[2] = { false, true,  true,  true,  true,  true,  false },
	[3] = { false, false, true,  true,  true,  true,  true  },
	[4] = { true,  false, false, true,  false, true,  true  },
	[5] = { true,  false, true,  true,  true,  false, true  },
	[6] = { true,  true,  true,  true,  true,  false, true  },
	[7] = { false, false, true,  false, false, true,  true  },
	[8] = { true,  true,  true,  true,  true,  true,  true  },
	[9] = { true,  false, true,  true,  true,  true,  true  }
}

--------------------------------
-- Local function definitions --
--------------------------------

local function drawDigit(n, x, y, w, h, clr)
	local digit = g_Digits[n]
	assert(digit, tostring(n))
	local line_w = math.floor((w + h)/20)
	
	if(digit[1]) then dxDrawLine(x, y + line_w/4, x, y + h/2 - line_w/4, clr, line_w) end
	if(digit[2]) then dxDrawLine(x, y + h/2 + line_w/4, x, y + h -  line_w/4, clr, line_w) end
	if(digit[3]) then dxDrawLine(x + line_w/4, y, x + w -  line_w/4, y, clr, line_w) end
	if(digit[4]) then dxDrawLine(x + line_w/4, y + h/2, x + w - line_w/4, y + h/2, clr, line_w) end
	if(digit[5]) then dxDrawLine(x + line_w/4, y + h, x + w - line_w/4, y + h, clr, line_w) end
	if(digit[6]) then dxDrawLine(x + w, y + line_w/4, x + w, y + h/2 - line_w/4, clr, line_w) end
	if(digit[7]) then dxDrawLine(x + w, y + h/2 + line_w/4, x + w, y + h - line_w/4, clr, line_w) end
end

local function renderClock(x, y, w, h)
	-- border
	--dxDrawLine ( g_Pos[1], g_Pos[2], g_Pos[1] + g_Size[1], g_Pos[2], tocolor ( 196, 196, 196 ), 1 )
	--dxDrawLine ( g_Pos[1] + g_Size[1], g_Pos[2], g_Pos[1] + g_Size[1], g_Pos[2] + g_Size[2], tocolor ( 64, 64, 64 ), 1 )
	--dxDrawLine ( g_Pos[1] + g_Size[1], g_Pos[2] + g_Size[2], g_Pos[1], g_Pos[2] + g_Size[2], tocolor ( 64, 64, 64 ), 1 )
	--dxDrawLine ( g_Pos[1], g_Pos[2] + g_Size[2], g_Pos[1], g_Pos[2], tocolor ( 196, 196, 196 ), 1 )
	dxDrawRectangle(x, y, w, h, BG_COLOR)
	
	local tm = getRealTime()
	local buf = ("%02u:%02u:%02u"):format(tm.hour, tm.minute, tm.second)
	local digitW = w / (6 + 4)
	local digitH = h * 0.8
	local pt_size = (digitW + h * 0.8)/20
	local digitY = y + h * 0.1
	local ptY1 = y + h * 1/3
	local ptY2 = y + h * 2/3
	
	x = x + digitW*0.2
	
	for i = 1, buf:len() do
		local c = buf:sub(i, i)
		if(c == ":") then
			x = x + digitW*0.3
			if(tm.second%2 == 0) then
				dxDrawRectangle(x - pt_size/2, ptY1 - pt_size/2, pt_size, pt_size, TEXT_COLOR)
				dxDrawRectangle(x - pt_size/2, ptY2 - pt_size/2, pt_size, pt_size, TEXT_COLOR)
			end
			x = x + digitW*0.3
		else
			local n = tonumber(c)
			drawDigit(n, x + digitW*0.2, digitY, digitW, digitH, TEXT_COLOR)
			x = x +	digitW*1.4
		end
	end
end

local function updateBuffer()
	local w, h = g_Size[1], g_Size[2]
	
	if(not g_Buffer) then
		g_Buffer = dxCreateRenderTarget(w, h, true)
	end
	
	dxSetRenderTarget(g_Buffer, true)
	dxSetBlendMode("modulate_add")
	renderClock(0, 0, w, h)
	dxSetBlendMode("blend")
	dxSetRenderTarget()
end

local function render()
	local x, y = g_Pos[1], g_Pos[2]
	local w, h = g_Size[1], g_Size[2]
	if(g_Buffer) then
		dxSetBlendMode("add")
		dxDrawImage(x, y, w, h, g_Buffer)
		dxSetBlendMode("blend")
	else
		renderClock(x, y, w, h)
	end
end

g_WidgetCtrl[$(wg_show)] = function(b)
	if((g_Show and b) or (not g_Show and not b)) then return end
	g_Show = b
	if(b) then
		addEventHandler("onClientRender", g_Root, render)
		if(USE_RENDER_TARGET) then
			g_UpdateTimer = setTimer(updateBuffer, 1000, 0)
			updateBuffer()
		end
	else
		removeEventHandler("onClientRender", g_Root, render)
		if(g_UpdateTimer) then
			killTimer(g_UpdateTimer)
			g_UpdateTimer = false
		end
		if(g_Buffer) then
			destroyElement(g_Buffer)
			g_Buffer = false
		end
	end
end

g_WidgetCtrl[$(wg_isshown)] = function()
	return g_Show
end

g_WidgetCtrl[$(wg_move)] = function(x, y)
	g_Pos = { x, y }
end

g_WidgetCtrl[$(wg_resize)] = function(w, h)
	g_Size = { w, h }
	
	if(g_Buffer) then
		destroyElement(g_Buffer)
		g_Buffer = false
	end
end

g_WidgetCtrl[$(wg_getsize)] = function()
	return g_Size
end

g_WidgetCtrl[$(wg_getpos)] = function()
	return g_Pos
end

g_WidgetCtrl[$(wg_reset)] = function()
	--g_Size = { g_ScreenSize[2]*0.11, g_ScreenSize[2]*0.11 }
	g_Size = { g_ScreenSizeSqrt[2]*3.5, g_ScreenSizeSqrt[2]*1.4 }
	g_Pos = { g_ScreenSize[1]*0.96 - g_Size[1], g_ScreenSize[2]*0.1 }
	g_WidgetCtrl[$(wg_show)](false)
end

---------------------------------
-- Global function definitions --
---------------------------------

function widgetCtrl(op, arg1, arg2)
	if(g_WidgetCtrl[op]) then
		return g_WidgetCtrl[op](arg1, arg2)
	end
end

----------
-- Code --
----------

#VERIFY_SERVER_BEGIN("4704A166BC367AA476EEEEC632C4933A")
	g_WidgetCtrl[$(wg_reset)]() -- reset pos, size, visiblity
	triggerEvent("onRafalhAddWidget", g_Root, getThisResource(), g_WidgetName)
	addEventHandler("onRafalhGetWidgets", g_Root, function()
		triggerEvent("onRafalhAddWidget", g_Root, getThisResource(), g_WidgetName)
	end)
#VERIFY_SERVER_END()
