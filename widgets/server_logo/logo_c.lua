--------------
-- Includes --
--------------

#include "../../include/serv_verification.lua"
#include "../../include/widgets.lua"

-----------------
-- Definitions --
-----------------

local SERVER_WEBSITE = "toxic.no-ip.eu"

---------------------
-- Local variables --
---------------------

local g_Root = getRootElement ()
local g_Me = getLocalPlayer ()
local g_ScreenSize = { guiGetScreenSize () }
local g_ScreenSizeSqrt = { g_ScreenSize[1]^(1/2), g_ScreenSize[2]^(1/2) }
local g_Size, g_Pos = false, false -- set in WG_RESET
local g_Visible = false
local g_Textures = {}
local g_TexSize = false
local g_Start = getTickCount ()
local g_WidgetCtrl = {}
local g_WidgetName = {"Server logo", pl = "Logo serwera"}

---------------------------------
-- Local function declarations --
---------------------------------

local function render ()
	if(not g_Shader) then return end
	
	local a = math.fmod ( ( getTickCount () - g_Start ) / 2000, 2 * math.pi )
	
	local w, h = g_Size[1], g_Size[2]
	local x, y = g_Pos[1], g_Pos[2]
	
	dxSetShaderValue ( g_Shader, "g_Pos", x + w/2, y + h/2 )
	dxSetShaderValue ( g_Shader, "g_ScrSize", g_ScreenSize[1], g_ScreenSize[2] )
	
	if ( a < math.pi ) then
		dxSetShaderValue ( g_Shader, "g_Texture", g_Textures.front )
		dxSetShaderValue ( g_Shader, "g_fAngle", math.pi/2 - a )
	else
		dxSetShaderValue ( g_Shader, "g_Texture", g_Textures.back )
		dxSetShaderValue ( g_Shader, "g_fAngle", math.pi/2 - a + math.pi )
	end
	
	--dxDrawRectangle ( x, y, w, h, 0xFF000000 )
	dxDrawImage ( x, y, w, h, g_Shader )
end

g_WidgetCtrl[$(wg_show)] = function ( visible )
	if ( g_Visible == visible ) then return end
	g_Visible = visible
	
	if ( g_Visible ) then
		addEventHandler ( "onClientRender", g_Root, render )
		
		g_Textures.back = dxCreateTexture("back.jpg")
		g_Shader = dxCreateShader("logo.fx")
		
	elseif ( not visible ) then
		removeEventHandler ( "onClientRender", g_Root, render )
		
		destroyElement(g_Textures.back)
		destroyElement(g_Shader)
	end
end

g_WidgetCtrl[$(wg_isshown)] = function ()
	return g_Visible
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
	--g_Size = { g_ScreenSize[2]*0.15, g_ScreenSize[2]*0.15*87/196 }
	g_Size = { g_ScreenSizeSqrt[2]*5, g_ScreenSizeSqrt[2]*5/g_TexSize[1]*g_TexSize[2] }
	--g_Pos = { g_ScreenSize[1]*0.95 - g_Size[1], g_ScreenSize[2]*0.05 }
	g_Pos = { g_ScreenSize[1] - g_ScreenSizeSqrt[2]*3 - 24 - g_Size[1]/2, g_ScreenSize[2]*0.05 }
	
	-- image is visible by default
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
-- Init --
----------

#VERIFY_SERVER_BEGIN ( "01D16B92486D3BBE949B49D5A481BAEE" )
	g_Textures.front = dxCreateTexture ( "logo.jpg" )
	g_TexSize = {dxGetMaterialSize(g_Textures.front)}
	
	g_WidgetCtrl[$(wg_reset)] () -- set pos, size and image
	
	triggerEvent("onRafalhAddWidget", g_Root, getThisResource(), g_WidgetName)
	addEventHandler("onRafalhGetWidgets", g_Root, function()
		triggerEvent("onRafalhAddWidget", g_Root, getThisResource(), g_WidgetName)
	end)
#VERIFY_SERVER_END ()
