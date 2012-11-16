--------------
-- Includes --
--------------

#include "include/internal_events.lua"

---------------------
-- Local variables --
---------------------

local g_Window, g_Panel = false, false
local g_MapName = ""
local g_Played, g_Rating, g_RatesCount = 0, 0, 0
local g_Toptimes = {}
local g_HideTimer = false

--------------------------------
-- Local function definitions --
--------------------------------

local function hideTopTimes ()
	if ( g_HideTimer ) then
		killTimer ( g_HideTimer )
		g_HideTimer = false
	end
	
	if ( not g_Window ) then
		return
	end
	
	GaFadeOut ( g_Window, 500 )
	GaFadeOut ( g_Panel, 500 )
end

local function showTopTimes ()
	if ( not g_Window ) then
		return
	end
	GaFadeIn ( g_Window, 500, 1/3 )
	GaFadeIn ( g_Panel, 500, 1 )
	g_HideTimer = setTimer ( hideTopTimes, 15000, 1 )
end

local function keyUpHandler ()
	if ( guiGetVisible ( g_Window ) ) then
		hideTopTimes ()
	else
		showTopTimes ()
	end
end

local function setupMapInfoPanel ( map_name, author, played, rating, rates_count, toptimes )
	local a = 0
	if ( g_Panel ) then
		a = guiGetAlpha ( g_Panel )
		destroyElement ( g_Panel )
	end
	
	local x, y = g_ScreenSize[1] / 2 + 64, 5
	local w, h = 300, 95 + #toptimes * 14 + math.min ( #toptimes, 1 ) * 35
	guiSetSize ( g_Window, w, h, false )
	g_Panel = guiCreateLabel ( x + 5, y + 15, w - 10, h - 20, "", false )
	
	local label = guiCreateLabel ( 5, 5, w - 20, 15, MuiGetMsg ( "Map: %s" ):format ( map_name ), false, g_Panel )
	guiSetFont ( label, "default-bold-small" )
	if ( not author ) then
		author = MuiGetMsg ( "unknown" )
	end
	guiCreateLabel ( 5, 20, w - 20, 15, MuiGetMsg ( "Author: %s" ):format ( author ), false, g_Panel )
	guiCreateLabel ( 5, 35, w - 20, 15, MuiGetMsg ( "Played: %u times" ):format ( played ), false, g_Panel )
	
	guiCreateLabel ( 5, 50, 50, 15, "Rating:", false, g_Panel )
	for i = 0, 4, 1 do
		if(i*2 < rating and rating <= i*2 + 1) then
			-- half star
			guiCreateStaticImage(55 + i*16, 50, 8, 16, "img/star_l.png", false, g_Panel)
			local star_r = guiCreateStaticImage(55 + i*16 + 8, 50, 8, 16, "img/star_r.png", false, g_Panel)
			guiSetAlpha(star_r, 0.3)
		else
			-- full star
			local star = guiCreateStaticImage(55 + i*16, 50, 16, 16, "img/star.png", false, g_Panel)
			if(rating <= i*2) then
				guiSetAlpha(star, 0.3)
			end
		end
	end
	guiCreateLabel ( 60 + 5*16, 50, w - 60 - 5*16, 15, MuiGetMsg ( "(%u rates)" ):format ( rates_count ), false, g_Panel )
	
	if ( #toptimes > 0 ) then
		guiCreateLabel ( 5, 70, w - 20, 15, "Top Times:", false, g_Panel )
		
		guiCreateLabel ( 5, 85, 35, 15, "Pos", false, g_Panel )
		guiCreateLabel ( 40, 85, 75, 15, "Time", false, g_Panel )
		guiCreateLabel ( 115, 85, w - 135, 15, "Player", false, g_Panel )
		
		guiCreateLabel ( 5, 90, w - 20, 15, "_____________________________________________", false, g_Panel )
		
		for i, data in ipairs ( toptimes ) do
			local y = 90 + i * 14
			
			local pos = guiCreateLabel ( 5, y, 35, 15, tostring ( i ), false, g_Panel )
			local tm = guiCreateLabel ( 40, y, 75, 15, data.time, false, g_Panel )
			local name = guiCreateLabel ( 115, y, w - 135, 15, data.name, false, g_Panel )
			
			guiSetFont ( pos, "default-bold-small" )
			guiSetFont ( tm, "default-bold-small" )
			guiSetFont ( name, "default-bold-small" )
			
			if ( data.player == g_MyId ) then
				guiLabelSetColor ( pos, 180, 255, 255 )
				guiLabelSetColor ( tm, 180, 255, 255 )
				guiLabelSetColor ( name, 180, 255, 255 )
			end
		end
	end
	
	-- Set panel alpha here because of bug in guiCreateStaticImage
	guiSetAlpha ( g_Panel, a )
end

local function onClientInit ()
	g_Window = guiCreateWindow ( g_ScreenSize[1]/2+64, 5, 300, 165, "Map Info", false )
	guiSetVisible ( g_Window, false )
	guiWindowSetMovable ( g_Window, false )
	guiWindowSetSizable ( g_Window, false )
	
	setupMapInfoPanel ( "", "", 0, 0, 0, {} )
	guiSetVisible ( g_Panel, false )
	guiSetAlpha ( g_Panel, 0 )
	bindKey ( "f5", "up", keyUpHandler )
end

local function onClientMapInfo ( show, name, author, played, rating, rates_count, toptimes )
	g_MapName, g_Author, g_Played, g_Rating, g_RatesCount, g_Toptimes = name, author, played, rating, rates_count, toptimes
	setupMapInfoPanel ( name, author, played, rating, rates_count, toptimes )
	if ( show ) then
		showTopTimes ()
		if ( g_HideTimer ) then
			resetTimer ( g_HideTimer )
		end
	end
end

local function onClientChangeGuiLang ()
	if ( g_Window ) then
		setupMapInfoPanel ( g_MapName, g_Author, g_Played, g_Rating, g_RatesCount, g_Toptimes )
	end
end

------------
-- Events --
------------

addInternalEventHandler ( $(EV_CLIENT_INIT), onClientInit )
addInternalEventHandler ( $(EV_CLIENT_MAP_INFO), onClientMapInfo )
addEventHandler ( "onClientLangChanged", g_ResRoot, onClientChangeGuiLang )
