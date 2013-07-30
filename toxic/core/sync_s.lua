--------------
-- Includes --
--------------

#include 'include/internal_events.lua'

---------------------
-- Local variables --
---------------------

-- g_Sync[name].func - function
-- g_Sync[name].data[arg].t = last modification time
-- g_Sync[name].data[arg].p[player] = if sync paused last sync time, else 0
local g_Sync = {}

--------------------------------
-- Local function definitions --
--------------------------------

local function onPlayerQuit ()
	for name, syncer in pairs ( g_Sync ) do
		for arg, el_data in pairs ( syncer.data ) do
			el_data.p[source] = nil -- remove player from all sync tables
			if ( table.empty ( el_data.p ) ) then
				syncer.data[arg] = nil
			end
		end
	end
end

---------------------------------
-- Global function definitions --
---------------------------------

function addSyncer ( name, func, alwaysupload )
	assert ( name and func )
	g_Sync[name] = {}
	g_Sync[name].func = func
	g_Sync[name].data = {}
	g_Sync[name].alwaysupload = alwaysupload
end

function notifySyncerChange ( name, arg, val )
	assert ( name and g_Sync[name] and ( arg ~= nil ) )
	
	local syncer = g_Sync[name]
	local el_data = syncer.data[arg]
	if ( not el_data ) then
		return -- noone sync it
	end
	
	--outputDebugString ( 'notifySyncerChange - '..name )
	el_data.t = getTickCount () -- update modification time
	for player, sync_time in pairs ( el_data.p ) do
		if ( sync_time == 0 ) then
			if ( not val ) then
				val = syncer.func ( arg )  -- no value given, call syncer function
			end
			triggerClientInternalEvent ( player, $(EV_SYNC), g_Root, { [name] = { arg, val } } ) -- sync with all players
		end
	end
end

function startSync ( player, tbl, force )
	assert ( Player.fromEl(player) and tbl )
	local sync_tbl = {}
	
	for name, arg in pairs ( tbl ) do
		--outputDebugString ( 'startSync - '..name )
		local syncer = g_Sync[name]
		if ( syncer ) then -- are parameters valid?
			if ( not syncer.data[arg] ) then -- noone synced it before
				syncer.data[arg] = { t = getTickCount (), p = {} }
			end
			
			local el_data = syncer.data[arg]
			if ( not el_data.p[player] or ( el_data.p[player] ~= 0 and el_data.p[player] < el_data.t ) or force ) then -- player need a sync
				local v = syncer.func ( arg ) -- call syncer function
				sync_tbl[name] = { arg, v }
			end
			el_data.p[player] = 0
		else
			outputDebugString ( 'Unknown syncer: '..tostring ( name ), 2 )
		end
	end
	
	if ( not table.empty ( sync_tbl ) ) then
		--outputDebugString ( 'syncing...' )
		triggerClientInternalEvent ( player, $(EV_SYNC), g_Root, sync_tbl ) -- sync with player
	end
end

function stopSync ( player, tbl )
	assert ( tbl )
	
	for name, arg in pairs ( tbl ) do
		--outputDebugString ( 'stopSync - '..name )
		local syncer = g_Sync[name]
		local el_data = syncer and syncer.data[arg]
		if ( el_data ) then -- are parameters valid?
			el_data.p[player] = nil -- stop sync for player
			if ( table.empty ( el_data.p ) ) then
				syncer.data[arg] = nil
			end
		end
	end
end

function pauseSync ( player, tbl )
	assert ( Player.fromEl(player) and tbl )
	
	for name, arg in pairs ( tbl ) do
		--outputDebugString ( 'pauseSync - '..name )
		local syncer = g_Sync[name]
		local el_data = syncer and syncer.data[arg]
		if ( el_data ) then -- are parameters valid?
			el_data.p[player] = el_data.t -- pause sync for player, save time of last sync
		end
	end
end

function syncOnce ( player, tbl, force )
	assert ( Player.fromEl(player) and tbl )
	local sync_tbl = {}
	
	for name, arg in pairs ( tbl ) do
		--outputDebugString ( 'syncOnce - '..name )
		local syncer = g_Sync[name]
		if ( syncer ) then
			if ( not syncer.data[arg] ) then -- noone synced it before
				syncer.data[arg] = { t = getTickCount (), p = {} }
			end
			
			local el_data = syncer.data[arg]
			if ( not el_data.p[player] or ( el_data.p[player] < el_data.t and el_data.p[player] ~= 0 ) or syncer.alwaysupload or force ) then -- player need a sync
				local v = syncer.func ( arg ) -- call syncer function
				sync_tbl[name] = { arg, v }
				--outputDebugString ( name..' added' )
			else
				--outputDebugString ( name..' ignored' )
				sync_tbl[name] = { arg, false }
			end
			el_data.p[player] = el_data.t -- pause sync for player, save time of last sync
		else
			outputDebugString ( 'Unknown syncer: '..tostring ( name ), 2 )
		end
	end
	
	triggerClientInternalEvent ( player, $(EV_SYNC), g_Root, sync_tbl ) -- sync with player
end

------------
-- Events --
------------

addInitFunc(function()
	addEventHandler ( 'onPlayerQuit', g_Root, onPlayerQuit )
	addInternalEventHandler ( $(EV_START_SYNC_REQUEST), function ( tbl, force ) startSync ( client, tbl, force ) end )
	addInternalEventHandler ( $(EV_STOP_SYNC_REQUEST), function ( tbl ) stopSync ( client, tbl ) end )
	addInternalEventHandler ( $(EV_PAUSE_SYNC_REQUEST), function ( tbl ) pauseSync ( client, tbl ) end )
	addInternalEventHandler ( $(EV_SYNC_ONCE_REQUEST), function ( tbl, force ) syncOnce ( client, tbl, force ) end )
end)