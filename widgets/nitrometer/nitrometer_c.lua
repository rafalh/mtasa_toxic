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

local g_LeftBarWdivH = 16/32
local g_RightBarWdivH = 0
local g_BarH = 0.9
local g_BarX = 0.01
local g_BarW = 0.935

---------------------------------
-- Local function declarations --
---------------------------------

local canVehicleUseNitro
local onClientRender

--------------------------------
-- Local function definitions --
--------------------------------

canVehicleUseNitro = function ( veh )
	local t = getVehicleType ( veh )
	return ( t == "Automobile" or t == "Monster Truck" or t == "Quad" )
end

onClientRender = function ()
	local veh = getPedOccupiedVehicle ( g_Me )
	local target = getCameraTarget ()
	if ( not veh or not canVehicleUseNitro ( veh ) or ( target ~= veh and target ~= g_Me ) ) then
		return
	end
	local res = getResourceFromName ( "rafalh_nitro" )
	if ( not res ) then
		return
	end
	local value = call ( res, "getNitro" ) or 0
	
	--local hour, minute = getTime ( )
	--local color = ( ( hour > 19 ) or ( hour >= 0 and hour < 6 ) ) and tocolor ( 0, 255, 0 ) or tocolor ( 255, 255, 255 )
	dxDrawImage ( g_Pos[1], g_Pos[2], g_Size[1], g_Size[2], "gauge.png", 0, 0, 0, tocolor ( 0, 255, 0 ) )
	dxDrawImage ( g_Pos[1], g_Pos[2], g_Size[1], g_Size[2], "arrow.png", value * 225, 0, 0, tocolor ( 255, 0, 0 ) )
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
	--g_Size = { 128, 128 }
	--g_Size = { g_ScreenSize[2]*0.15, g_ScreenSize[2]*0.15 }
	g_Size = { g_ScreenSizeSqrt[2]*3.5, g_ScreenSizeSqrt[2]*3.5 }
	--g_Pos = { 25, g_ScreenSize[2] - g_Size[2] - 256 }
	g_Pos = { 25, g_ScreenSize[2]*0.75 - g_Size[2] }
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

#VERIFY_SERVER_BEGIN ( "16814B1E20F77E45C290DA1BBCB4A7B9" )
	g_WidgetCtrl[$(wg_reset)] () -- reset pos, size, visiblity
	triggerEvent ( "onRafalhAddWidget", g_Root, getThisResource (), "Nitrometer" )
	addEventHandler ( "onRafalhGetWidgets", g_Root, function ()
		triggerEvent ( "onRafalhAddWidget", g_Root, getThisResource (), "Nitrometer" )
	end )
#VERIFY_SERVER_END ()
