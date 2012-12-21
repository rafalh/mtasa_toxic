--------------
-- Includes --
--------------

#include "..\\include\\serv_verification.lua"
#include "..\\include\\widgets.lua"

-----------------
-- Definitions --
-----------------

local IMAGE_PATH = "logo.jpg"
local SERVER_WEBSITE = "toxic.no-ip.eu"

---------------------
-- Local variables --
---------------------

local g_Root = getRootElement ()
local g_Me = getLocalPlayer ()
local g_ScreenSize = { guiGetScreenSize () }
local g_ScreenSizeSqrt = { g_ScreenSize[1]^(1/2), g_ScreenSize[2]^(1/2) }
local g_Image, g_Website, g_Size, g_Pos = false, false -- set in WG_RESET
local g_WidgetCtrl = {}

---------------------------------
-- Local function declarations --
---------------------------------

g_WidgetCtrl[$(wg_show)] = function ( visible )
	if ( visible and not g_Image ) then
		g_Image = guiCreateStaticImage( g_Pos[1], g_Pos[2], g_Size[1], g_Size[2] - 20, IMAGE_PATH, false )
		g_Website = guiCreateLabel ( g_Pos[1], g_Pos[2] + g_Size[2] - 20, g_Size[1], 20, SERVER_WEBSITE, false )
		guiLabelSetColor ( g_Website, 0x70, 0xc0, 0x00 )
		guiSetFont ( g_Website, "default-bold-small" )
	elseif ( not visible and g_Image ) then
		destroyElement ( g_Image )
		destroyElement ( g_Website )
		g_Image, g_Website = false, false
	end
end

g_WidgetCtrl[$(wg_isshown)] = function ()
	return ( g_Image and true ) or false
end

g_WidgetCtrl[$(wg_move)] = function ( x, y )
	if ( g_Image ) then
		guiSetPosition ( g_Image, x, y, false )
	end
	g_Pos = { x, y }
end

g_WidgetCtrl[$(wg_resize)] = function ( w, h )
	if ( g_Image ) then
		guiSetSize ( g_Image, w, h - 20, false )
		guiSetPosition ( g_Website, g_Pos[1], g_Pos[2] + h - 20, false )
	end
	g_Size = { w, h }
end

g_WidgetCtrl[$(wg_getsize)] = function ()
	return g_Size
end

g_WidgetCtrl[$(wg_getpos)] = function ()
	return g_Pos
end

g_WidgetCtrl[$(wg_reset)] = function ()
	--g_Size = { g_ScreenSize[2]*0.15, g_ScreenSize[2]*0.15*87/196 }
	g_Size = { g_ScreenSizeSqrt[2]*4, g_ScreenSizeSqrt[2]*4*( 87 + 20 )/196 }
	--g_Pos = { g_ScreenSize[1]*0.95 - g_Size[1], g_ScreenSize[2]*0.05 }
	g_Pos = { g_ScreenSize[1] - g_ScreenSizeSqrt[2]*3 - 24 - g_Size[1]/2, g_ScreenSize[2]*0.05 }
	
	-- image is visible by default
	if ( g_Image ) then
		guiSetPosition ( g_Image, g_Pos[1], g_Pos[2], false )
		guiSetSize ( g_Image, g_Size[1], g_Size[2] - 20, false )
		guiSetPosition ( g_Website, g_Pos[1], g_Pos[2] + g_Size[2] - 20, false )
	else
		g_WidgetCtrl[$(wg_show)] ( true )
	end
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
-- Init --
----------

#VERIFY_SERVER_BEGIN ( "01D16B92486D3BBE949B49D5A481BAEE" )
	g_WidgetCtrl[$(wg_reset)] () -- set pos, size and image
	triggerEvent ( "onRafalhAddWidget", g_Root, getThisResource (), "Server logo" )
	addEventHandler ( "onRafalhGetWidgets", g_Root, function ()
		triggerEvent ( "onRafalhAddWidget", g_Root, getThisResource (), "Server logo" )
	end )
#VERIFY_SERVER_END ()
