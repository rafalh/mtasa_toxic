--------------
-- Includes --
--------------

#include "..\\include\\serv_verification.lua"

-----------------
-- Definitions --
-----------------

#B_PROGRESS = 1
#B_IMG = 2
#B_LABEL = 3
#B_RESIZE_START = 4
#B_RESIZE_END = 5
#B_RESIZE_CENTER = 6
#B_RESIZE_A = 7

---------------------
-- Local variables --
---------------------

local g_Me = getLocalPlayer ()
local g_Root = getRootElement ()
local g_Bars = {} -- g_Windows[window] = {  }
local g_BarsCount = 0
local g_Verified = false
local DEBUG = false

--------------------------------
-- Local function definitions --
--------------------------------

local function getAnimatedProgressBarDinamicProgress ( bar )
	local data = g_Bars[bar]
	if ( data[$(B_RESIZE_START)] ) then
		local ticks = getTickCount ()
		if ( ticks >= data[$(B_RESIZE_END)] ) then
			g_Bars[bar][$(B_RESIZE_START)] = nil
			return data[$(B_PROGRESS)]
		else
			return ( data[$(B_RESIZE_CENTER)] + data[$(B_RESIZE_A)]*math.sin ( ( ticks - data[$(B_RESIZE_START)] )/( data[$(B_RESIZE_END)] - data[$(B_RESIZE_START)] )*math.pi + math.pi*1.5 ) )*100
		end
	else
		return data[$(B_PROGRESS)]
	end
end

local function onClientPreRender ()
	for bar, data in pairs ( g_Bars ) do
		if ( data[$(B_RESIZE_START)] ) then
			local progress = getAnimatedProgressBarDinamicProgress ( bar )
			guiSetSize ( data[$(B_IMG)], progress/100, 1, true )
			if(data[$(B_LABEL)]) then
				guiSetText ( data[$(B_LABEL)], math.floor ( progress ).."%" )
			end
		end
	end
end

---------------------------------
-- Global function definitions --
---------------------------------

function createAnimatedProgressBar ( x, y, w, h, fg_color, bg_color, relative, parent )
	if ( not g_Verified ) then
		return false
	end
	
	local bar
	if ( type ( fg_color ) == "number" ) then
		return false
	else
		bar = guiCreateStaticImage ( x, y, w, h, bg_color or "img/bar_bg.png", relative, parent )
		g_Bars[bar] = {}
		g_Bars[bar][$(B_IMG)] = guiCreateStaticImage ( 0, 0, 0, 1, fg_color or "img/bar_fg.png", true, bar )
		if(h > 10) then
			g_Bars[bar][$(B_LABEL)] = guiCreateLabel ( 0, 0, 1, 1, "0%", true, bar )
			guiLabelSetHorizontalAlign ( g_Bars[bar][$(B_LABEL)], "center" )
			guiLabelSetVerticalAlign ( g_Bars[bar][$(B_LABEL)], "center" )
			--guiLabelSetColor ( g_Bars[bar][$(B_LABEL)], 255, 255, 255 )
		end
	end
	
	g_Bars[bar][$(B_PROGRESS)] = 0
		
	if ( g_BarsCount == 0 ) then
		addEventHandler ( "onClientPreRender", g_Root, onClientPreRender )
	end
	addEventHandler ( "onClientElementDestroy", bar, function ()
		g_BarsCount = g_BarsCount - 1
		if ( g_BarsCount == 0 ) then
			removeEventHandler ( "onClientPreRender", g_Root, onClientPreRender )
		end
		g_Bars[source] = nil
	end, false )
	
	g_BarsCount = g_BarsCount + 1
	
	return bar
end

function setAnimatedProgressBarProgress ( bar, progress, time )
	assert ( g_Bars[bar] )
	if ( progress == g_Bars[bar][$(B_PROGRESS)] ) then
		return
	end
	time = tonumber ( time ) or 0
	if ( time > 0 ) then
		if ( g_Bars[bar][$(B_RESIZE_START)] ) then
			g_Bars[bar][$(B_PROGRESS)] = getAnimatedProgressBarDinamicProgress ( bar )
		end
		local now = getTickCount ()
		g_Bars[bar][$(B_RESIZE_CENTER)] = ( progress + g_Bars[bar][$(B_PROGRESS)] )/2/100
		g_Bars[bar][$(B_RESIZE_A)] = ( progress - g_Bars[bar][$(B_PROGRESS)] )/2/100
		g_Bars[bar][$(B_RESIZE_START)] = now
		g_Bars[bar][$(B_RESIZE_END)] = now + time
	else
		guiSetSize ( g_Bars[bar][$(B_IMG)], progress/100, 1, true )
		if(g_Bars[bar][$(B_LABEL)]) then
			guiSetText ( g_Bars[bar][$(B_LABEL)], math.floor ( progress ).."%" )
		end
	end
	g_Bars[bar][$(B_PROGRESS)] = progress
end

function getAnimatedProgressBarProgress ( bar )
	assert ( g_Bars[bar] )
	return g_Bars[bar][$(B_PROGRESS)]
end

------------
-- Events --
------------

#VERIFY_SERVER_BEGIN ( "62443A6D1AA2D8A266064C951C92E266" )
	g_Verified = true
	--[[if(DEBUG) then
		local bar = createAnimatedProgressBar(100, 100, 200, 10, false, false, false)
		setAnimatedProgressBarProgress(bar, 34)
	end]]
#VERIFY_SERVER_END ()
