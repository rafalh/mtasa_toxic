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

local function RcOnPlayerReachCheckpoint(checkpoint, time)
	local pdata = Player.fromEl(source)
	if(pdata.cp_times) then
		table.insert(pdata.cp_times, time)
	end
end

function RcEncodeTrace(rec)
	local longFmtCnt = 0
	local buf = ""
	for i, data in ipairs(rec) do
		local dticks, model = tonumber(data[1]), tonumber(data[8])
		local dx, dy, dz = tonumber(data[2]), tonumber(data[3]), tonumber(data[4])
		local drx, dry, drz = tonumber(data[5]), tonumber(data[6]), tonumber(data[7])
		
		if(not dticks or not dx or not dy or not dz or not drx or not dry or not drz) then
			outputDebugString("Invalid rec", 2)
			return false
		end
		
		if(drx > 180)      then drx = drx - 360
		elseif(drx < -180) then drx = drx + 360 end
		if(dry > 180)      then dry = dry - 360
		elseif(dry < -180) then dry = dry + 360 end
		if(drz > 180)      then drz = drz - 360
		elseif(drz < -180) then drz = drz + 360 end
		
		local longFmt = model or dticks > 65000 or
			math.abs(dx) > 32000 or math.abs(dy) > 32000 or math.abs(dz) > 32000 or
			math.abs(drx) > 127 or math.abs(dry) > 127 or math.abs(drz) > 127
		
		if(longFmt) then
			longFmtCnt = longFmtCnt + 1
			buf = buf.."\1"..uintToBin(dticks, 4)..
				intToBin(dx, 4)..intToBin(dy, 4)..intToBin(dz, 4)..
				intToBin(drx, 2)..intToBin(dry, 2)..intToBin(drz, 2)..uintToBin(model or 0, 2)
		else
			buf = buf.."\0"..uintToBin(dticks, 2)..
				intToBin(dx, 2)..intToBin(dy, 2)..intToBin(dz, 2)..
				intToBin(drx, 1)..intToBin(dry, 1)..intToBin(drz, 1)
		end
	end
	
	if(longFmtCnt*10 > #rec) then
		outputDebugString("Too bad "..longFmtCnt.."/"..#rec, 2)
	end
	
	return buf
end

function RcDecodeTrace(buf)
	local rec = {}
	local i = 1
	while(i <= buf:len()) do
		local flags = buf:byte(i)
		assert(flags <= 1)
		local data = {}
		if(flags == 1) then -- long format
			assert(i + 24 <= buf:len())
			data[1] = binToUint(buf:sub(i + 1, i + 4)) -- dticks
			data[2] = binToInt(buf:sub(i + 5, i + 8)) -- dx
			data[3] = binToInt(buf:sub(i + 9, i + 12)) -- dy
			data[4] = binToInt(buf:sub(i + 13, i + 16)) -- dz
			data[5] = binToInt(buf:sub(i + 17, i + 18)) -- drx
			data[6] = binToInt(buf:sub(i + 19, i + 20)) -- dry
			data[7] = binToInt(buf:sub(i + 21, i + 22)) -- drz
			data[8] = binToUint(buf:sub(i + 23, i + 24)) -- model
			if(data[8] == 0) then data[8] = false end
			i = i + 25
		else
			assert(i + 11 <= buf:len())
			data[1] = binToUint(buf:sub(i + 1, i + 2)) -- dticks
			data[2] = binToInt(buf:sub(i + 3, i + 4)) -- dx
			data[3] = binToInt(buf:sub(i + 5, i + 6)) -- dy
			data[4] = binToInt(buf:sub(i + 7, i + 8)) -- dz
			data[5] = binToInt(buf:sub(i + 9, i + 9)) -- drx
			data[6] = binToInt(buf:sub(i + 10, i + 10)) -- dry
			data[7] = binToInt(buf:sub(i + 11, i + 11)) -- drz
			i = i + 12
		end
		
		table.insert(rec, data)
	end
	
	return rec
end

--[[function RcEncodeTraceOld(rec)
	local buf = ""
	for i, data in ipairs(rec) do
		if(#data >= 7 and #data <= 8) then -- check
			buf = buf..","
			for i, v in ipairs(data) do
				local n = tonumber(v) or 0
				if(n < 0) then
					buf = buf.."-"
				end
				n = math.abs(n)
				buf = buf..("%x"):format(n)
				
				buf = buf..((i < #data and " ") or "")
			end
		end
	end
	
	return buf:sub(2)
end]]

local function RcOnRecording(map_id, recording)
	map_id = touint(map_id, 0)
	local pdata = Player.fromEl(client)
	
	if(map_id <= 0 or not pdata or type(recording) ~= "table" or #recording <= 2 or not pdata.id) then
		outputDebugString("Invalid parameters in RcOnRecording", 2)
		return
	end
	
	--outputDebugString("RcOnRecording", 3)
	
	if(Settings.recorder) then
		local rows = DbQuery("SELECT player, rec FROM "..BestTimesTable.." WHERE map=? AND (rec<>0 OR player=?) ORDER BY time LIMIT $(MAX_RECORDINGS+1)", map_id, pdata.id)
		
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
			outputDebugString("Saving ghost trace (stage 2): "..pdata:getName(), 3)
			local encoded = RcEncodeTrace(recording)
			encoded = zlibCompress(encoded)
			local blob = DbBlob(encoded)
			if(foundRow and foundRow.rec ~= 0) then
				DbQuery("UPDATE "..BlobsTable.." SET data="..blob.." WHERE id=?", foundRow.rec)
			else
				DbQuery("INSERT INTO "..BlobsTable.." (data) VALUES("..blob..")")
				local id = Database.getLastInsertID()
				if(id == 0) then outputDebugString("last insert ID == 0", 2) end
				DbQuery("UPDATE "..BestTimesTable.." SET rec=? WHERE map=? AND player=?", id, map_id, pdata.id)
			end
			
			local rowAfterTop = rows[$(MAX_RECORDINGS+1)]
			if(rowAfterTop) then
				DbQuery("DELETE FROM "..BlobsTable.." WHERE id=?", rowAfterTop.rec)
				DbQuery("UPDATE "..BestTimesTable.." SET rec=0 WHERE player=? AND map=?", rowAfterTop.player, map_id)
			end
		else
			outputDebugString("Invalid player: "..pdata:getName(), 2)
		end
	end
end

---------------------------------
-- Global function definitions --
---------------------------------

function RcStartRecording(room, map_id)
	--outputDebugString("Recording started...", 3)
	
	for player, pdata in pairs(g_Players) do
		if(pdata.room == room) then
			pdata.recording = true
		end
	end
	
	local rows = DbQuery("SELECT bt.player, bt.time, b.data FROM "..BestTimesTable.." bt, "..BlobsTable.." b WHERE bt.map=? AND b.id=bt.rec ORDER BY bt.time LIMIT 1", map_id)
	local row = rows and rows[1]
	if(row and Settings.ghost) then
		outputDebugString("Showing ghost", 3)
		local recCompr = zlibUncompress(row.data)
		if(not recCompr) then outputDebugString("Failed to uncompress", 2) end
		local rec = RcDecodeTrace(recCompr)
		
		local rows2 = DbQuery("SELECT count(player) AS c FROM "..BestTimesTable.." WHERE map=? AND time<? LIMIT 1", map_id, row.time)
		local recTitle = "Top "..(rows2[1].c + 1)
		
		RPC("Playback.startAfterCountdown", rec, recTitle):setClient(room.el):exec()
	end
	
	triggerClientInternalEvent(room.el, $(EV_CLIENT_START_RECORDING_REQUEST), g_Root, map_id)
end

function RcStopRecording(room)
	--outputDebugString("recording stoped", 3)
	
	for player, pdata in pairs(g_Players) do
		if(pdata.room == room) then
			pdata.recording = nil
		end
	end
	
	RPC("Playback.stop"):setClient(room.el):exec()
	triggerClientInternalEvent(room.el, $(EV_CLIENT_STOP_RECORDING_REQUEST), g_Root)
end

function RcFinishRecordingPlayer(player, time, map_id, improvedBestTime)
	local pdata = Player.fromEl(player)
	assert(pdata and map_id)
	
	if(not improvedBestTime) then
		if (pdata.recording) then
			triggerClientInternalEvent(player, $(EV_CLIENT_STOP_RECORDING_REQUEST), player, map_id)
		end
		return
	end
	
	if(pdata.recording) then
		assert(pdata.id)
		local rows = DbQuery("SELECT player, time FROM "..BestTimesTable.." WHERE map=? AND (rec<>0 OR player=?) ORDER BY time LIMIT $(MAX_RECORDINGS)", map_id, pdata.id)
		
		local found = false
		for i, data in ipairs(rows) do
			if(data.player == pdata.id and data.time == time) then
				found = true
				break
			end
		end
		
		if(found or #rows < $(MAX_RECORDINGS)) then -- if player just get this besttime or there is fewer than 3 recordings
			outputDebugString("Saving ghost trace (stage 1): "..pdata:getName(), 3)
			triggerClientInternalEvent(player, $(EV_CLIENT_STOP_SEND_RECORDING_REQUEST), player, map_id)
		else
			--outputDebugString("Ghost trace won't be saved", 3)
			triggerClientInternalEvent(player, $(EV_CLIENT_STOP_RECORDING_REQUEST), player, map_id)
		end
	end
	
	if(pdata.cp_times) then
		assert(pdata.id)
		local rows = DbQuery("SELECT player, time, cp_times FROM "..BestTimesTable.." WHERE map=? AND (cp_times<>0 OR player=?) ORDER BY time LIMIT $(MAX_RECORDINGS+1)", map_id, pdata.id)
		
		local foundRow = false
		for i, data in ipairs(rows) do
			if(i <= $(MAX_RECORDINGS) and data.player == pdata.id and data.time == time) then
				foundRow = data
				break
			end
		end
		
		if(foundRow or #rows < $(MAX_RECORDINGS)) then -- if player just get this besttime or there is fewer than 3 cp recordings
			--outputDebugString("saving cp rec for "..pdata:getName(), 3)
			local buf = ""
			local prevTime = 0
			for i, t in ipairs(pdata.cp_times) do
				buf = buf..("%x,"):format(t - prevTime)
				prevTime = t
			end
			buf = buf..("%x"):format(time - prevTime)
			buf = zlibCompress(buf)
			local blob = DbBlob(buf)
			
			if(foundRow.cp_times ~= 0) then
				DbQuery("UPDATE "..BlobsTable.." SET data="..blob.." WHERE id=?", foundRow.cp_times)
			else
				DbQuery("INSERT INTO "..BlobsTable.." (data) VALUES("..blob..")")
				local id = Database.getLastInsertID()
				if(id == 0) then outputDebugString("last insert ID == 0", 2) end
				DbQuery("UPDATE "..BestTimesTable.." SET cp_times=? WHERE map=? AND player=?", id, map_id, pdata.id)
			end
			
			local rowAfterTop = rows[$(MAX_RECORDINGS+1)]
			if(rowAfterTop) then
				DbQuery("DELETE FROM "..BlobsTable.." WHERE id=?", rowAfterTop.cp_times)
				DbQuery("UPDATE "..BestTimesTable.." SET cp_times=0 WHERE map=? AND player=?", map_id, rowAfterTop.player)
			end
		end
		
		pdata.cp_times = false -- dont allow to use this cp list in next map
	end
end

------------
-- Events --
------------

addInitFunc(function()
	addEventHandler("onPlayerReachCheckpoint", g_Root, RcOnPlayerReachCheckpoint)
	addInternalEventHandler($(EV_RECORDING), RcOnRecording)
end)
