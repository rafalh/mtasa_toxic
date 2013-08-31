--------------
-- Includes --
--------------

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
local g_WidgetName = {"Analog clock", pl = "Analogowy zegar"}

---------------------------------
-- Local function declarations --
---------------------------------

local onClientRender
local onClientResourceStart

--------------------------------
-- Local function definitions --
--------------------------------

onClientRender = function ()
	local tm = getRealTime ()
	local x, y = g_Pos[1] + g_Size[1]/2, g_Pos[2] + g_Size[2]/2
	local m = tm.minute + tm.second/60
	local h = ( tm.hour + tm.minute/60 + tm.second/3600 )%12
	
	local angle_s = math.pi/2 - tm.second/60*2*math.pi
	local angle_m = math.pi/2 - m/60*2*math.pi
	local angle_h = math.pi/2 - h/12*2*math.pi
	
	-- border
	--dxDrawLine ( g_Pos[1], g_Pos[2], g_Pos[1] + g_Size[1], g_Pos[2], tocolor ( 196, 196, 196 ), 1 )
	--dxDrawLine ( g_Pos[1] + g_Size[1], g_Pos[2], g_Pos[1] + g_Size[1], g_Pos[2] + g_Size[2], tocolor ( 64, 64, 64 ), 1 )
	--dxDrawLine ( g_Pos[1] + g_Size[1], g_Pos[2] + g_Size[2], g_Pos[1], g_Pos[2] + g_Size[2], tocolor ( 64, 64, 64 ), 1 )
	--dxDrawLine ( g_Pos[1], g_Pos[2] + g_Size[2], g_Pos[1], g_Pos[2], tocolor ( 196, 196, 196 ), 1 )
	dxDrawRectangle ( g_Pos[1], g_Pos[2], g_Size[1], g_Size[2], tocolor ( 0, 0, 0, 64 ) )
	
	dxDrawLine ( x, y, x + math.cos ( angle_s )*g_Size[1]/2, y - math.sin ( angle_s )*g_Size[2]/2, tocolor ( 255, 255, 255 ), 1 )
	dxDrawLine ( x, y, x + math.cos ( angle_m )*g_Size[1]/3, y - math.sin ( angle_m )*g_Size[2]/3, tocolor ( 255, 255, 255 ), 1.5 )
	dxDrawLine ( x, y, x + math.cos ( angle_h )*g_Size[1]/4, y - math.sin ( angle_h )*g_Size[2]/4, tocolor ( 255, 255, 255 ), 2 )
	
	dxDrawRectangle ( g_Pos[1] + g_Size[1]*1/12 - 0.5, y - 0.5, 2, 2 )
	dxDrawRectangle ( g_Pos[1] + g_Size[1]*11/12 - 0.5, y - 0.5, 2, 2 )
	dxDrawRectangle ( x - 0.5, g_Pos[2] + g_Size[2]*1/12 - 0.5, 2, 2 )
	dxDrawRectangle ( x - 0.5, g_Pos[2] + g_Size[2]*11/12 - 0.5, 2, 2 )
end

g_WidgetCtrl[$(wg_show)] = function ( b )
	if ( ( g_Show and b ) or ( not g_Show and not b ) ) then return end
	g_Show = b
	if ( b ) then
		addEventHandler ( "onClientRender", g_Root, onClientRender )
	else
		removeEventHandler( "onClientRender", g_Root, onClientRender )
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
	--g_Size = { g_ScreenSize[2]*0.11, g_ScreenSize[2]*0.11 }
	g_Size = { g_ScreenSizeSqrt[2]*3, g_ScreenSizeSqrt[2]*3 }
	g_Pos = { g_ScreenSize[1]*0.5 - g_Size[1]/2, g_ScreenSize[2]*0.08 }
	g_WidgetCtrl[$(wg_show)] ( false )
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

addEventHandler('onClientResourceStart', resourceRoot, function()
	g_WidgetCtrl[$(wg_reset)] () -- reset pos, size, visiblity
	triggerEvent("onRafalhAddWidget", g_Root, getThisResource(), g_WidgetName)
	addEventHandler("onRafalhGetWidgets", g_Root, function()
		triggerEvent("onRafalhAddWidget", g_Root, getThisResource(), g_WidgetName)
	end)
end)
