--------------
-- Includes --
--------------

#include "../../include/serv_verification.lua"
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

---------------------------------
-- Local function declarations --
---------------------------------

local onClientRender
local onClientResourceStart

--------------------------------
-- Local function definitions --
--------------------------------

g_Digits = {
	[0] = { true,  true,  true,  false, true,  true,  true  },
	[1] = { false, false, false, false, false, true,  true  },
	[2] = { false, true,  true,  true,  true,  true,  false },
	[3] = { false, false, true,  true,  true,  true,  true  },
	[4] = { true,  false, false, true,  false, true,  true  },
	[5] = { true,  false, true,  true,  true,  false, true  },
	[6] = { true,  true,  true,  true,  true,  false, true  },
	[7] = { false, false, true,  false, false, true,  true  },
	[8] = { true,  true,  true,  true,  true,  true,  true  },
	[9] = { true,  false, true,  true,  true,  true,  true  }
}

drawDigit = function ( n, x, y, w, h, clr )
	local digit = g_Digits[n]
	local line_w = ( w + h )/20
	
	if ( digit[1] ) then dxDrawLine ( x, y + line_w/4, x, y + h/2 - line_w/4, clr, line_w ) end
	if ( digit[2] ) then dxDrawLine ( x, y + h/2 + line_w/4, x, y + h -  line_w/4, clr, line_w ) end
	if ( digit[3] ) then dxDrawLine ( x + line_w/4, y, x + w -  line_w/4, y, clr, line_w ) end
	if ( digit[4] ) then dxDrawLine ( x + line_w/4, y + h/2, x + w - line_w/4, y + h/2, clr, line_w ) end
	if ( digit[5] ) then dxDrawLine ( x + line_w/4, y + h, x + w - line_w/4, y + h, clr, line_w ) end
	if ( digit[6] ) then dxDrawLine ( x + w, y + line_w/4, x + w, y + h/2 - line_w/4, clr, line_w ) end
	if ( digit[7] ) then dxDrawLine ( x + w, y + h/2 + line_w/4, x + w, y + h - line_w/4, clr, line_w ) end
end

onClientRender = function ()
	local tm = getRealTime ()
	local x, y = g_Pos[1] + g_Size[1]/2, g_Pos[2] + g_Size[2]/2
	
	-- border
	--dxDrawLine ( g_Pos[1], g_Pos[2], g_Pos[1] + g_Size[1], g_Pos[2], tocolor ( 196, 196, 196 ), 1 )
	--dxDrawLine ( g_Pos[1] + g_Size[1], g_Pos[2], g_Pos[1] + g_Size[1], g_Pos[2] + g_Size[2], tocolor ( 64, 64, 64 ), 1 )
	--dxDrawLine ( g_Pos[1] + g_Size[1], g_Pos[2] + g_Size[2], g_Pos[1], g_Pos[2] + g_Size[2], tocolor ( 64, 64, 64 ), 1 )
	--dxDrawLine ( g_Pos[1], g_Pos[2] + g_Size[2], g_Pos[1], g_Pos[2], tocolor ( 196, 196, 196 ), 1 )
	dxDrawRectangle ( g_Pos[1], g_Pos[2], g_Size[1], g_Size[2], tocolor ( 0, 0, 0, 64 ) )
	
	local buf = ( "%2u:%02u:%02u" ):format ( tm.hour, tm.minute, tm.second )
	local w = g_Size[1]/( 6 + 4 )
	local x = g_Pos[1] + w/6
	local pt_size = ( w + g_Size[2]*8/10 )/20
	
	for i = 1, buf:len (), 1 do
		local c = buf:sub ( i, i )
		if ( c == ":" ) then
			x = x + w*1.5/5
			if ( tm.second%2 == 0 ) then
				dxDrawRectangle ( x - pt_size/2, g_Pos[2] + g_Size[2]/3 - pt_size/2, pt_size, pt_size, tocolor ( 0, 255, 0 ) )
				dxDrawRectangle ( x - pt_size/2, g_Pos[2] + g_Size[2]*2/3 - pt_size/2, pt_size, pt_size, tocolor ( 0, 255, 0 ) )
			end
			x = x + w*1.5/5
		else
			local n = tonumber ( c )
			if ( n ) then
				drawDigit ( n, x + w/5, g_Pos[2] + g_Size[2]/10, w, g_Size[2]*8/10, tocolor ( 0, 255, 0 ) )
			end
			x = x +	w*7/5
		end
	end
	--dxDrawRectangle ( g_Pos[1] + g_Size[1]*1/12 - 0.5, y - 0.5, 2, 2 )
	--dxDrawRectangle ( g_Pos[1] + g_Size[1]*11/12 - 0.5, y - 0.5, 2, 2 )
	
end

g_WidgetCtrl[$(wg_show)] = function ( b )
	if ( ( g_Show and b ) or ( not g_Show and not b ) ) then return end
	g_Show = b
	if ( b ) then
		addEventHandler ( "onClientRender", g_Root, onClientRender )
	else
		removeEventHandler( "onClientRender", g_Root, onClientRender )
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

#VERIFY_SERVER_BEGIN ( "4704A166BC367AA476EEEEC632C4933A" )
	g_WidgetCtrl[$(wg_reset)] () -- reset pos, size, visiblity
	triggerEvent ( "onRafalhAddWidget", g_Root, getThisResource (), "Digital clock" )
	addEventHandler ( "onRafalhGetWidgets", g_Root, function ()
		triggerEvent ( "onRafalhAddWidget", g_Root, getThisResource (), "Digital clock" )
	end )
#VERIFY_SERVER_END ()
