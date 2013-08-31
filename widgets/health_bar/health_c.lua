--------------
-- Includes --
--------------

#include "../../include/widgets.lua"

-----------------
-- Definitions --
-----------------

#BG_IMG = "images/bg.png"
#LEFT_BAR_IMG = "images/bar_l.png"
#CENTER_BAR_IMG = "images/bar.png"
#RIGHT_BAR_IMG = nil
#LEFT_BAR_W_DIV_H = 16/32
#RIGHT_BAR_W_DIV_H = 0
#BAR_H = 0.9
#BAR_X = 0.01
#BAR_W = 0.935

---------------------
-- Local variables --
---------------------

local g_Me = getLocalPlayer ()
local g_Root = getRootElement ()
local g_ScreenSize = { guiGetScreenSize () }
local g_ScreenSizeSqrt = { g_ScreenSize[1]^0.5, g_ScreenSize[2]^0.5 }
local g_Show, g_Size, g_Pos = false -- set in WG_RESET
local g_WidgetCtrl = {}

local g_BarX, g_BarY
local g_BarH
local g_LBarW, g_RBarW

---------------------------------
-- Local function declarations --
---------------------------------

local onClientRender
local recalc

--------------------------------
-- Local function definitions --
--------------------------------

onClientRender = function ()
	local veh = getCameraTarget ()
	if ( not veh ) then
		return
	end
	if ( getElementType ( veh ) == "player" ) then
		veh = getPedOccupiedVehicle ( veh )
	end
	if ( not veh or getElementType ( veh ) ~= "vehicle" ) then
		return
	end
	
	local value = ( getElementHealth ( veh ) - 250 )/750
	
	if ( value < 0 ) then
		value = 0
	elseif ( value > 1 ) then
		value = 1
	end
	
	local bar_w = g_Size[1]*$(BAR_W)*value
	local lbar_w, rbar_w = g_LBarW, g_RBarW
	-- rest calculated in recalc ()
	
	if ( bar_w > lbar_w + rbar_w ) then
		bar_w = bar_w - lbar_w - rbar_w
	else
		--lbar_w = math.floor ( bar_w )
#if(LEFT_BAR_IMG) then
		lbar_w = math.floor ( bar_w / $(RIGHT_BAR_W_DIV_H/LEFT_BAR_W_DIV_H + 1) )
#end
#if(RIGHT_BAR_IMG) then
		rbar_w = math.floor ( bar_w / $(LEFT_BAR_W_DIV_H/RIGHT_BAR_W_DIV_H + 1) )
#end
		bar_w = 0
	end
	
	dxDrawImage ( g_Pos[1], g_Pos[2], g_Size[1], g_Size[2], $("\""..BG_IMG.."\""))
#if(LEFT_BAR_IMG) then
	dxDrawImage ( g_BarX, g_BarY, lbar_w, g_BarH, $("\""..LEFT_BAR_IMG.."\"") )
#end
	dxDrawImage ( g_BarX $(LEFT_BAR_IMG and "+ lbar_w" or ""), g_BarY, bar_w, g_BarH, $("\""..CENTER_BAR_IMG.."\"") )
#if(RIGHT_BAR_IMG) then
	dxDrawImage ( g_BarX $(LEFT_BAR_IMG and "+ lbar_w" or "") + bar_w, g_BarY, rbar_w, g_BarH, $("\""..RIGHT_BAR_IMG.."\"") )
#end
end

recalc = function ()
	g_BarX = math.floor ( g_Pos[1] + g_Size[1]*$(BAR_X) )
	g_BarY = g_Pos[2] + g_Size[2]*(1 - $(BAR_H))/2
	g_BarH = g_Size[2]*$(BAR_H)
	g_LBarW = $(LEFT_BAR_IMG and "math.floor ( g_BarH*"..LEFT_BAR_W_DIV_H.." )" or 0)
	g_RBarW = $(RIGHT_BAR_IMG and "math.floor ( g_BarH*"..RIGHT_BAR_W_DIV_H.." )" or 0)
end

g_WidgetCtrl[$(wg_show)] = function ( b )
	if ( b == g_Show ) then
		return
	end
	g_Show = b
	if ( b ) then
		addEventHandler ( "onClientRender", g_Root, onClientRender )
	else
		removeEventHandler ( "onClientRender", g_Root, onClientRender )
	end
end

g_WidgetCtrl[$(wg_isshown)] = function ()
	return g_Show
end

g_WidgetCtrl[$(wg_move)] = function ( x, y )
	g_Pos = { x, y }
	recalc ()
end

g_WidgetCtrl[$(wg_resize)] = function ( w, h )
	g_Size = { w, h }
	recalc ()
end

g_WidgetCtrl[$(wg_getsize)] = function ()
	return g_Size
end

g_WidgetCtrl[$(wg_getpos)] = function ()
	return g_Pos
end

g_WidgetCtrl[$(wg_reset)] = function ()
	g_Size = { g_ScreenSizeSqrt[2]*6, g_ScreenSizeSqrt[2]*0.8 }
	g_Pos = { g_ScreenSize[1] - g_Size[1] - 24, 0.15*g_ScreenSize[2] }
	recalc ()
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
	triggerEvent ( "onRafalhAddWidget", g_Root, getThisResource (), "Health bar" )
	addEventHandler ( "onRafalhGetWidgets", g_Root, function ()
		triggerEvent ( "onRafalhAddWidget", g_Root, getThisResource (), "Health bar" )
	end )
end)
