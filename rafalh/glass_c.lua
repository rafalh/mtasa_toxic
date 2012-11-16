--------------
-- Includes --
--------------

#include "include/internal_events.lua"
#include "../include/serv_verification.lua"

----------------------
-- Global variables --
----------------------

local g_BigDemageTime = false
local g_PrevHp = 1000
local g_PrevTarget = nil
local g_Size = 0
local g_Pos = 0
local g_Verified = false

--------------------------------
-- Local function definitions --
--------------------------------

local function renderGlass ()
	local veh = getCameraTarget ()
	if ( veh and ( getElementType ( veh ) == "player" or getElementType ( veh ) == "ped" ) ) then
		veh = getPedOccupiedVehicle ( veh )
	end
	if ( veh ~= g_PrevTarget ) then
		g_PrevTarget = veh
		g_PrevHp = 0 -- h will be > g_PrevHp so no image will be displayed
		g_BigDemageTime = false
	end
	if ( veh ) then
		local h = getElementHealth ( veh )
		if ( g_PrevHp - h > 100 ) then
			if ( not g_BigDemageTime ) then
				g_Size = math.random () / 2 + 0.25
				g_Pos = math.random () * ( 1 - g_Size )
			end
			g_BigDemageTime = getTickCount ()
		elseif ( h > g_PrevHp ) then
			g_BigDemageTime = false
		end
		g_PrevHp = h
		if ( g_BigDemageTime ) then
			local a = 255 - ( getTickCount () - g_BigDemageTime ) / 15000 * 255
			if ( a <= 0 ) then
				g_BigDemageTime = false
			else
				if ( g_Settings.breakable_glass ) then
					-- broken glass
					dxDrawImage ( g_Pos * g_ScreenSize[1], g_Pos * g_ScreenSize[2], g_Size * g_ScreenSize[1], g_Size * g_ScreenSize[2], "img/broken_glass.png", 0, 0, 0, tocolor ( 255, 255, 255, a ) )
				end
				
				-- red screen for 128 ms
				a = 128 - ( getTickCount () - g_BigDemageTime )
				if ( a > 0 and g_Settings.red_damage_screen ) then
					dxDrawRectangle ( 0, 0, g_ScreenSize[1], g_ScreenSize[2], tocolor ( 255, 0, 0, a ) )
				end
			end
		end
	end
end

------------
-- Events --
------------

#VERIFY_SERVER_BEGIN ( "593C2070A55147B063D423AFAC7003D6" )
	addEventHandler ( "onClientRender", g_Root, renderGlass )
	g_Verified = true
#VERIFY_SERVER_END ()
