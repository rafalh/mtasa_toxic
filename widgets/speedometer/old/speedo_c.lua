--------------
-- Includes --
--------------

#include "..\\shared\\verification_code.lua"
#include "..\\shared\\widgets.lua"

---------------------
-- Local variables --
---------------------

local g_Root = getRootElement ()
local g_Me = getLocalPlayer ()
local g_ScreenSize = { guiGetScreenSize () }
local g_Size = { 0.22*g_ScreenSize[2], 0.22*g_ScreenSize[2] }
local g_Pos = { g_ScreenSize[1] - g_Size[1] - 10, g_ScreenSize[2] - g_Size[2] - 120 }
local g_Show = false
local g_Verified = false
local g_WidgetCtrl = {}
local g_tFireStart = nil

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
	local vehSpeed = math.sqrt ( vx^2 + vy^2 + vz^2 ) * 161
	local vehHealth = getElementHealth ( veh )
	
	if vehHealth and ( vehHealth > 0 ) then
		-- Show a little red/green health bar on the speedo
		local hp = (vehHealth-250)/750
		local curBarLen = hp*g_Size[2]*0.2
		if curBarLen < 1 then curBarLen = 1 end
		
		-- green/yellow till 50%, then yellow/red
		local r = 255*(1 - hp)/0.5
		if r > 255 then r = 255 end
		local g = 255*hp/0.5
		if g > 255 then g = 255 end
		if g < 0 then g = 0 end
		
		if hp >= 0 then
			g_tFireStart = nil
			dxDrawRectangle ( g_Pos[1] + g_Size[1]/2 - g_Size[2]*0.2/2, g_Pos[2] + g_Size[2]*0.55, curBarLen, g_Size[2]*0.03, tocolor ( r, g, 0, 120 ) )
			dxDrawRectangle ( g_Pos[1] + g_Size[1]/2 - g_Size[2]*0.2/2 + curBarLen, g_Pos[2] + g_Size[2]*0.55, g_Size[2]*0.2-curBarLen, g_Size[2]*0.03, tocolor ( 100, 100, 100, 120 ) )
		else
			-- Flash red bar for 5s when car is about to blow
			if not g_tFireStart then g_tFireStart = getTickCount() end
			local firePerc = (5000 - (getTickCount() - g_tFireStart)) / 5000
			if firePerc < 0 then firePerc = 0 end
			local a = 120
			if (getTickCount()/300)%2 > 1 then a = 0 end
			dxDrawRectangle ( g_Pos[1] + g_Size[1]/2 - g_Size[2]*0.2/2, g_Pos[2] + g_Size[2]*0.55, firePerc*g_Size[2]*0.2, g_Size[2]*0.03, tocolor(255, 0, 0, a) )
		end    
	end
	-- Draw rotated needle image
	-- Image is scaled exactly 1° per kmh of speed, so we can use vehSpeed directly
	dxDrawImage ( g_Pos[1], g_Pos[2], g_Size[1], g_Size[2], "disc.png", 0, 0, 0, white, false )
	dxDrawImage ( g_Pos[1], g_Pos[2], g_Size[1], g_Size[2], "needle.png", vehSpeed, 0, 0, white, false )
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

---------------------------------
-- Global function definitions --
---------------------------------

function widgetCtrl ( op, arg1, arg2 )
	if ( g_Verified and g_WidgetCtrl[op] ) then
		return g_WidgetCtrl[op] ( arg1, arg2 )
	end
end

------------
-- Events --
------------

addEvent ( "onEvent_rafalh", true )

addEventHandler ( "onEvent_rafalh", g_Root, function ( event, code )
	if ( event == 10 and code == verification_code ( g_Me, getResourceName ( getThisResource () ) ) ) then -- onVerifyServerReply, sourceResource==getThisResource() mta bug?
		-- ADD EVENT HANDLERS HERE
		g_Verified = true
		if ( g_Show ) then
			addEventHandler ( "onClientRender", g_Root, onClientRender )
		end
		triggerEvent ( "onRafalhAddWidget", g_Root, getThisResource (), "Speedometer" )
		addEventHandler ( "onRafalhGetWidgets", g_Root, function ()
			triggerEvent ( "onRafalhAddWidget", g_Root, getThisResource (), "Speedometer" )
		end )
	end
end )

if ( md5 ( getResourceName ( getThisResource () ) ) == "75FDB4AC6683119FDF6813EB7E40FC26" ) then
	triggerServerEvent ( "onEvent_rafalh", g_Root, 9, getResourceName ( getThisResource () ) ) -- onVerifyServer
end
