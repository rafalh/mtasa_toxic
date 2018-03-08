-- Includes
#include 'include/config.lua'

-- Defines
#POINTS_FOR_KILLS = true

#if(DD_TOPS) then
VictoriesTable = Database.Table{
	name = 'victories',
	{'player', 'INT UNSIGNED', fk = {'players', 'player'}},
	{'map', 'INT UNSIGNED', fk = {'maps', 'map'}},
	{'victCount', 'INT UNSIGNED'},
	{'victories_idx', unique = {'map', 'victCount', 'player'}},
	{'victories_idx2', unique = {'map', 'player'}},
}
#end -- DD_TOPS

local function onKillersList(killer, assist)
	local victimPlayer = Player.fromEl(client)
	local killerPlayer = killer and Player.fromEl(killer)
	local assistPlayer = assist and Player.fromEl(assist)
	
	local room = victimPlayer and victimPlayer.room
	local map = room and getCurrentMap(room)
	if(not victimPlayer or not map
		or killerPlayer == victimPlayer or assistPlayer == victimPlayer) then
		Debug.warn('Invalid args for onKillersList ('..tostring(victimPlayer and victimPlayer:getName())..' '..tostring(map)..')')
		return
	end
	
	-- Check if killers info is allowed
	if(not victimPlayer.ddKillersAllowed) then
		Debug.warn('Player \''..tostring(victimPlayer:getName())..'\' is not allowed to send killer info now')
		return
	end
	victimPlayer.ddKillersAllowed = nil
	
	--Debug.info('KillersInfo '..victimPlayer:getName()..' '..tostring(victimPlayer:isAlive()))
	
	local respawn = map and map:getRespawn()
	if(not respawn and victimPlayer:isAlive()) then
		Debug.warn('Ignoring killer info - client alive: '..tostring(victimPlayer:getName()))
		return
	end
	
	if(map.isRace or map:getType().name ~= 'DD') then
		Debug.warn('Wrong map type: '..map:getType().name..' '..map:getName())
		return
	end
	
	-- Check if there is any killer
	if(not killerPlayer) then return end
	
	local killerLvl = LvlFromExp(killerPlayer.accountData.points)
	victimPlayer:addNotify{
		icon = 'stats/img/skull.png',
		{"You have been killed by %s (%u. level)!", killerPlayer:getName(), killerLvl}}
	
	local victimExp = victimPlayer.accountData.points
	local victimLvl = LvlFromExp(victimExp)
	
#if(POINTS_FOR_KILLS) then
	local expBonus = math.floor(victimLvl^0.5*5)
	killerPlayer:addNotify{
		icon = 'stats/img/skull.png',
		{"You have killed %s (%u. level) and receive %s!", victimPlayer:getName(), victimLvl, expBonus..' EXP'}}
	killerPlayer.accountData:add('points', expBonus)
#else
	killerPlayer:addNotify{
		icon = 'stats/img/skull.png',
		{"You have killed %s (%u. level)!", victimPlayer:getName(), victimLvl}}
#end
	killerPlayer.accountData:add('kills', 1)
	killerPlayer.currentMapKills = (killerPlayer.currentMapKills or 0) + 1
	
	if(assistPlayer) then
#if(POINTS_FOR_KILLS) then
		local expBonus = math.floor(expBonus/2)
		assistPlayer:addNotify{
			icon = 'stats/img/skull.png',
			{"You have killed %s (assist) and receive %s!", victimPlayer:getName(), expBonus..' EXP'}}
		assistPlayer.accountData:add('points', expBonus)
#else
		assistPlayer:addNotify{
			icon = 'stats/img/skull.png',
			{"You have killed %s (assist)!", victimPlayer:getName()}}
#end
	end
end

function DdMapStart(room)
	local map = getCurrentMap(room)
	local mapType = map and map:getType()
	room.ddKilersDetection = (map and not map.isRace and mapType.name == 'DD')
	if(room.ddKilersDetection) then
		RPC('DdSetKillersDetectionEnabled', true):exec()
	end
end

function DdMapStop(room)
	if(room.ddKilersDetection) then
		RPC('DdSetKillersDetectionEnabled', false):exec()
		room.ddKilersDetection = nil
	end
	
	for player, pdata in pairs(g_Players) do
		pdata.currentMapKills = 0
		if(pdata.ddKillersAllowed) then
			Debug.warn('Killers list not received from \''..pdata:getName()..'\'!')
		end
		pdata.ddKillersAllowed = nil
	end
end

#if(DD_TOPS) then

function DdGetTops(map, count)
	local cachedTops = Cache.get('Stats.m'..map:getId()..'.DdTops')
	if(cachedTops and #cachedTops >= count) then
		return cachedTops
	end
	
	local rows = DbQuery(
		'SELECT v.player, v.victCount, p.name '..
		'FROM '..VictoriesTable..' v '..
		'INNER JOIN '..PlayersTable..' p ON v.player=p.player '..
		'WHERE v.map=? ORDER BY victCount DESC LIMIT ?', map:getId(), count)
	
	Cache.set('Stats.m'..map:getId()..'.DdTops', rows, 300)
	return rows
end

function DdPreloadPersonalTops(mapId, playerIdList, needsPos)
	local personalCache = Cache.get('BestTime.m'..mapId..'.Personal')
	if(not personalCache) then
		personalCache = {}
		Cache.set('BestTime.m'..mapId..'.Personal', personalCache, 300)
	end
	
	local idList = {}
	for i, playerId in ipairs(playerIdList) do
		if(personalCache[playerId] == nil or (needsPos and personalCache[playerId] and not personalCache[playerId].pos)) then
			personalCache[playerId] = false
			table.insert(idList, playerId)
		end
	end
	
	if(#idList > 0) then
		local rows
		if(needsPos) then
			rows = DbQuery(
				'SELECT v1.player, v1.victCount, ('..
					'SELECT COUNT(*) FROM '..VictoriesTable..' AS v2 '..
					'WHERE v2.map=v1.map AND v2.victCount>=v1.victCount) AS pos '..
				'FROM '..VictoriesTable..' v1 '..
				'WHERE v1.map=? AND v1.player IN (??)', map:getId(), table.concat(idList, ','))
		else
			rows = DbQuery(
				'SELECT player, victCount '..
				'FROM '..VictoriesTable..' '..
				'WHERE map=? AND player IN (??)', mapId, table.concat(idList, ','))
		end
		
		for i, data in ipairs(rows) do
			local playerId = data.player
			data.player = nil
			personalCache[playerId] = data
		end
	end
end

function DdGetPersonalTop(mapId, playerId, needsPos)
	if(not playerId) then return false end
	DdPreloadPersonalTops(mapId, {playerId}, needsPos)
	local cache = Cache.get('Stats.m'..mapId..'.DdTops')
	local info = cache[playerId]
	return info and table.copy(info)
end

function DdAddVictory(player, map)
	if(not player.id) then return end -- guest
	local rows = DbQuery('SELECT victCount FROM '..VictoriesTable..' WHERE map=? AND player=?', map:getId(), player.id)
	local victCount = rows and rows[1] and rows[1].victCount
	if(victCount) then
		DbQuery('UPDATE '..VictoriesTable..' SET victCount=victCount+1 WHERE map=? AND player=?', map:getId(), player.id)
	else
		DbQuery('INSERT INTO '..VictoriesTable..' (map, player, victCount) VALUES(?, ?, 1)', map:getId(), player.id)
	end
	
	Cache.remove('Stats.m'..map:getId()..'.DdTops')
	
	MiUpdateTops()
end

#end -- DD_TOPS

local function onPlayerWasted()
	local player = Player.fromEl(source)
	
	-- Check if killers detection is enabled and player is ready
	if(not player or not player.room.ddKilersDetection or not player.sync) then return end
	
	-- Check if Race State is valid
	if(player.room.gameState == 'Running' or player.room.gameState == 'PostFinish') then
		if(player.ddKillersAllowed) then
			--Debug.warn('Previous killers list has not been received!')
			return
		end
		player.ddKillersAllowed = true
		RPC('DdGetKillers'):setClient(source):onResult(onKillersList):exec()
		--Debug.info('onPlayerWasted '..player:getName())
	end
end

local function onPlayerReady()
	local player = Player.fromEl(client)
	local room = player.room
	if(room.ddKilersDetection) then
		RPC('DdSetKillersDetectionEnabled', true):setClient(player.el):exec()
	end
end

addInitFunc(function()
	addEventHandler('onPlayerWasted', root, onPlayerWasted)
	addEventHandler('main.onPlayerReady', g_ResRoot, onPlayerReady)
end)
