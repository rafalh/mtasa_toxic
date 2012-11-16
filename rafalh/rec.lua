--------------
-- Includes --
--------------

#include "include/internal_events.lua"

-----------------
-- Definitions --
-----------------

#MAX_RECORDINGS = 3

--------------------------------
-- Local function definitions --
--------------------------------

local function RcOnPlayerReachCheckpoint ( checkpoint, time )
	local pdata = g_Players[source]
	if ( pdata.cp_times ) then
		table.insert ( pdata.cp_times, time )
	end
end

local function RcEncodeTrace ( rec )
	local buf = ""
	for i, data in ipairs ( rec ) do
		if ( #data >= 7 and #data <= 8 ) then -- check
			buf = buf..","
			for i, v in ipairs ( data ) do
				local n = tonumber ( v ) or 0
				if ( n < 0 ) then
					buf = buf.."-"
				end
				n = math.abs ( n )
				-- BINARY
				-- n < 255^3 = 16581375
				--if ( n/$(255^2) >= 1 ) then
				--	buf = buf..string.char ( math.floor ( n/$(255^2) ) + 1 )
				--end
				--if ( n/$(255^1) >= 1 ) then
				--	buf = buf..string.char ( math.floor ( ( n/$(255^1) )%255 ) + 1 )
				--end
				--buf = buf..string.char ( math.floor ( n%255 ) + 1 )
				
				-- ASCII
				buf = buf..( "%x" ):format ( n )
				
				buf = buf..( ( i < #data and " " ) or "" )
			end
		end
	end
	
	return buf:sub ( 2 )
end

local function RcDecodeTrace ( data )
	local rec = split ( data, ( "," ):byte () )
	
	for i, v in ipairs ( rec ) do
		rec[i] = split ( v, ( " " ):byte () )
		
		-- decode hexadecimal numbers
		for j, v in ipairs ( rec[i] ) do
			if ( v:sub ( 1, 1 ) == "-" ) then
				rec[i][j] = -tonumber ( "0x"..v:sub ( 2 ) )
			else
				rec[i][j] = tonumber ( "0x"..v )
			end
		end
		
		-- make angles (-180, 180)
		for j = 5, 7, 1 do
			if ( rec[i][j] > 180 ) then
				rec[i][j] = rec[i][j] - 360
			end
		end
	end
	
	return rec
end

local function RcOnRecording ( map_id, recording )
	map_id = touint ( map_id, 0 )
	local pdata = g_Players[client]
	
	if ( map_id <= 0 or not pdata or type ( recording ) ~= "table" or #recording <= 2 ) then
		outputDebugString ( "Invalid parameters in RcOnRecording", 2 )
		return
	end
	
	--outputDebugString ( "RcOnRecording", 3 )
	if ( SmGetBool ( "recorder" ) ) then
		local rows = DbQuery ( "SELECT player FROM rafalh_besttimes WHERE map=? AND (rec<>'' OR player=?) ORDER BY time LIMIT $(MAX_RECORDINGS+1)", map_id, pdata.id )
		
		-- check if player has a toptime
		local found = false
		for i, data in ipairs ( rows ) do
			if ( i < $(MAX_RECORDINGS+1) and data.player == pdata.id ) then
				found = true
				break
			end
		end
		
		-- if player just get this besttime or there is fewer than 3 recordings
		if ( found or #rows < $(MAX_RECORDINGS) ) then
			local encoded = RcEncodeTrace ( recording )
			DbQuery ( "UPDATE rafalh_besttimes SET rec=? WHERE player=? AND map=?", encoded, pdata.id, map_id )
			if ( rows[$(MAX_RECORDINGS+1)] ) then
				DbQuery ( "UPDATE rafalh_besttimes SET rec='' WHERE player=? AND map=?", rows[$(MAX_RECORDINGS+1)].player, map_id )
			end
		end
	end
end

---------------------------------
-- Global function definitions --
---------------------------------

function RcStartRecording ( map_id )
	--outputDebugString ( "recording started" )
	
	for player, pdata in pairs ( g_Players ) do
		pdata.recording = true
	end
	
	local rows = DbQuery ( "SELECT player, time, rec FROM rafalh_besttimes WHERE map=? AND rec<>'' ORDER BY time LIMIT 1", map_id )
	local rec, rec_title = false, nil
	if ( rows and rows[1] and SmGetBool ( "ghost" ) ) then
		rec = RcDecodeTrace ( rows[1].rec )
		
		local rows2 = DbQuery ( "SELECT count(player) AS c FROM rafalh_besttimes WHERE map=? AND time<? LIMIT 1", map_id, rows[1].time )
		rec_title = "Top "..( rows2[1].c + 1 )
	end
	
	triggerClientInternalEvent ( g_Root, $(EV_CLIENT_START_RECORDING_REQUEST), g_Root, map_id, rec, rec_title )
end

function RcStopRecording ()
	--outputDebugString ( "recording stoped" )
	
	for player, pdata in pairs ( g_Players ) do
		pdata.recording = nil
	end
	
	triggerClientInternalEvent ( g_Root, $(EV_CLIENT_STOP_RECORDING_REQUEST), g_Root )
end

function RcFinishRecordingPlayer ( player, time, map_id, improved_besttime )
	local pdata = g_Players[player]
	
	if ( not improved_besttime ) then
		if ( pdata.recording ) then
			triggerClientInternalEvent ( player, $(EV_CLIENT_STOP_RECORDING_REQUEST), player, map_id )
		end
		return
	end
	
	if ( pdata.recording ) then
		local rows = DbQuery ( "SELECT player, time FROM rafalh_besttimes WHERE map=? AND (rec<>'' OR player=?) ORDER BY time LIMIT $(MAX_RECORDINGS)", map_id, pdata.id )
		
		local found = false
		for i, data in ipairs ( rows ) do
			if ( data.player == pdata.id and data.time == time ) then
				found = true
				break
			end
		end
		
		if ( found or #rows < 3 ) then -- if player just get this besttime or there is fewer than 3 recordings
			outputDebugString ( "Saving ghost trace", 3 )
			triggerClientInternalEvent ( player, $(EV_CLIENT_STOP_SEND_RECORDING_REQUEST), player, map_id )
		else
			--outputDebugString ( "Ghost trace won't be saved", 3 )
			triggerClientInternalEvent ( player, $(EV_CLIENT_STOP_RECORDING_REQUEST), player, map_id )
		end
	end
	
	if ( pdata.cp_times ) then
		local rows = DbQuery ( "SELECT player, time FROM rafalh_besttimes WHERE map=? AND (cp_times<>'' OR player=?) ORDER BY time LIMIT $(MAX_RECORDINGS+1)", map_id, pdata.id )
		
		local found = false
		for i, data in ipairs ( rows ) do
			if ( i < $(MAX_RECORDINGS+1) and data.player == pdata.id and data.time == time ) then
				found = true
				break
			end
		end
		
		if ( found or #rows < $(MAX_RECORDINGS) ) then -- if player just get this besttime or there is fewer than 3 cp recordings
			--outputDebugString ( "saving cp rec for "..getPlayerName ( player ), 3 )
			local buf = ""
			local prev_time = 0
			for i, t in ipairs ( pdata.cp_times ) do
				buf = buf..( "%x," ):format ( t - prev_time )
				prev_time = t
			end
			buf = buf..( "%x" ):format ( time - prev_time )
			DbQuery ( "UPDATE rafalh_besttimes SET cp_times=? WHERE player=? AND map=?", buf, pdata.id, map_id )
			if ( rows[$(MAX_RECORDINGS+1)] ) then
				DbQuery ( "UPDATE rafalh_besttimes SET cp_times='' WHERE player=? AND map=?", rows[$(MAX_RECORDINGS+1)].player, map_id )
			end
		end
		
		pdata.cp_times = false -- dont allow to use this cp list in next map
	end
end

--[[setTimer ( function ()
	local map = getCurrentMap()
	local map_id = map:getId()
	RcStartRecording ( map_id )
end, 2000, 1 )]]

------------
-- Events --
------------

addEventHandler ( "onPlayerReachCheckpoint", g_Root, RcOnPlayerReachCheckpoint )
addInternalEventHandler ( $(EV_RECORDING), RcOnRecording )
