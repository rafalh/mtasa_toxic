--------------
-- Includes --
--------------

#include "../../include/widgets.lua"

---------------------
-- Local variables --
---------------------

local IMAGE_SIZE = { 320, 320 }

local g_Me = getLocalPlayer ()
local g_Root = getRootElement ()
local g_ScreenSize = { guiGetScreenSize () }
local g_ScreenSizeSqrt = { g_ScreenSize[1]^0.5, g_ScreenSize[2]^0.5 }
local g_Show, g_Size, g_Pos = false -- set in WG_RESET
local g_WidgetCtrl = {}
local g_WidgetName = {"Speedometer", pl = "Prędkościomierz"}
local g_Textures = {}
local HAS_NITRO_API = getVersion().sortable >= "1.3.1-9.05174" -- above version with crash-fix

--------------------------------
-- Local function definitions --
--------------------------------

local function getHealth ( veh )
	local health = ( getElementHealth ( veh ) - 250 )/750
	if ( health < 0 ) then
		health = 0
	elseif ( health > 1 ) then
		health = 1
	end
	
	return health
end

local function renderSpeed ( veh )
	local vx, vy, vz = getElementVelocity ( veh )
	local mps = ( ( vx^2 + vy^2 + vz^2 )^0.5 ) * 50
	local kmph = (mps / 1000) * 3600
	
	if ( kmph > 200 ) then
		kmph = 200
	end
	
	-- 15 degress per 10km/h
	dxDrawImage ( g_Pos[1], g_Pos[2], g_Size[1], g_Size[2], g_Textures.needle, 32 + 1.5 * kmph )
end

local function renderHealth ( health )
	local x, y = g_Pos[1], g_Pos[2]
	local w, h = g_Size[1], g_Size[2]
	if ( health > 0 ) then
		dxDrawImageSection ( x, y, w, (1 - health) * h, 0, 0, IMAGE_SIZE[1], (1 - health) * IMAGE_SIZE[2], g_Textures.hp, 0, 0, 0, tocolor ( 96, 96, 96, 255 ) )
		dxDrawImageSection ( x, y + (1 - health) * h, w, health * h, 0, (1 - health) * IMAGE_SIZE[2], IMAGE_SIZE[1], health * IMAGE_SIZE[2], g_Textures.hp, 0, 0, 0, tocolor ( 255, 255, 255, 255 ) )
	else
		local a = 96 + ( math.sin ( getTickCount () / 180 ) + 1 ) * 0.5 * ( 255 - 96 )
		dxDrawImage ( x, y, w, h, g_Textures.hp, 0, 0, 0, tocolor ( a, a, a, 255 ) )
	end
end

local function renderNos(veh)
	local nos = 0
	
	if(veh == getPedOccupiedVehicle(g_Me)) then
		local res = getResourceFromName("rafalh_nitro")
		if(res) then
			nos = call(res, "getNitro") or 0
		elseif(HAS_NITRO_API) then
			nos = not isVehicleNitroRecharging(veh) and getVehicleNitroLevel(veh) or 0
		end
	end
	
	local x, y = g_Pos[1], g_Pos[2]
	local w, h = g_Size[1], g_Size[2]
	dxDrawImageSection ( x, y, w, (1 - nos) * h, 0, 0, IMAGE_SIZE[1], (1 - nos) * IMAGE_SIZE[2], g_Textures.nos, 0, 0, 0, tocolor ( 96, 96, 96, 255 ) )
	dxDrawImageSection ( x, y + (1 - nos) * h, w, nos * h, 0, (1 - nos) * IMAGE_SIZE[2], IMAGE_SIZE[1], nos * IMAGE_SIZE[2], g_Textures.nos, 0, 0, 0, tocolor ( 255, 255, 255, 255 ) )
end

local function renderMeter ()
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
	
	local health = getHealth ( veh )
	renderHealth ( health )
	renderNos ( veh )
	
	local r, g, b = 64 + ( 1 - health ) * 128, 196, 64
	dxDrawImage ( g_Pos[1], g_Pos[2], g_Size[1], g_Size[2], g_Textures.bg, 0, 0, 0, tocolor ( r, g, b ) )
	dxDrawImage ( g_Pos[1], g_Pos[2], g_Size[1], g_Size[2], g_Textures.text )
	
	renderSpeed ( veh )
end

g_WidgetCtrl[$(wg_show)] = function ( b )
	if (b == g_Show) then
		return
	end
	g_Show = b
	if(b) then
		addEventHandler("onClientRender", g_Root, renderMeter)
		
		g_Textures.hp = dxCreateTexture("hp.png")
		g_Textures.bg = dxCreateTexture("bg.png")
		g_Textures.nos = dxCreateTexture("nos.png")
		g_Textures.needle = dxCreateTexture("needle.png")
		g_Textures.text = dxCreateTexture("text.png")
	else
		removeEventHandler("onClientRender", g_Root, renderMeter)
		for id, tex in pairs(g_Textures) do
			destroyElement(tex)
		end
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
	g_Size = { g_ScreenSizeSqrt[2]*7, g_ScreenSizeSqrt[2]*7 }
	g_Pos = { g_ScreenSize[1] - g_Size[1] - 24, g_ScreenSize[2] - g_Size[2] - 128 }
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

addEventHandler('onClientResourceStart', resourceRoot, function()
	g_WidgetCtrl[$(wg_reset)] () -- reset pos, size, visiblity
	triggerEvent("onRafalhAddWidget", g_Root, getThisResource(), g_WidgetName)
	addEventHandler("onRafalhGetWidgets", g_Root, function()
		triggerEvent("onRafalhAddWidget", g_Root, getThisResource(), g_WidgetName)
	end)
end)
