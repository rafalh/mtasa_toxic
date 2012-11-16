--------------
-- Includes --
--------------

#include "include/internal_events.lua"

---------------------
-- Local variables --
---------------------

local g_StatFields = {
	{ "name", "Player" },
	{ "cash", "Cash", formatMoney },
	{ "points", "Points", formatNumber },
	{ "_rank", "Rank" },
	{ "dm", "DD/DM Played", formatNumber },
	{ "dm_wins", "DD/DM Wins", formatNumber },
	{ "first", "Race - 1st", formatNumber, "%s times" },
	{ "second", "Race - 2nd", formatNumber, "%s times" },
	{ "third", "Race - 3rd", formatNumber, "%s times" },
	{ "toptimes_count", "Top Times held" },
	{ "bidlvl", "Bidlevel" },
	{ "exploded", "Exploded", formatNumber, "%s times" },
	{ "drowned", "Drowned", formatNumber, "%s times" },
	{ "_time_here", "Playtime" }
}
local g_Gui = {}
local g_Timer = nil
local g_Stats = {}

local StatsPanel = {
	name = "Statistics",
	img = "img/userpanel/stats.png",
	width = 230,
	height = 260,
}

--------------------------------
-- Local function definitions --
--------------------------------

local function StUpdatePlaytime ()
	local now = getRealTime ().timestamp
	for parent, gui in pairs ( g_Gui ) do
		local play_time = g_Stats[gui.id] and g_Stats[gui.id].time_here
		if ( play_time ) then
			local join_time = g_Stats[gui.id] and g_Stats[gui.id]._join_time
			if ( join_time ) then
				play_time = now - join_time + play_time
			end
			guiSetText ( gui._time_here, formatTimePeriod ( play_time, 0 ) )
		end
	end
end

local function StUpdateGui ( id )
	-- update playtime
	StUpdatePlaytime ()
	
	-- update rest
	for parent, gui in pairs ( g_Gui ) do
		if ( gui.id == id ) then
			for i, data in ipairs ( g_StatFields ) do
				local val = g_Stats[id] and g_Stats[id][data[1]]
				if ( val ) then
					if ( data[3] ) then
						val = data[3] ( val )
					end
					if ( data[4] ) then
						val = MuiGetMsg ( data[4] ):format ( val )
					end
					guiSetText ( gui[data[1]], val )
				end
			end
		end
	end
end

function StCreateGui ( id, parent, x, y, w, h )
	if ( not g_Gui[parent] ) then
		g_Gui[parent] = { id = id }
		local gui = g_Gui[parent]
		
		for i, field in ipairs ( g_StatFields ) do
			guiCreateLabel ( x, y, 120, 15, field[2]..":", false, parent )
			gui[field[1]] = guiCreateLabel ( x + 120, y, w - 120, 15, "-", false, parent )
			y = y + 15
		end
		
		if ( id == g_MyId ) then
			local player_name = getPlayerName ( g_Me ):gsub ( "#%x%x%x%x%x%x", "" )
			guiSetText ( gui.name, player_name )
		end
	end
	
	StUpdateGui ( id )
	if ( not g_Timer ) then
		g_Timer = setTimer ( StUpdatePlaytime, 1000, 0 )
	end
end

function StDestroyGui ( parent )
	if ( not g_Gui[parent] ) then return end
	
	StHideGui ( parent )
	
	local id = g_Gui[parent].id
	if ( id ~= g_MyId and g_Stats[id].refs == 0 ) then
		g_Stats[id] = nil
	end
	
	g_Gui[parent] = nil
end

function StShowGui ( parent )
	if ( not g_Gui[parent] ) then return end
	
	local id = g_Gui[parent].id
	local force = false
	
	if ( not g_Stats[id] ) then
		g_Stats[id] = { refs = 0 }
		force = true
	end
	
	if ( g_Stats[id].refs == 0 ) then
		triggerServerInternalEvent ( $(EV_START_SYNC_REQUEST), g_Me, { stats = id }, force )
	end
	g_Stats[id].refs = g_Stats[id].refs + 1
end

function StHideGui ( parent )
	if ( not g_Gui[parent] ) then return end
	
	local id = g_Gui[parent].id
	
	g_Stats[id].refs = g_Stats[id].refs - 1
	if ( g_Stats[id].refs == 0 ) then
		triggerServerInternalEvent ( $(EV_PAUSE_SYNC_REQUEST), g_Me, { stats = id } )
	end
end

function StatsPanel.onShow ( tab )
	local w, h = guiGetSize ( tab, false )
	StCreateGui ( g_MyId, tab, 10, 10, w - 20, h - 20 )
	StShowGui ( tab )
end

function StatsPanel.onHide ( tab )
	StHideGui ( tab )
end

local function onClientPlayerChangeNick ( oldNick, newNick )
	if ( source == g_Me and g_Gui and not wasEventCancelled () ) then
		local player_name = newNick:gsub ( "#%x%x%x%x%x%x", "" )
		for tab, gui in pairs ( g_Gui ) do
			if ( gui.id == g_MyId ) then
				guiSetText ( gui.name, player_name )
			end
		end
	end
end

local function onClientSync ( sync_tbl )
	-- is it stats sync?
	if ( not sync_tbl.stats ) then return end
	
	-- check id
	local id = sync_tbl.stats[1]
	if ( not g_Stats[id] and id ~= g_MyId ) then return end
	
	-- create table if not exists
	if ( not g_Stats[id] ) then
		g_Stats[id] = { refs = 0 }
	end
	
	-- update stats
	for field, val in pairs ( sync_tbl.stats[2] ) do
		g_Stats[id][field] = val
	end
	
	StUpdateGui ( id )
end

local function StClosePlayerInfo ()
	-- source = btn
	guiSetEnabled ( source, false )
	local wnd = getElementParent ( source )
	GaFadeOut ( wnd, 200 )
	setTimer ( destroyElement, 200, 1, wnd )
end

local function StDestroyPlayerInfo ()
	StDestroyGui ( source )
end

function StCreatePlayerInfoWnd ( id )
	local w, h = 300, 80 + #g_StatFields * 15
	local x, y = ( g_ScreenSize[1] - w ) / 2, ( g_ScreenSize[2] - h ) / 2
	local wnd = guiCreateWindow ( x, y, w, h, "Player Info", false )
	guiSetVisible ( wnd, false )
	addEventHandler ( "onClientElementDestroy", wnd, StDestroyPlayerInfo, false )
	
	StCreateGui ( id, wnd, 10, 25, 280, h - 45 )
	
	local btn = guiCreateButton ( w - 60, h - 35, 50, 25, "Close", false, wnd )
	addEventHandler ( "onClientGUIClick", btn, StClosePlayerInfo, false )
	
	StShowGui ( wnd )
	GaFadeIn ( wnd, 200 )
	return wnd
end

----------------------
-- Global variables --
----------------------

table.insert ( g_StatsPanelTabs, { "Statistics", StatsPanel.onShow, StatsPanel.onHide } )
UpRegister ( StatsPanel )

------------
-- Events --
------------

addEventHandler ( "onClientPlayerChangeNick", g_Root, onClientPlayerChangeNick )
addInternalEventHandler ( $(EV_SYNC), onClientSync )
