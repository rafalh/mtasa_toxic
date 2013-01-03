--------------
-- Includes --
--------------

#include "..\\include\\serv_verification.lua"

-----------------
-- Definitions --
-----------------

#PALETTE_W = 175
#PALETTE_H = 187

#WND_HUE = 1 -- odcien
#WND_SAT = 2 -- nasycenie
#WND_LUM = 3 -- jasnosc
#WND_PALETTE = 4
#WND_EVENT = 5

---------------------
-- Local variables --
---------------------

local g_Me = getLocalPlayer ()
local g_Root = getRootElement ()
local g_Windows = {} -- g_Windows[window] = { hue, sat, lum, palette, event }
local g_WindowsCount = 0
local g_Verified = false

--------------------------------
-- Local function definitions --
--------------------------------

local function Hue_2_RGB ( v1, v2, vH ) -- helper for hslToRgb
    if ( vH < 0 ) then vH = vH + 1 end
    if ( vH > 1 ) then vH = vH - 1 end
    if ( ( 6 * vH ) < 1 ) then return v1 + ( v2 - v1 ) * 6 * vH end
    if ( ( 2 * vH ) < 1 ) then return v2 end
    if ( ( 3 * vH ) < 2 ) then return v1 + ( v2 - v1 ) * ( ( 2 / 3 ) - vH ) * 6 end
    return v1
end

local function hslToRgb ( hue, sat, lum )
	local r, g, b = 0, 0, 0
	
	-- http://www.easyrgb.com/index.php?X=MATH&H=19#text19
	if ( sat == 0 ) then -- HSL from 0 to 1
		r = lum * 255 -- RGB results from 0 to 255
		g = lum * 255
		b = lum * 255
	else
		local var_2
		if ( lum < 0.5 ) then var_2 = lum * ( 1 + sat )
		else                  var_2 = ( lum + sat ) - ( sat * lum ) end
		
		local var_1 = 2 * lum - var_2
		
		r = 255 * Hue_2_RGB ( var_1, var_2, hue + ( 1 / 3 ) ) 
		g = 255 * Hue_2_RGB ( var_1, var_2, hue )
		b = 255 * Hue_2_RGB ( var_1, var_2, hue - ( 1 / 3 ) )
	end
	return r, g, b
end

local function rgbToHsl ( r, g, b )
	local hue, sat, lum = 0, 0, 0
	
	-- http://www.easyrgb.com/index.php?X=MATH&H=18#text18
	local var_R = ( r / 255 ) -- RGB from 0 to 255
	local var_G = ( g / 255 )
	local var_B = ( b / 255 )

	local var_Min = math.min ( var_R, var_G, var_B ) -- Min. value of RGB
	local var_Max = math.max ( var_R, var_G, var_B ) -- Max. value of RGB
	local del_Max = var_Max - var_Min                -- Delta RGB value

	lum = ( var_Max + var_Min ) / 2

	if ( del_Max == 0 ) then -- This is a gray, no chroma...
		hue = 0              -- HSL results from 0 to 1
		sat = 0
	else                     -- Chromatic data...
		if ( lum < 0.5 ) then sat = del_Max / ( var_Max + var_Min )
		else                  sat = del_Max / ( 2 - var_Max - var_Min ) end

		del_R = ( ( ( var_Max - var_R ) / 6 ) + ( del_Max / 2 ) ) / del_Max
		del_G = ( ( ( var_Max - var_G ) / 6 ) + ( del_Max / 2 ) ) / del_Max
		del_B = ( ( ( var_Max - var_B ) / 6 ) + ( del_Max / 2 ) ) / del_Max

	   if     ( var_R == var_Max ) then hue = del_B - del_G
	   elseif ( var_G == var_Max ) then hue = ( 1 / 3 ) + del_R - del_B
	   elseif ( var_B == var_Max ) then hue = ( 2 / 3 ) + del_G - del_R end

		if     ( hue < 0 ) then hue = hue + 1
		elseif ( hue > 1 ) then hue = hue - 1 end
	end
	
	--outputDebugString ( ("#%02x%02x%02x -> %u %u %u" ):format ( r, g, b, hue, sat, lum ), 3 )
	return hue, sat, lum
end

local function onClientRender ()
	for wnd, wnd_data in pairs ( g_Windows ) do
		local x, y = guiGetPosition ( wnd, false )
		
		local i = 0
		for i = 0, 31, 1 do
			local r, g, b = hslToRgb ( wnd_data[$(WND_HUE)], wnd_data[$(WND_SAT)], 1-i/31 )
			local clr = tocolor ( r, g, b )
			dxDrawRectangle ( x+$(PALETTE_W)+20, y+20+(i/32)*$(PALETTE_H), 15, $(PALETTE_H)/32+1, clr, true )
		end
		
		local r, g, b = hslToRgb ( wnd_data[$(WND_HUE)], wnd_data[$(WND_SAT)], wnd_data[$(WND_LUM)] )
		
		dxDrawRectangle ( x+10, y+30+$(PALETTE_H), 65, 20, tocolor ( r, g, b ), true )
		
		local clrX = x+10+wnd_data[$(WND_HUE)]*$(PALETTE_W)
		local clrY = y+20+(1-wnd_data[$(WND_SAT)])*$(PALETTE_H)
		dxDrawLine ( clrX-5, clrY, clrX+5, clrY, tocolor ( 0, 0, 0 ), 2, true )
		dxDrawLine ( clrX, clrY-5, clrX, clrY+5, tocolor ( 0, 0, 0 ), 2, true )
		
		local lum_x = x+$(PALETTE_W) + 20
		local lum_y = y + 20 + $(PALETTE_H)*(1-wnd_data[$(WND_LUM)])
		local lum_clr = wnd_data[$(WND_LUM)] > 0.2 and tocolor ( 0, 0, 0 ) or tocolor ( 255, 255, 255 )
		dxDrawLine ( lum_x, lum_y, lum_x + 15, lum_y, lum_clr, 2, true )
	end
end

local function onClientMouseMove ( x, y )
	local wnd = ( g_Windows[source] and source ) or getElementParent ( source )
	local wnd_data = g_Windows[wnd]
	
	if ( not wnd_data[$(WND_PALETTE)] ) then return end
	
	local wndX, wndY = guiGetPosition ( wnd, false )
	x = x - wndX
	y = y - wndY
	
	if ( wnd_data[$(WND_PALETTE)] == 1 ) then
		if ( x <= 10 ) then wnd_data[$(WND_HUE)] = 0
		elseif ( x > 10+$(PALETTE_W) ) then wnd_data[$(WND_HUE)] = 1
		else wnd_data[$(WND_HUE)] = (x-10)/$(PALETTE_W) end
		
		if ( y <= 20 ) then wnd_data[$(WND_SAT)] = 1
		elseif ( y > 20+$(PALETTE_H) ) then wnd_data[$(WND_SAT)] = 0
		else wnd_data[$(WND_SAT)] = 1-(y-20)/$(PALETTE_H) end
	elseif ( wnd_data[$(WND_PALETTE)] == 2 ) then
		if ( y <= 20 ) then wnd_data[$(WND_LUM)] = 1
		elseif ( y > 20+$(PALETTE_H) ) then wnd_data[$(WND_LUM)] = 0
		else wnd_data[$(WND_LUM)] = 1-(y-20)/$(PALETTE_H) end
	end
end

local function onClientGUIMouseDown ( button, x, y )
	local wnd = ( g_Windows[source] and source ) or getElementParent ( source )
	local wnd_data = g_Windows[wnd]
	local wndX, wndY = guiGetPosition ( wnd, false )
	local x2, y2 = x-wndX, y-wndY
	
	if ( x2 >= 10 and y2 >= 20 and x2 < 10+$(PALETTE_W) and y2 < 20+$(PALETTE_H) ) then
		wnd_data[$(WND_PALETTE)] = 1
		onClientMouseMove ( x, y )
	elseif ( x2 >= $(PALETTE_W)+20 and y2 >= 20 and x2 < $(PALETTE_W)+35 and y2 < 20+$(PALETTE_H) ) then
		wnd_data[$(WND_PALETTE)] = 2
		onClientMouseMove ( x, y )
	else
		wnd_data[$(WND_PALETTE)] = false
	end
end

local function onClientClick ( btn, state )
	if ( state == "up" ) then
		for wnd, wnd_data in pairs ( g_Windows ) do
			wnd_data[$(WND_PALETTE)] = false
		end
	end
end

local function onClientResourceStop ()
	for wnd, wnd_data in pairs ( g_Windows ) do
		triggerEvent ( wnd_data[$(WND_EVENT)], wnd, false )
	end
end

---------------------------------
-- Global function definitions --
---------------------------------

function createColorDlg ( event_name, r, g, b )
	if ( not g_Verified ) then
		return false
	end
	
	addEvent ( event_name )
	
	if ( not r or not g or not b ) then
		r, g, b = 255, 0, 0
	end
	local hue, sat, lum = rgbToHsl ( r, g, b )
	--r, g, b = calcColor ( hue, sat ) -- fixme
	
	local w, h = guiGetScreenSize ()
	local wnd = guiCreateWindow ( (w-$(PALETTE_W)-45)/2, (h-$(PALETTE_H)-60)/2, $(PALETTE_W)+45, $(PALETTE_H)+60, "Color", false )
	g_Windows[wnd] = { hue, sat, lum, false, event_name } -- { hue, sat, lum, palette, event }
	
	guiWindowSetMovable ( wnd, true )
	guiWindowSetSizable ( wnd, false )
	
	local btn = guiCreateButton ( $(PALETTE_W)-90, $(PALETTE_H)+30, 60, 20, "OK", false, wnd )
	addEventHandler ( "onClientGUIClick", btn, function ()
		local wnd = getElementParent ( source )
		local wnd_data = g_Windows[wnd]
		local r, g, b = hslToRgb ( wnd_data[$(WND_HUE)], wnd_data[$(WND_SAT)], wnd_data[$(WND_LUM)] )
		
		triggerEvent ( wnd_data[$(WND_EVENT)], wnd, r, g, b )
		destroyElement ( wnd )
	end, false )
	btn = guiCreateButton ( $(PALETTE_W)-20, $(PALETTE_H)+30, 60, 20, "Cancel", false, wnd )
	addEventHandler ( "onClientGUIClick", btn, function ()
		local wnd = getElementParent ( source )
		triggerEvent ( g_Windows[wnd][$(WND_EVENT)], wnd, false )
		destroyElement ( wnd )
	end, false )
	
	guiCreateStaticImage ( 10, 20, $(PALETTE_W), $(PALETTE_H), "img/palette.jpg", false, wnd )
	
	addEventHandler ( "onClientMouseMove", wnd, onClientMouseMove )
	addEventHandler ( "onClientGUIMouseDown", wnd, onClientGUIMouseDown )
	if ( g_WindowsCount == 0 ) then
		addEventHandler ( "onClientClick", g_Root, onClientClick )
		addEventHandler ( "onClientRender", g_Root, onClientRender )
	end
	addEventHandler ( "onClientElementDestroy", wnd, function ()
		g_WindowsCount = g_WindowsCount - 1
		if ( g_WindowsCount == 0 ) then
			removeEventHandler ( "onClientClick", g_Root, onClientClick )
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
