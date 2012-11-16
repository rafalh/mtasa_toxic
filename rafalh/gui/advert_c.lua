
#include "include/internal_events.lua"

local g_Adverts = {}
local g_AdvertIdx = 0
local g_Visible = false

-- Settings
local g_TextColor = tocolor ( 0, 255, 0 )
local g_TextFont = "bankgothic"
local g_TextScale = 0.6
local g_BgColor = tocolor ( 16, 16, 16, 128 )
local g_VisibleTime = 10000
local g_Speed = 200
local g_AppearingTime = 500
local g_AdvertInternal = 120000

local function AdvRender ()
	local ticks = getTickCount ()
	local dt = ticks - g_Visible
	
	local text = g_Adverts[g_AdvertIdx]
	local text_w = dxGetTextWidth ( text, g_TextScale, g_TextFont )
	local w, h = g_ScreenSize[1], dxGetFontHeight ( g_TextScale, g_TextFont )
	local h_fact = 1
	local visible_time = ( w + text_w ) / g_Speed * 1000
	
	if ( dt > visible_time ) then
		g_Visible = false
		removeEventHandler ( "onClientRender", g_Root, AdvRender )
		return
	elseif ( dt < g_AppearingTime ) then
		h_fact = dt / g_AppearingTime
	elseif ( dt > visible_time - g_AppearingTime ) then
		h_fact = ( visible_time - dt ) / g_AppearingTime
	end
	
	local y = - h * ( 1 - h_fact )
	local h = h * h_fact
	dxDrawRectangle ( 0, 0, w, h, g_BgColor, true )
	
	
	if ( getVersion ().sortable < "1.3.0-9.03986.0" ) then
		text = text:gsub ( "#%x%x%x%x%x%x", "" )
	end
	
	local x = w - dt * g_Speed / 1000
	dxDrawText ( text, x, y, x, y, g_TextColor, g_TextScale, g_TextFont, "left", "top", false, false, true, true )
end

local function AdvShowNext ()
	if ( not g_Visible ) then
		addEventHandler ( "onClientRender", g_Root, AdvRender )
	end
	
	g_Visible = getTickCount ()
	g_AdvertIdx = g_AdvertIdx + 1
	if ( g_AdvertIdx > #g_Adverts ) then
		g_AdvertIdx = 1
	end
	
	outputConsole ( g_Adverts[g_AdvertIdx]:gsub ( "#%x%x%x%x%x%x", "" ) )
end

local function AdvInit ()
	local tmp = {}
	local node, i = xmlLoadFile ( "conf/adverts.xml" ), 0
	if ( node ) then
		while ( true ) do
			local subnode = xmlFindChild ( node, "advert", i )
			if ( not subnode ) then break end
			
			local attr = xmlNodeGetAttributes ( subnode )
			
			local advert = {}
			advert.freq = touint ( attr.freq, 1 )
			if ( attr[g_Settings.lang] ) then
				advert.text = attr[g_Settings.lang]
			else
				advert.text = xmlNodeGetValue ( subnode )
			end
			
			table.insert ( tmp, advert )
			i = i + 1
		end
		xmlUnloadFile ( node )
	end
	
	table.sort ( tmp, function ( a, b ) return a.freq < b.freq end )
	
	for i, advert in ipairs ( tmp ) do
		for j = 1, advert.freq, 1 do
			table.insert ( g_Adverts, math.floor ( #g_Adverts * j / advert.freq ) + 1, advert.text )
		end
	end
	
	if ( #g_Adverts > 0 ) then
		g_AdvertIdx = math.random ( 0, #g_Adverts )
		setTimer ( AdvShowNext, g_AdvertInternal, 0 )
		--AdvShowNext ()
	end
end

addInternalEventHandler ( $(EV_CLIENT_INIT), AdvInit )
