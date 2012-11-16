local g_Window, g_Panel, g_Bar
local g_Rating = false
local g_HideTimer = false

addEvent ( "onPlayerRate", true )
addEvent ( "onClientSetRateGuiVisibleReq", true )
addEvent ( "onClientMapStopping" )

local function RtInitGui ()
	local x, y = ( g_ScreenSize[1] - 300 ) / 2 - 205, 5
	g_Window = guiCreateWindow ( x, y, 300, 80, "Rate this map", false )
	g_Panel = guiCreateLabel ( x + 5, y + 15, 290, 80 - 20, "", false )
	guiSetVisible ( g_Window, false )
	guiWindowSetMovable ( g_Window, false )
	guiWindowSetSizable ( g_Window, false )
	
	guiCreateLabel ( 0, 5, 290, 20, "Press 0-9 to rate this map", false, g_Panel )
	
	local rafalh_shared = getResourceFromName ( "rafalh_shared" )
	if ( rafalh_shared ) then
		g_Bar = call ( rafalh_shared, "createAnimatedProgressBar", 0, 30, 290, 20, false, false, false, g_Panel )
	end
	
	if ( not g_Bar ) then
		g_Bar = guiCreateProgressBar ( 0, 30, 290, 20, false, g_Panel )
	end
	guiSetVisible ( g_Bar, false )
end

local function RtUpdateBar ()
	if ( g_Bar and g_Rating ) then
		local rafalh_shared = getResourceFromName ( "rafalh_shared" )
		if ( getElementType ( g_Bar ) == "gui-progressbar" ) then
			guiProgressBarSetProgress ( g_Bar, g_Rating * 10 )
		elseif ( rafalh_shared ) then
			call ( rafalh_shared, "setAnimatedProgressBarProgress", g_Bar, g_Rating * 10, 500 )
		end
		guiSetVisible ( g_Bar, true )
	end
end

local function RtKeyUp ( key )
	if ( g_Bar ) then
		g_Rating = touint ( key ) + 1
		RtUpdateBar ()
		resetTimer ( g_HideTimer )
	end
end

local function RtSetBinds ( enabled )
	if ( enabled ) then
		for i = 0, 9, 1 do
			bindKey ( tostring ( i ), "up", RtKeyUp )
		end
	else
		for i = 0, 9, 1 do
			unbindKey ( tostring ( i ), "up", RtKeyUp )
		end
	end
end

local function RtDestroyGui ()
	g_Rating = false
	
	RtSetBinds ( false )
	if ( g_Window ) then
		destroyElement ( g_Window )
		destroyElement ( g_Panel )
	end
	g_Window, g_Panel, g_Bar = false, false, false
end

local function RtHideGui ()
	if ( not g_Window ) then return end
	
	if ( not guiGetVisible ( g_Window ) ) then
		return
	end
	
	GaFadeOut ( g_Window, 500, 0 )
	GaFadeOut ( g_Panel, 500, 0 )
	
	if ( g_HideTimer ) then
		killTimer ( g_HideTimer )
		g_HideTimer = false
	end
	
	RtSetBinds ( false )
	if ( g_Rating ) then
		triggerServerEvent ( "onPlayerRate", g_Me, g_Rating )
		g_Rating = false
	end
end

local function RtShowGui ()
	if ( not g_Window ) then
		RtInitGui ()
	end
	
	GaFadeIn ( g_Window, 500, 1 / 3 )
	GaFadeIn ( g_Panel, 500, 1 )
	
	RtSetBinds ( true )
	g_HideTimer = setTimer ( RtHideGui, 15000, 1 )
end

local function RtSetVisible ( visible )
	if ( visible ) then
		RtShowGui ()
	else
		RtHideGui ()
	end
end

local function RtMapStop ()
	RtDestroyGui ()
end

------------
-- Events --
------------

addEventHandler ( "onClientSetRateGuiVisibleReq", g_Root, RtSetVisible )
addEventHandler ( "onClientMapStopping", g_Root, RtMapStop )
