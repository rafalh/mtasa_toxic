--------------
-- Includes --
--------------

#include "include/internal_events.lua"

---------------------
-- Local variables --
---------------------

local ITEM_ALPHA = 0.6
local PANEL_COLUMNS = 3
local PANEL_ALPHA = 0.9
local ITEM_W = 100
local ITEM_H = 110
local FADE_DELAY = 200

local g_Items = {}
local g_Wnd = false
local g_CurrentItem = false

-- Local functions

local function getItemFromGuiElement ( element )
	for i, item in ipairs ( g_Items ) do
		if ( item.btn == source or item.label == source ) then
			return item
		end
	end
	
	return false
end

local function onBackClick ()
	GaFadeOut ( g_CurrentItem.wnd, FADE_DELAY )
	if ( g_CurrentItem.onHide ) then
		g_CurrentItem.onHide ( g_CurrentItem.wnd2 )
	end
	g_CurrentItem = false
	GaFadeIn ( g_Wnd, FADE_DELAY, PANEL_ALPHA )
end

local function onItemClick ()
	guiSetVisible ( g_Wnd, false )
	g_CurrentItem = getItemFromGuiElement ( source )
	
	if ( not g_CurrentItem.wnd ) then
		local panel_w = g_CurrentItem.width or 450
		local panel_h = g_CurrentItem.height or 350
		local w, h = panel_w, panel_h + 55
		local x = ( g_ScreenSize[1] - w ) / 2
		local y = ( g_ScreenSize[2] - h ) / 2
		g_CurrentItem.wnd = guiCreateWindow ( x, y, w, h, g_CurrentItem.name, false )
		guiSetVisible ( g_CurrentItem.wnd, false )
		guiWindowSetSizable ( g_CurrentItem.wnd, false )
		
		g_CurrentItem.wnd2 = guiCreateLabel ( 0, 20, panel_w, panel_h, "", false, g_CurrentItem.wnd )
		
		local btn = guiCreateButton ( w - 80, h - 35, 70, 25, "Back", false, g_CurrentItem.wnd )
		addEventHandler ( "onClientGUIClick", btn, onBackClick, false )
	end
	if ( g_CurrentItem.onShow ) then
		g_CurrentItem.onShow ( g_CurrentItem.wnd2 )
	end
	GaFadeOut ( g_Wnd, FADE_DELAY )
	GaFadeIn ( g_CurrentItem.wnd, FADE_DELAY, PANEL_ALPHA )
end

local function onItemMouseEnter ()
	local item = getItemFromGuiElement ( source )
	GaFadeIn ( item.btn, 200 )
	GaResize ( item.btn, 200, ITEM_W - 20, ITEM_H - 30 )
	guiLabelSetColor ( item.label, 0, 255, 0 )
end

local function onItemMouseLeave ()
	local item = getItemFromGuiElement ( source )
	GaFadeOut ( item.btn, 200, ITEM_ALPHA )
	GaResize ( item.btn, 200, ITEM_W - 30, ITEM_H - 40 )
	guiLabelSetColor ( item.label, 255, 255, 0 )
end

local function UpHide ()
	GaFadeOut ( g_Wnd, FADE_DELAY )
	
	if ( g_CurrentItem ) then
		GaFadeOut ( g_CurrentItem.wnd, FADE_DELAY )
		if ( g_CurrentItem.onHide ) then
			g_CurrentItem.onHide ( g_CurrentItem.wnd2 )
		end
		g_CurrentItem = false
	end
	
	guiSetInputEnabled ( false )
end

local function UpCreateGui ()
	local w = ITEM_W * PANEL_COLUMNS + 20
	local h = 60 + ITEM_H * math.ceil ( #g_Items / PANEL_COLUMNS )
	local x = ( g_ScreenSize[1] - w ) / 2
	local y = ( g_ScreenSize[2] - h ) / 2
	g_Wnd = guiCreateWindow ( x, y, w, h, "User Panel", false )
	guiSetVisible ( g_Wnd, false )
	guiWindowSetSizable ( g_Wnd, false )
	
	for i, item in ipairs ( g_Items ) do
		local item_x = 10 + ( ( i - 1 ) % PANEL_COLUMNS ) * ITEM_W
		local item_y = 30 + math.floor ( ( i - 1 ) / PANEL_COLUMNS ) * ITEM_H
		
		if ( item.img ) then
			item.btn = guiCreateStaticImage ( item_x + 15, item_y, ITEM_W - 30, ITEM_H - 40, item.img, false, g_Wnd )
			guiSetAlpha ( item.btn, ITEM_ALPHA )
			addEventHandler ( "onClientGUIClick", item.btn, onItemClick, false )
			addEventHandler ( "onClientMouseEnter", item.btn, onItemMouseEnter, false )
			addEventHandler ( "onClientMouseLeave", item.btn, onItemMouseLeave, false )
			item.label = guiCreateLabel ( item_x, item_y, ITEM_W, ITEM_H - 20, item.name, false, g_Wnd )
			guiLabelSetHorizontalAlign ( item.label, "center" )
			guiLabelSetVerticalAlign ( item.label, "bottom" )
			guiSetFont ( item.label, "default-bold-small" )
			guiLabelSetColor ( item.label, 255, 255, 0 )
			addEventHandler ( "onClientGUIClick", item.label, onItemClick, false )
			addEventHandler ( "onClientMouseEnter", item.label, onItemMouseEnter, false )
			addEventHandler ( "onClientMouseLeave", item.label, onItemMouseLeave, false )
		else
			item.btn = guiCreateButton ( item_x + 5, item_y + 5, ITEM_W - 10, ITEM_H - 10, item.name, false, g_Wnd )
			addEventHandler ( "onClientGUIClick", item.btn, onItemClick, false )
		end
	end
	
	local btn = guiCreateButton ( w - 70, h - 35, 60, 25, "Close", false, g_Wnd )
	addEventHandler ( "onClientGUIClick", btn, UpHide, false )
end

local function UpShow ()
	if ( not g_Wnd ) then
		UpCreateGui ()
	end
	
	GaFadeIn ( g_Wnd, FADE_DELAY, PANEL_ALPHA )
	guiSetInputEnabled ( true )
end

local function UpInit ()
	bindKey ( g_ClientSettings.user_panel_key, "up", UpToggle )
end

----------------------
-- Global functions --
----------------------

function UpRegister ( item )
	assert(type(item) == "table", item)
	table.insert ( g_Items, item )
end

function UpToggle ()
	if ( ( not g_Wnd or not guiGetVisible ( g_Wnd ) ) and not g_CurrentItem ) then
		UpShow ()
	else
		UpHide ()
	end
end


------------
-- Events --
------------

addInternalEventHandler ( $(EV_CLIENT_INIT), UpInit )
