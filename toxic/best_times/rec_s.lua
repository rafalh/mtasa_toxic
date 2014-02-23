--------------
-- Includes --
--------------

#include 'include/internal_events.lua'

-----------------
-- Definitions --
-----------------

#MAX_RECORDINGS = 3

-------------------
-- Custom events --
-------------------
addEvent('onPlayerReachCheckpoint')

--------------------------------
-- Local function definitions --
--------------------------------

local function RcOnPlayerReachCheckpoint(checkpoint, time)
	local pdata = Player.fromEl(source)
	if(pdata.cp_times) then
		table.insert(pdata.cp_times, time)
	end
end

local function RcOnRecording(map_id, recording)
	local prof = DbgPerf()
	map_id = touint(map_id, 0)
	local pdata = Player.fromEl(client)
	
	if(map_id <= 0 or not pdata or type(recording) ~= 'table' or #recording <= 2 or not pdata.id) then
		Debug.warn('Invalid parameters in RcOnRecording')
		return
	end
	
	--Debug.info('RcOnRecording')
	
	if(Settings.recorder) then
		local rows = DbQuery('SELECT player, rec FROM '..BestTimesTable..' WHERE map=? AND (rec IS NOT NULL OR player=?) ORDER BY time LIMIT $(MAX_RECORDINGS+1)', map_id, pdata.id)
		
		-- check if player has a toptime
		local foundRow = false
		for i, data in ipairs(rows) do
			if(i <= $(MAX_RECORDINGS) and data.player == pdata.id) then
				foundRow = data
				break
			end
		end
		
		-- if player just get this besttime or there is fewer than 3 recordings
		if(foundRow or #rows < $(MAX_RECORDINGS)) then
			Debug.info('Saving ghost trace (stage 2): '..pdata:getName())
			local encoded = RcEncodeTrace(recording)
			if(zlibCompress) then
				encoded = zlibCompress(encoded)
			end
			local blob = DbBlob(encoded)
			if(foundRow and foundRow.rec) then
				DbQuery('UPDATE '..BlobsTable..' SET data='..blob..' WHERE id=?', foundRow.rec)
			else
				DbQuery('INSERT INTO '..BlobsTable..' (data) VALUES('..blob..')')
				local id = Database.getLastInsertID()
				if(id == 0) then Debug.warn('last insert ID == 0') end
				DbQuery('UPDATE '..BestTimesTable..' SET rec=? WHERE map=? AND player=?', id, map_id, pdata.id)
			end
			
			local rowAfterTop = rows[$(MAX_RECORDINGS+1)]
			if(rowAfterTop) then
				DbQuery('UPDATE '..BestTimesTable..' SET rec=NULL WHERE player=? AND map=?', rowAfterTop.player, map_id)
				DbQuery('DELETE FROM '..BlobsTable..' WHERE id=?', rowAfterTop.rec)
			end
		else
			Debug.warn('Invalid player: '..pdata:getName())
		end
	end
	
	prof:cp('RcOnRecording')
end

---------------------------------
-- Global function definitions --
---------------------------------

function RcStartRecording(room, map_id)
	--Debug.info('Recording started...')
	local prof = DbgPerf()
	local prof2 = DbgPerf(30)
	
	for player, pdata in pairs(g_Players) do
		if(pdata.room == room) then
			pdata.recording = true
			pdata.cp_times = Settings.cp_recorder and room.isRace and {}
		end
	end
	prof2:cp('RcStartRecording 1')
	
	local rows = DbQuery('SELECT bt.player, bt.time, b.data FROM '..BestTimesTable..' bt, '..BlobsTable..' b WHERE bt.map=? AND b.id=bt.rec ORDER BY bt.time LIMIT 1', map_id)
	local row = rows and rows[1]
	prof2:cp('RcStartRecording 2')
	if(row and Settings.ghost) then
		Debug.info('Showing ghost')
		
		local recCoded = row.data
		if(zlibUncompress) then
			recCoded = zlibUncompress(recCoded)
		end
		if(not recCoded) then Debug.warn('Failed to uncompress') end
		prof2:cp('RcStartRecording 3')
		
		local rows2 = DbQuery('SELECT count(player) AS c FROM '..BestTimesTable..' WHERE map=? AND time<? LIMIT 1', map_id, row.time)
		local recTitle = 'Top '..(rows2[1].c + 1)
		prof2:cp('RcStartRecording 4')
		
		RPC('Playback.startAfterCountdown', recCoded, recTitle):setClient(room.el):exec()
		prof2:cp('RcStartRecording 5')
	end
	
	triggerClientInternalEvent(room.el, $(EV_CLIENT_START_RECORDING_REQUEST), g_Root, map_id)
	prof2:cp('RcStartRecording 6')
	prof:cp('RcStartRecording')
end

function RcStopRecording(room)
	--Debug.info('recording stoped')
	
	for player, pdata in pairs(g_Players) do
		if(pdata.room == room) then
			pdata.recording = nil
		end
	end
	
	RPC('Playback.stop'):setClient(room.el):exec()
	triggerClientInternalEvent(room.el, $(EV_CLIENT_STOP_RECORDING_REQUEST), g_Root)
end

function RcFinishRecordingPlayer(player, time, map_id, improvedBestTime)
	local prof = DbgPerf()
	local pdata = Player.fromEl(player)
	assert(pdata and map_id)
	
	if(not improvedBestTime) then
		if(pdata.recording) then
			triggerClientInternalEvent(player, $(EV_CLIENT_STOP_RECORDING_REQUEST), player, map_id)
		end
		return
	end
	
	if(pdata.recording) then
		assert(pdata.id)
		local rows = DbQuery('SELECT player, time FROM '..BestTimesTable..' WHERE map=? AND (rec IS NOT NULL OR player=?) ORDER BY time LIMIT $(MAX_RECORDINGS)', map_id, pdata.id)
		
		local found = false
		for i, data in ipairs(rows) do
			if(data.player == pdata.id and data.time == time) then
				found = true
				break
			end
		end
		
		if(found or #rows < $(MAX_RECORDINGS)) then -- if player just get this besttime or there is fewer than 3 recordings
			Debug.info('Saving ghost trace (stage 1): '..pdata:getName())
			triggerClientInternalEvent(player, $(EV_CLIENT_STOP_SEND_RECORDING_REQUEST), player, map_id)
		else
			--Debug.info('Ghost trace won't be saved')
			triggerClientInternalEvent(player, $(EV_CLIENT_STOP_RECORDING_REQUEST), player, map_id)
		end
	end
	
	if(pdata.cp_times) then
		assert(pdata.id)
		local rows = DbQuery('SELECT player, time, cp_times FROM '..BestTimesTable..' WHERE map=? AND (cp_times IS NOT NULL OR player=?) ORDER BY time LIMIT $(MAX_RECORDINGS+1)', map_id, pdata.id)
		
		local foundRow = false
		for i, data in ipairs(rows) do
			if(i <= $(MAX_RECORDINGS) and data.player == pdata.id and data.time == time) then
				foundRow = data
				break
			end
		end
		
		if(foundRow or #rows < $(MAX_RECORDINGS)) then -- if player just get this besttime or there is fewer than 3 cp recordings
			--Debug.info('saving cp rec for '..pdata:getName())
			local buf = ''
			local prevTime = 0
			for i, t in ipairs(pdata.cp_times) do
				buf = buf..('%x,'):format(t - prevTime)
				prevTime = t
			end
			buf = buf..('%x'):format(time - prevTime)
			if(zlibCompress) then
				buf = zlibCompress(buf)
			end
			local blob = DbBlob(buf)
			
			if(foundRow and foundRow.cp_times) then
				DbQuery('UPDATE '..BlobsTable..' SET data='..blob..' WHERE id=?', foundRow.cp_times)
			else
				DbQuery('INSERT INTO '..BlobsTable..' (data) VALUES('..blob..')')
				local id = Database.getLastInsertID()
				if(id == 0) then Debug.warn('last insert ID == 0') end
				DbQuery('UPDATE '..BestTimesTable..' SET cp_times=? WHERE map=? AND player=?', id, map_id, pdata.id)
			end
			
			local rowAfterTop = rows[$(MAX_RECORDINGS+1)]
			if(rowAfterTop) then
				DbQuery('UPDATE '..BestTimesTable..' SET cp_times=NULL WHERE map=? AND player=?', map_id, rowAfterTop.player)
				DbQuery('DELETE FROM '..BlobsTable..' WHERE id=?', rowAfterTop.cp_times)
			end
		end
		
		pdata.cp_times = false -- dont allow to use this cp list in next map
	end
	prof:cp('RcFinishRecordingPlayer')
end

------------
-- Events --
------------

addInitFunc(function()
	addEventHandler('onPlayerReachCheckpoint', g_Root, RcOnPlayerReachCheckpoint)
	addInternalEventHandler($(EV_RECORDING), RcOnRecording)
end)
