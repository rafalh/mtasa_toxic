local g_Poll = false

RatesTable = Database.Table{
	name = 'rates',
	{'player', 'INT UNSIGNED', fk = {'players', 'player'}},
	{'map', 'INT UNSIGNED', fk = {'maps', 'map'}},
	{'rate', 'TINYINT UNSIGNED'},
	{'rates_idx', unique = {'map', 'player'}},
}

addEvent('onPollStarting')

function RtPlayerRate(rate)
	local pdata = Player.fromEl(source)
	local room = pdata.room
	local map = getCurrentMap(room)
	
	rate = touint(rate, 0)
	if(rate < 1 or rate > 5 or not map or not pdata.id) then return end
	
	rate = rate * 2
	local map_id = map:getId()
	local rows = DbQuery('SELECT rates, rates_count FROM '..MapsTable..' WHERE map=? LIMIT 1', map_id)
	local mapData = rows and rows[1]
	
	local rows = DbQuery('SELECT rate FROM '..RatesTable..' WHERE player=? AND map=? LIMIT 1', pdata.id, map_id)
	local oldRate = rows and rows[1] and rows[1].rate
	if(not oldRate or Settings.allow_rate_change) then
		if(oldRate) then
			assert(mapData.rates_count > 0 and mapData.rates > 0)
			mapData.rates = mapData.rates - oldRate + rate
			DbQuery('UPDATE '..RatesTable..' SET rate=? WHERE player=? AND map=?', rate, pdata.id, map_id)
		else
			mapData.rates_count = mapData.rates_count + 1
			mapData.rates = mapData.rates + rate
			DbQuery('INSERT INTO '..RatesTable..' (player, map, rate) VALUES(?, ?, ?)', pdata.id, map_id, rate)
			pdata.accountData:add('mapsRated', 1)
		end
		
		DbQuery('UPDATE '..MapsTable..' SET rates=?, rates_count=? WHERE map=?', mapData.rates, mapData.rates_count, map_id)
		privMsg(source, "Rate added! Current average rating: %.2f", mapData.rates / mapData.rates_count)
		
		MiUpdateInfo()
	else
		privMsg(source, "You rated this map before: %u!", oldRate)
	end
end
RPC.allow('RtPlayerRate')

local function RtTimerProc(room)
	local map = getCurrentMap(room)
	if(not map or g_Poll) then return end
	
	local pidList = {}
	for player, pdata in pairs(g_Players) do
		if(pdata.id) then
			table.insert(pidList, pdata.id)
		end
	end
	
	local pidListStr = table.concat(pidList, ',')
	local mapId = map:getId()
	local rows = DbQuery('SELECT player FROM '..RatesTable..' WHERE map=? AND player IN (??) LIMIT 1', mapId, pidListStr)
	for i, row in ipairs(rows) do
		table.removeValue(pidList, row.player)
	end
	
	for i, pid in ipairs(pidList) do
		local player = Player.fromId(pid)
		RPC('RtSetVisible', true):setClient(player.el):exec()
	end
end

local function RtMapStart()
	setMapTimer(RtTimerProc, 60 * 1000, 1, g_RootRoom) -- FIXME
	g_Poll = false
end

local function RtPoolStarting()
	--outputDebugString('RtPoolStarting', 3)
	RPC('RtSetVisible', false):exec()
	g_Poll = true
end

addInitFunc(function()
	addEventHandler('onGamemodeMapStart', g_Root, RtMapStart) -- FIXME
	addEventHandler('onPollStarting', g_Root, RtPoolStarting)
end)
