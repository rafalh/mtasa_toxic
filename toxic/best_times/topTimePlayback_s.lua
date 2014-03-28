namespace('TopTimePlayback')

addEvent('onRaceStateChanging')

function start(room, map_id)
	if(not Settings.ghost) then return end
	
	local prof = DbgPerf()
	local row = DbQuerySingle('SELECT bt.player, bt.time, b.data FROM '..BestTimesTable..' bt, '..BlobsTable..' b WHERE bt.map=? AND b.id=bt.rec ORDER BY bt.time LIMIT 1', map_id)
	if(not row) then return end
	
	Debug.info('Showing ghost')
	
	local traceCoded = row.data
	if(zlibUncompress) then
		traceCoded = zlibUncompress(traceCoded)
	end
	if(not traceCoded) then
		Debug.warn('Failed to uncompress ghost trace')
		return
	end
	
	local place = DbCount(BestTimesTable, 'map=? AND time<=? LIMIT 1', map_id, row.time)
	local recTitle = 'Top '..place
	
	RPC('TopTimePlayback.init', traceCoded, recTitle):setClient(room.el):exec()
	room.topTimePlabackWaiting = true
	room.topTimePlaback = {traceCoded, recTitle}
	
	prof:cp('TopTimePlayback.start')
end

function stop(room)
	if(not room.topTimePlaback) then return end
	room.topTimePlabackWaiting = false
	room.topTimePlaback = false
	RPC('TopTimePlayback.destroy'):setClient(room.el):exec()
end

local function onRaceStateChange(stateName)
	if(stateName == 'Running') then
		for el, room in Room.pairs() do
			if(room.topTimePlabackWaiting) then
				RPC('TopTimePlayback.start'):setClient(room.el):exec()
				room.topTimePlabackWaiting = false
			end
		end
	end
end

local function onPlayerReady()
	local player = Player.fromEl(client)
	local room = player.room
	if(room.topTimePlaback) then
		RPC('TopTimePlayback.init', room.topTimePlaback[1], room.topTimePlaback[2]):setClient(player.el):exec()
		if(not room.topTimePlabackWaiting) then
			RPC('TopTimePlayback.start'):setClient(player.el):exec()
		end
	end
end

addInitFunc(function()
	addEventHandler('onRaceStateChanging', root, onRaceStateChange)
	addEventHandler('main.onPlayerReady', g_ResRoot, onPlayerReady)
end)
