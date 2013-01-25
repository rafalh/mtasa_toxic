--------------
-- Includes --
--------------

#include "include/internal_events.lua"

---------------------
-- Local variables --
---------------------

local g_StatFields = {
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

local function StUpdatePlaytime()
	local now = getRealTime().timestamp
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

local function StUpdateGui(id)
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

function StGetHeight()
	return #g_StatFields * 15
end

function StCreateGui(id, parent, x, y, w, h)
	if ( not g_Gui[parent] ) then
		g_Gui[parent] = { id = id }
		local gui = g_Gui[parent]
		
		for i, field in ipairs ( g_StatFields ) do
			guiCreateLabel ( x, y, 120, 15, field[2]..":", false, parent )
			gui[field[1]] = guiCreateLabel ( x + 120, y, w - 120, 15, "-", false, parent )
			y = y + 15
		end
	end
	
	StUpdateGui ( id )
	if ( not g_Timer ) then
		g_Timer = setTimer ( StUpdatePlaytime, 1000, 0 )
	end
end

function StDestroyGui(parent)
	if ( not g_Gui[parent] ) then return end
	
	StHideGui ( parent )
	
	local id = g_Gui[parent].id
	if ( id ~= g_MyId and g_Stats[id].refs == 0 ) then
		g_Stats[id] = nil
	end
	
	g_Gui[parent] = nil
end

function StShowGui(parent)
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

function StHideGui(parent)
	if ( not g_Gui[parent] ) then return end
	
	local id = g_Gui[parent].id
	
	g_Stats[id].refs = g_Stats[id].refs - 1
	if ( g_Stats[id].refs == 0 ) then
		triggerServerInternalEvent ( $(EV_PAUSE_SYNC_REQUEST), g_Me, { stats = id } )
	end
end

function StatsPanel.onShow(panel)
	local w, h = guiGetSize(panel, false)
	StCreateGui(g_MyId, panel, 10, 10, w - 20, h - 20)
	StShowGui(panel)
end

function StatsPanel.onHide(panel)
	StHideGui(panel)
end

local function onSync ( sync_tbl )
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

----------------------
-- Global variables --
----------------------

table.insert(g_StatsPanelTabs, {"Statistics", StatsPanel.onShow, StatsPanel.onHide})
UpRegister(StatsPanel)

------------
-- Events --
------------

addInternalEventHandler($(EV_SYNC), onSync)
