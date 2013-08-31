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
local g_Controls = { w = false, s = false, a = false, d = false, space = false, up = false, down = false }

local g_WidgetName = {"Keyboard spectator", pl = "Obserwator klawiatury"}
local g_BgColor = tocolor ( 0, 0, 128, 96 )
local g_ActiveBgColor = tocolor ( 255, 196, 0, 96 )
local g_BorderColor = tocolor ( 0, 0, 0 )
local g_TextColor = tocolor ( 255, 255, 255 )

addEvent ( "onClientPlayerControls", true )
addEvent ( "onSyncControlsReq", true )

--------------------------------
-- Local function definitions --
--------------------------------

local function drawKey ( name, is_down, x, y, w, h )
	if ( is_down ) then
		dxDrawRectangle ( x, y, w, h, g_ActiveBgColor )
	else
		dxDrawRectangle ( x, y, w, h, g_BgColor )
	end
	
	dxDrawLine ( x, y, x + w, y, g_BorderColor )
	dxDrawLine ( x + w, y, x + w, y + h, g_BorderColor )
	dxDrawLine ( x + w, y + h, x, y + h, g_BorderColor )
	dxDrawLine ( x, y + h, x, y, g_BorderColor )
	
	dxDrawText ( name, x, y, x + w, y + h, g_TextColor, 1, "default", "center", "center" )
end

local function KbspRender ()
	local veh = getPedOccupiedVehicle ( g_Me )
	local target = getCameraTarget ()
	if ( not target or target == veh or target == g_Me ) then return end
	
	local key_w = math.floor ( g_Size[1] / 10 )
	local key_h = math.floor ( g_Size[2] / 4 )
	
	dxDrawRectangle ( g_Pos[1], g_Pos[2], g_Size[1], g_Size[2], tocolor ( 0, 0, 0, 32 ) )
	
	drawKey ( "W", g_Controls.w, g_Pos[1] + key_w, g_Pos[2], key_w, key_h )
	drawKey ( "S", g_Controls.s, g_Pos[1] + key_w, g_Pos[2] + key_h, key_w, key_h )
	drawKey ( "A", g_Controls.a, g_Pos[1], g_Pos[2] + key_h, key_w, key_h )
	drawKey ( "D", g_Controls.d, g_Pos[1] + 2 * key_w, g_Pos[2] + key_h, key_w, key_h )
	
	drawKey ( "Space", g_Controls.space, g_Pos[1] + key_w, g_Pos[2] + 3 * key_h, 4 * key_w, key_h )
	
	drawKey ( "Up", g_Controls.up, g_Pos[1] + 8 * key_w, g_Pos[2] + 2 * key_h, key_w, key_h )
	drawKey ( "Left", --[[g_Controls.a]]false, g_Pos[1] + 7 * key_w, g_Pos[2] + 3 * key_h, key_w, key_h )
	drawKey ( "Down", g_Controls.down, g_Pos[1] + 8 * key_w, g_Pos[2] + 3 * key_h, key_w, key_h )
	drawKey ( "Right", --[[g_Controls.d]]false, g_Pos[1] + 9 * key_w, g_Pos[2] + 3 * key_h, key_w, key_h )
end

local function KbspOnPlayerControls ( data )
	--outputDebugString ( "KbspOnPlayerControls", 3 )
	g_Controls.w = data:sub ( 1, 1 ) == "1"
	g_Controls.s = data:sub ( 2, 2 ) == "1"
	g_Controls.a = data:sub ( 3, 3 ) == "1"
	g_Controls.d = data:sub ( 4, 4 ) == "1"
	g_Controls.space = data:sub ( 5, 5 ) == "1"
	g_Controls.up = data:sub ( 6, 6 ) == "1"
	g_Controls.down = data:sub ( 7, 7 ) == "1"
end

g_WidgetCtrl[$(wg_show)] = function ( bVisible )
	if ( bVisible == g_Show ) then
		return
	end
	g_Show = bVisible
	if ( bVisible ) then
		addEventHandler ( "onClientRender", g_Root, KbspRender )
		triggerServerEvent ( "onSyncControlsReq", g_Root, true )
	else
		removeEventHandler ( "onClientRender", g_Root, KbspRender )
		triggerServerEvent ( "onSyncControlsReq", g_Root, false )
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
	--g_Size = { 200, 31 }
	--g_Size = { g_ScreenSize[2]*0.22, g_ScreenSize[2]*0.03 }
	g_Size = { g_ScreenSizeSqrt[2]*20, g_ScreenSizeSqrt[2]*6 }
	g_Pos = { ( g_ScreenSize[1] - g_Size[1] ) / 2, g_ScreenSize[2]*0.95 - g_Size[2] - 120 }
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
	g_WidgetCtrl[$(wg_reset)]() -- reset pos, size, visiblity
	addEventHandler("onClientPlayerControls", g_Root, KbspOnPlayerControls)
	triggerEvent("onRafalhAddWidget", g_Root, getThisResource(), g_WidgetName)
	addEventHandler("onRafalhGetWidgets", g_Root, function()
		triggerEvent("onRafalhAddWidget", g_Root, getThisResource(), g_WidgetName)
	end)
end)
