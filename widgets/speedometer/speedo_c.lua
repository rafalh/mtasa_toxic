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
local g_Verified = false
local g_WidgetCtrl = {}

---------------------------------
-- Local function declarations --
---------------------------------

local onClientRender

--------------------------------
-- Local function definitions --
--------------------------------

onClientRender = function ()
	local veh = getCameraTarget ()
	if not veh then
		return
	end
	if getElementType ( veh ) == "player" then
		veh = getPedOccupiedVehicle ( veh )
	end
	if not veh or getElementType ( veh ) ~= "vehicle" then
		return
	end
	local vx, vy, vz = getElementVelocity ( veh )
	local speed = ( ( vx^2 + vy^2 + vz^2 )^0.5 ) * 161
	local health = math.max ( ( getElementHealth ( veh ) - 250 ) / 750, 0 )
	
	-- Draw health bar
	dxDrawRectangle ( g_Pos[1] + g_Size[1]*0.35, g_Pos[2] + g_Size[2]*0.79, health*g_Size[1]*0.31, g_Size[2]*0.1, tocolor ( 255, 255*health, 0, 255 ) )
	
	-- Draw rotated needle image
	-- Image is scaled exactly 1° per kmh of speed, so we can use speed directly
	dxDrawImage ( g_Pos[1], g_Pos[2], g_Size[1], g_Size[2], "disc.png", 0, 0, 0, white, false )
	dxDrawImage ( g_Pos[1], g_Pos[2], g_Size[1], g_Size[2], "needle.png", speed-3, 0, 0, white, false )
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
	g_Size = { g_ScreenSizeSqrt[2]*6, g_ScreenSizeSqrt[2]*6 }
	g_Pos = { g_ScreenSize[1] - g_Size[1] - 24, g_ScreenSize[2]*0.92 - g_Size[2] - 120 }
	g_WidgetCtrl[$(wg_show)] ( true )
end

---------------------------------
-- Global function definitions --
---------------------------------

function widgetCtrl ( op, arg1, arg2 )
	if ( g_Verified and g_WidgetCtrl[op] ) then
		return g_WidgetCtrl[op] ( arg1, arg2 )
	end
end

----------
-- Code --
----------

addEventHandler('onClientResourceStart', resourceRoot, function()
	g_Verified = true
	g_WidgetCtrl[$(wg_reset)] () -- reset pos, size, visiblity
	triggerEvent ( "onRafalhAddWidget", g_Root, getThisResource (), "Speedometer" )
	addEventHandler ( "onRafalhGetWidgets", g_Root, function ()
		triggerEvent ( "onRafalhAddWidget", g_Root, getThisResource (), "Speedometer" )
	end )
end)
