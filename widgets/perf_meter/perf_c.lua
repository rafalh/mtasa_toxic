--------------
-- Includes --
--------------

#include "../../include/serv_verification.lua"
#include "../../include/widgets.lua"

---------------------
-- Local variables --
---------------------

local g_Root = getRootElement ()
local g_Me = getLocalPlayer ()
local g_ScreenSize = { guiGetScreenSize () }
local g_ScreenSizeSqrt = { g_ScreenSize[1]^(1/2), g_ScreenSize[2]^(1/2) }
local g_Show, g_Size, g_Pos = false -- set in WG_RESET
local g_WidgetCtrl = {}
local g_WidgetName = {"Perfomance meter", pl = "Miernik wydajności"}

local g_BgColor = tocolor ( 0, 0, 128, 96 )
local g_TextColor = tocolor ( 255, 255, 255 )
local g_Font = "bankgothic"
local g_Scale = 0.7
local g_FontHeight = dxGetFontHeight(g_Scale, g_Font)
local g_Fps = 0
local g_Frames, g_FramesTicks = 0, getTickCount()

--------------------------------
-- Local function definitions --
--------------------------------

local function PerfRender ()
	local x, y = g_Pos[1], g_Pos[2]
	local w, h = g_Size[1], g_Size[2]
	
	g_Frames = g_Frames + 1
	local ticks = getTickCount()
	local dt = ticks - g_FramesTicks
	if(ticks - g_FramesTicks >= 1000) then
		g_Fps = math.floor(g_Frames * 1000 / dt)
		g_Frames = 0
		g_FramesTicks = ticks
	end
	
	dxDrawText("FPS: ", x, y, x, y + h, tocolor(255, 255, 255), g_Scale, g_Font)
	local offset = dxGetTextWidth("FPS: ", g_Scale, g_Font)
	
	local fps = g_Fps --tonumber(getElementData(g_Me, "fps"))
	local clr
	if(not fps or fps < 20) then
		clr = tocolor(255, 0, 0)
	elseif(fps < 40) then
		clr = tocolor(255, 255, 0)
	else
		clr = tocolor(0, 255, 0)
	end
	dxDrawText ( fps or "unknown", x + offset, y, 0, 0, clr, g_Scale, g_Font)
	y = y + g_FontHeight*2/3
	
	dxDrawText("Ping: ", x, y, 0, 0, tocolor(255, 255, 255), g_Scale, g_Font)
	local offset = dxGetTextWidth("Ping: ", g_Scale, g_Font)
	
	local ping = getPlayerPing(g_Me)
	if(not ping or ping > 300) then
		clr = tocolor(255, 0, 0)
	elseif(ping > 150) then
		clr = tocolor(255, 255, 0)
	else
		clr = tocolor(0, 255, 0)
	end
	dxDrawText(ping, x + offset, y, 0, 0, clr, g_Scale, g_Font)
end

g_WidgetCtrl[$(wg_show)] = function ( bVisible )
	if ( bVisible == g_Show ) then
		return
	end
	g_Show = bVisible
	if ( bVisible ) then
		addEventHandler ( "onClientRender", g_Root, PerfRender )
	else
		removeEventHandler ( "onClientRender", g_Root, PerfRender )
	end
end

g_WidgetCtrl[$(wg_isshown)] = function ()
	return g_Show
end

g_WidgetCtrl[$(wg_move)] = function ( x, y )
	g_Pos = { x, y }
end

g_WidgetCtrl[$(wg_resize)] = function ( w, h )
	g_Size = { w, h }
end

g_WidgetCtrl[$(wg_getsize)] = function ()
	return g_Size
end

g_WidgetCtrl[$(wg_getpos)] = function ()
	return g_Pos
end

g_WidgetCtrl[$(wg_reset)] = function ()
	g_Size = { 100, 20 }
	g_Pos = { 2, g_ScreenSize[2] - g_Size[2] - 60 }
	g_WidgetCtrl[$(wg_show)] ( true )
end

---------------------------------
-- Global function definitions --
---------------------------------

function widgetCtrl ( op, arg1, arg2 )
	if ( g_WidgetCtrl[op] ) then
		return g_WidgetCtrl[op] ( arg1, arg2 )
	end
end

----------
-- Code --
----------

#VERIFY_SERVER_BEGIN ( "15CF846833407136403D841B1B76E36F" )
	g_WidgetCtrl[$(wg_reset)] () -- reset pos, size, visiblity
	triggerEvent("onRafalhAddWidget", g_Root, getThisResource(), g_WidgetName)
	addEventHandler("onRafalhGetWidgets", g_Root, function()
		triggerEvent("onRafalhAddWidget", g_Root, getThisResource(), g_WidgetName)
	end)
#VERIFY_SERVER_END ()
