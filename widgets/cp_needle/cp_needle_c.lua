--------------
-- Includes --
--------------

#include "../../include/widgets.lua"

---------------------
-- Local variables --
---------------------

local g_Root = getRootElement ()
local g_ResRoot = getResourceRootElement()
local g_Me = getLocalPlayer ()
local g_ScreenSize = { guiGetScreenSize () }
local g_ScreenSizeSqrt = { g_ScreenSize[1]^(1/2), g_ScreenSize[2]^(1/2) }
local g_Show, g_Size, g_Pos = false -- set in WG_RESET
local g_Checkpoints = false
local g_WidgetCtrl = {}
local g_WidgetName = {"CP needle", pl = "Wskaźnik CP"}
local g_Textures = {}

--------------------------------
-- Local function definitions --
--------------------------------

local function onClientRender()
	local target = getCameraTarget ()
	if ( target and getElementType ( target ) == "vehicle" ) then
		target = getVehicleOccupant ( target )
	end
	if ( target ) then
		local cp = g_Checkpoints[getElementData ( target, "race.checkpoint" )]
		if ( isElement ( cp ) ) then
			local cx, cy = getElementPosition ( cp )
			local x, y, _, lx, ly = getCameraMatrix ()
			local a = math.deg ( math.atan2 ( cx-x, cy-y ) - math.atan2 ( lx-x, ly-y ) )
			dxDrawImage ( g_Pos[1], g_Pos[2], g_Size[1], g_Size[2], g_Textures.needle, a )
		end
	end
end

local function loadCheckpoints()
	local checkpoints = getElementsByType ("checkpoint")
	local idToCp = {}
	local cpToIndex = {}
	
	for i, cp in ipairs(checkpoints) do
		local id = getElementID(cp)
		assert(not idToCp[id])
		idToCp[id] = cp
		cpToIndex[cp] = i
	end
	
	g_Checkpoints = {}
	
	local cp = checkpoints[1]
	while(cp) do
		table.insert(g_Checkpoints, cp)
		local nextId = getElementData(cp, "nextid")
		local nextCp = idToCp[nextId]
		if(not nextCp) then
			local i = cpToIndex[cp]
			nextCp = checkpoints[i + 1]
		end
		
		idToCp[nextId] = nil -- dont hang
		cp = nextCp
	end
	
	--outputDebugString("Loaded "..#g_Checkpoints.." CPs")
end

local function onClientResourceStart()
	if(g_Show) then
		loadCheckpoints()
	else
		g_Checkpoints = false
	end
end

g_WidgetCtrl[$(wg_show)] = function ( b )
	if ((g_Show and b) or (not g_Show and not b)) then return end
	g_Show = b
	if(b) then
		if(not g_Checkpoints) then
			loadCheckpoints()
		end
		g_Textures.needle = dxCreateTexture("needle.png")
		addEventHandler("onClientRender", g_Root, onClientRender)
	else
		removeEventHandler("onClientRender", g_Root, onClientRender)
		destroyElement(g_Textures.needle)
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
	g_WidgetCtrl[$(wg_reset)]() -- reset pos, size, visiblity
	addEventHandler("onClientResourceStart", g_Root, onClientResourceStart) -- map resource start
	triggerEvent("onRafalhAddWidget", g_Root, getThisResource(), g_WidgetName)
	addEventHandler("onRafalhGetWidgets", g_Root, function()
		triggerEvent("onRafalhAddWidget", g_Root, getThisResource(), g_WidgetName)
	end)
end)
