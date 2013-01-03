--------------
-- Includes --
--------------

#include "..\\include\\serv_verification.lua"

-----------------
-- Definitions --
-----------------

#PALETTE_WIDTH = 500
#PALETTE_HEIGHT = 172
#PALETTE_COLOR_W = 25
#PALETTE_COLOR_H = 24.5
#PALETTE_COLORS_COUNT = 127

#PALETTE_COLORS_IN_ROW = PALETTE_WIDTH/PALETTE_COLOR_W
#PALETTE_COLORS_IN_COL = PALETTE_HEIGHT/PALETTE_COLOR_H

#WND_COLOR = 1
#WND_EVENT = 2
#WND_MOUSEDOWN = 3

---------------------
-- Local variables --
---------------------

local g_Me = getLocalPlayer ()
local g_Root = getRootElement ()
local g_Windows = {} -- g_Windows[window] = { r, g, b, intensity, color, brightness, palette, event }
local g_WindowsCount = 0
local g_Verified = false

---------------------------------
-- Local function declarations --
---------------------------------

local onClientRender
local onClientGUIMouseDown
local onClientGUIMouseUp
local onClientMouseMove
local onClientResourceStop

--------------------------------
-- Local function definitions --
--------------------------------

onClientRender = function ()
	for wnd, data in pairs ( g_Windows ) do
		local x, y = guiGetPosition ( wnd, false )
		local clr_x = x + 10 + ( data[$(WND_COLOR)]%$(PALETTE_COLORS_IN_ROW) )*$(PALETTE_COLOR_W)
		local clr_y = y + 20 + math.floor ( data[$(WND_COLOR)]/$(PALETTE_COLORS_IN_ROW) )*$(PALETTE_COLOR_H)
		
		dxDrawLine ( clr_x, clr_y, clr_x + $(PALETTE_COLOR_W), clr_y, tocolor ( 255, 0, 0 ), 2, true )
		dxDrawLine ( clr_x + $(PALETTE_COLOR_W), clr_y, clr_x + $(PALETTE_COLOR_W), clr_y + $(PALETTE_COLOR_H), tocolor ( 255, 0, 0 ), 2, true )
		dxDrawLine ( clr_x + $(PALETTE_COLOR_W), clr_y + $(PALETTE_COLOR_H), clr_x, clr_y + $(PALETTE_COLOR_H), tocolor ( 255, 0, 0 ), 2, true )
		dxDrawLine ( clr_x, clr_y + $(PALETTE_COLOR_H), clr_x, clr_y, tocolor ( 255, 0, 0 ), 2, true )
	end
end

onClientGUIMouseDown = function ( button, x, y )
	local wnd = getElementParent ( source )
	local wnd_x, wnd_y = guiGetPosition ( wnd, false )
	local color = math.floor ( ( y - wnd_y - 20 )/$(PALETTE_COLOR_H) ) * $(PALETTE_COLORS_IN_ROW) + math.floor ( ( x - wnd_x - 10 )/$(PALETTE_COLOR_W) )
	
	g_Windows[wnd][$(WND_MOUSEDOWN)] = true
	
	if ( color < $(PALETTE_COLORS_COUNT) ) then
		g_Windows[wnd][$(WND_COLOR)] = color
	end
end

onClientGUIMouseUp = function ( x, y )
	for wnd, data in pairs ( g_Windows ) do
		g_Windows[wnd][$(WND_MOUSEDOWN)] = false
	end
end

onClientMouseMove = function ( x, y )
	local wnd = getElementParent ( source )
	if ( g_Windows[wnd][$(WND_MOUSEDOWN)] ) then
		local wnd_x, wnd_y = guiGetPosition ( wnd, false )
		local color = math.floor ( ( y - wnd_y - 20 )/$(PALETTE_COLOR_H) ) * $(PALETTE_COLORS_IN_ROW) + math.floor ( ( x - wnd_x - 10 )/$(PALETTE_COLOR_W) )
		
		if ( color < $(PALETTE_COLORS_COUNT) ) then
			g_Windows[wnd][$(WND_COLOR)] = color
		end
	end
end

onClientResourceStop = function ()
	for wnd, data in pairs ( g_Windows ) do
		triggerEvent ( g_Windows[wnd][$(WND_EVENT)], wnd, false )
	end
end

---------------------------------
-- Global function definitions --
---------------------------------

function createVehicleColorDlg ( event, color )
	if ( not g_Verified ) then
		return false
	end
	
	addEvent ( event )
	
	local w, h = guiGetScreenSize ()
	local wnd = guiCreateWindow ( (w-$(PALETTE_WIDTH)-20)/2, (h-$(PALETTE_HEIGHT)-60)/2, $(PALETTE_WIDTH)+20, $(PALETTE_HEIGHT)+60, "Vehicle color", false )
	g_Windows[wnd] = { tonumber ( color ) or 0, event, false }
	
	guiWindowSetMovable ( wnd, true )
	guiWindowSetSizable ( wnd, false )
	
	local btn = guiCreateButton ( $(PALETTE_WIDTH)-120, $(PALETTE_HEIGHT)+30, 60, 20, "OK", false, wnd )
	addEventHandler ( "onClientGUIClick", btn, function ()
		local wnd = getElementParent ( source )
		triggerEvent ( g_Windows[wnd][$(WND_EVENT)], wnd, g_Windows[wnd][$(WND_COLOR)] )
		destroyElement ( wnd )
	end, false )
	btn = guiCreateButton ( $(PALETTE_WIDTH)-50, $(PALETTE_HEIGHT)+30, 60, 20, "Cancel", false, wnd )
	addEventHandler ( "onClientGUIClick", btn, function ()
		local wnd = getElementParent ( source )
		triggerEvent ( g_Windows[wnd][$(WND_EVENT)], wnd, false )
		destroyElement ( wnd )
	end, false )
	
	local img = guiCreateStaticImage ( 10, 20, $(PALETTE_WIDTH), $(PALETTE_HEIGHT), "img/veh_colors.png", false, wnd )
	
	addEventHandler ( "onClientGUIMouseDown", img, onClientGUIMouseDown, false )
	addEventHandler ( "onClientGUIMouseUp", img, onClientGUIMouseUp, false )
	addEventHandler ( "onClientMouseMove", img, onClientMouseMove, false )
	if ( g_WindowsCount == 0 ) then
		addEventHandler ( "onClientRender", g_Root, onClientRender )
	end
	addEventHandler ( "onClientElementDestroy", wnd, function ()
		g_WindowsCount = g_WindowsCount - 1
		if ( g_WindowsCount == 0 ) then
			removeEventHandler ( "onClientRender", g_Root, onClientRender )
		end
		g_Windows[source] = nil
	end, false )
	
	g_WindowsCount = g_WindowsCount + 1
	
	return wnd
end

------------
-- Events --
------------

#VERIFY_SERVER_BEGIN ( "62443A6D1AA2D8A266064C951C92E266" )
	g_Verified = true
	addEventHandler ( "onClientResourceStop", getResourceRootElement (), onClientResourceStop )
#VERIFY_SERVER_END ()
