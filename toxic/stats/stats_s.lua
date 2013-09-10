-- Includes
#include 'include/config.lua'

-- Globals
local g_Stats = {
	'cash', 'points',
	'mapsPlayed', 'mapsBought', 'mapsRated',
#if(DM_STATS) then
	'dmVictories', 'huntersTaken', 'dmPlayed',
#end
#if(DD_STATS) then
	'ddVictories', 'ddPlayed', 'kills',
#end
#if(RACE_STATS) then
	'raceVictories', 'racesFinished', 'racesPlayed',
#end
	'maxWinStreak', 'toptimes_count',
	'bidlvl', 'time_here', 'exploded', 'drowned'}

PlayersTable:addColumns{
	-- Old stats
	{'cash',           'INT',                default = 0},
	{'points',         'MEDIUMINT',          default = 0},
	{'exploded',       'MEDIUMINT UNSIGNED', default = 0},
	{'drowned',        'MEDIUMINT UNSIGNED', default = 0},
	
	-- New stats
	{'maxWinStreak',  'SMALLINT UNSIGNED',  default = 0},
	{'mapsPlayed',    'MEDIUMINT UNSIGNED', default = 0},
	{'mapsBought',    'MEDIUMINT UNSIGNED', default = 0},
	{'mapsRated',     'SMALLINT UNSIGNED',  default = 0},
#if(DM_STATS) then
	{'huntersTaken',  'MEDIUMINT UNSIGNED', default = 0},
	{'dmVictories',   'MEDIUMINT UNSIGNED', default = 0},
	{'dmPlayed',      'MEDIUMINT UNSIGNED', default = 0},
#end
#if(DD_STATS) then
	{'ddVictories',   'MEDIUMINT UNSIGNED', default = 0},
	{'ddPlayed',      'MEDIUMINT UNSIGNED', default = 0},
	{'kills',         'MEDIUMINT UNSIGNED', default = 0},
#end
#if(RACE_STATS) then
	{'raceVictories', 'MEDIUMINT UNSIGNED', default = 0},
	{'racesFinished', 'MEDIUMINT UNSIGNED', default = 0},
	{'racesPlayed',   'MEDIUMINT UNSIGNED', default = 0},
#end
	{'achvCount',     'TINYINT UNSIGNED',   default = 0},
	
	-- Effectiveness (TODO)
	--[[{'efectiveness',      'FLOAT', default = 0},
	{'efectiveness_dd',   'FLOAT', default = 0},
	{'efectiveness_dm',   'FLOAT', default = 0},
	{'efectiveness_race', 'FLOAT', default = 0},]]
}

local function StAccountDataChange(accountData, name, newValue)
	if(not table.find(g_Stats, name)) then return end -- not a stat
	
	local player = Player.fromId(accountData.id)
	if(not player) then return end
	
	if(name == 'points') then
		setPlayerAnnounceValue(player.el, 'score', tostring(newValue))
		
		if(Settings.scoreboard_exp) then
			setElementData(player.el, 'exp', formatNumber(newValue))
		end
		
		if(StDetectRankChange) then
			StDetectRankChange(player, accountData.points, newValue)
		end
		
		StDetectLevelChange(player, accountData.points, newValue)
	end
	
	if(name == 'cash' and Settings.scoreboard_cash) then
		setElementData(player.el, 'cash', formatMoney(newValue))
	end
end

local function StAccountDataChangeDone(accountData, name)
	if(not table.find(g_Stats, name)) then return end -- not a stat
	
	local player = Player.fromId(accountData.id)
	if(player) then
		AchvCheckPlayer(player.el)
	end

	notifySyncerChange('stats', accountData.id)
end

local function StPlayerStatsSyncCallback(idOrPlayer)
	local id = touint(idOrPlayer)
	local player = (id and Player.fromId(id)) or Player.fromEl(idOrPlayer)
	
	local accountData
	if(player) then
		accountData = player.accountData
	elseif(id) then
		accountData = AccountData.create(id)
	else
		return false
	end
	
	local data = accountData:getTbl()
	if(not data) then return false end
	
	data._rank = StRankFromPoints(data.points)
	if(player) then
		-- send timestamp as string, because MTA converts all number to float (low precision)
		data._loginTimestamp = tostring(player.loginTimestamp)
	end
	data.name = data.name:gsub('#%x%x%x%x%x%x', '')
	return data
end

local function StUpdatePlayerScoreboardData(player)
	local pts = player.accountData.points
	setPlayerAnnounceValue(player.el, 'score', tostring(pts))
	
	if(Settings.scoreboard_lvl) then
		local lvl = LvlFromExp(pts)
		setElementData(player.el, 'lvl', lvl)
	end
	
	if(Settings.scoreboard_exp) then
		setElementData(player.el, 'exp', formatNumber(pts))
	end
	
	if(Settings.scoreboard_cash) then
		setElementData(player.el, 'cash', formatMoney(player.accountData.cash))
	end
end

local function StOnPlayerJoinOrLogin()
	local player = Player.fromEl(source)
	StUpdatePlayerScoreboardData(player)
end

local function StOnPlayerWasted(totalAmmo, killer, weapon)
	local player = Player.fromEl(source)
	if(not player) then return end
	
	if(weapon == 53) then -- drowned
		player.accountData:add('drowned', 1)
	end
end

local function StOnVehicleExplode()
	local playerEl = getVehicleOccupant(source)
	local player = playerEl and Player.fromEl(playerEl)
	if(not player) then return end
	
	-- Note: Blow in Admin Panel generates two onVehicleExplode but only one has health > 0
	if(getElementHealth(source) > 0) then
		player.accountData:add('exploded', 1)
	end
end

-- Called from maps
function StMapStart(room)
	local mapTypeCounter = false
	local map = getCurrentMap(room)
	local mapType = map:getType()
	
	if(false) then
#if(RACE_STATS) then
	elseif(room.isRace) then
		mapTypeCounter = 'racesPlayed'
#end
#if(DM_STATS) then
	elseif(mapType.name == 'DM') then
		mapTypeCounter = 'dmPlayed'
#end
#if(DD_STATS) then
	elseif(mapType.name == 'DD') then
		mapTypeCounter = 'ddPlayed'
#end
	end
	
	for el, player in pairs(g_Players) do
		player.accountData:add('mapsPlayed', 1)
		if(mapTypeCounter) then
			player.accountData:add(mapTypeCounter, 1)
		end
	end
	
	if(DdMapStart) then
		DdMapStart(room)
	end
end

-- Called from maps
function StMapStop(room)
	if(DdMapStop) then
		DdMapStop(room)
	end
end

function StPlayerWin(player)
	local room = player.room
	local map = getCurrentMap(room)
	local mapType = map and map:getType()
	local winCounter = false
	if(not mapType) then
		outputDebugString('unknown map type', 2)
#if(RACE_STATS) then
	elseif(room.isRace) then
		winCounter = 'raceVictories'
#end -- RACE_STATS
#if(DM_STATS) then
	elseif(mapType.name == 'DM') then
		winCounter = 'dmVictories'
#end -- DM_STATS
#if(DD_STATS) then
	elseif(mapType.name == 'DD') then
		winCounter = 'ddVictories'
#end -- DD_STATS
	end
	
	if(winCounter) then
		player.accountData:add(winCounter, 1)
	end
	
	if(room.winStreakPlayer == player.el) then
		room.winStreakLen = room.winStreakLen + 1
		if(g_PlayersCount > 1) then
			scriptMsg("%s is on a winning streak! It's his %u. victory.", player:getName(), room.winStreakLen)
		end
	else
		room.winStreakPlayer = player.el
		room.winStreakLen = 1
	end
	local maxStreak = player.accountData.maxWinStreak
	if(room.winStreakLen > maxStreak) then
		player.accountData.maxWinStreak = room.winStreakLen
	end
	
#if(DD_TOPS) then
	if(mapType and mapType.name == 'DD' and DdAddVictory) then
		DdAddVictory(player, map)
	end
#end -- DD_TOPS
end

-- Called from maps
function StHunterTaken(player)
#if(DM_STATS) then
	local map = getCurrentMap(player.room)
	local mapType = map and map:getType()
	
	if(not mapType or mapType.name ~= 'DM') then return end
	
	local ptsAdd = 5
	player.accountData:add('huntersTaken', 1)
	player.accountData:add('points', ptsAdd)
	
	player:addNotify{
		icon = 'stats/img/icon.png',
		{"You earned %s points. Total: %s.", formatNumber(ptsAdd), formatNumber(player.accountData.points)},
	}
#end
end

function StPlayerFinish(player, rank, ms)
	local room = player.room
	local map = getCurrentMap(player.room)
	local mapType = map and map:getType()
	if(not mapType) then return end
	
	if(room.isRace or rank == 1) then
#if(RACE_STATS) then
		if(room.isRace) then
			player.accountData:add('racesFinished', 1)
		end
#end
		
		local cashadd = math.floor(1000 * g_PlayersCount / rank)
		local pointsadd = math.floor(g_PlayersCount / rank)
		
		local stats = {}
		stats.cash = player.accountData.cash + cashadd
		stats.points = player.accountData.points + pointsadd
		player.accountData:set(stats)
		
		player:addNotify{
			icon = 'stats/img/coins.png',
			{"%s added to your cash! Total: %s.", formatMoney(cashadd), formatMoney(stats.cash)},
			{"You earned %s points. Total: %s.", formatNumber(pointsadd), formatNumber(stats.points)},
		}
	end
	
	if(rank == 1) then
		StPlayerWin(player)
	end
end

-- Called from core
function StSetupScoreboard(res)
	if(Settings.scoreboard_lvl) then
		call(res, 'scoreboardAddColumn', 'lvl', g_Root, 25, 'Lvl', false)
	end
	if(Settings.scoreboard_exp) then
		call(res, 'scoreboardAddColumn', 'exp', g_Root, 40, 'EXP', false)
	end
	if(Settings.scoreboard_cash) then
		call(res, 'scoreboardAddColumn', 'cash', g_Root, 70, 'Cash', false)
	end
end

local function StInit()
	if(StLoadRanks) then
		StLoadRanks()
	end
	
	for el, player in pairs(g_Players) do
		if(not player.is_console) then
			StUpdatePlayerScoreboardData(player)
		end
	end
	
	addSyncer('stats', StPlayerStatsSyncCallback)
	
	addEventHandler('onPlayerJoin', g_Root, StOnPlayerJoinOrLogin)
	addEventHandler('onPlayerLogin', g_Root, StOnPlayerJoinOrLogin)
	addEventHandler('onPlayerLogout', g_Root, StOnPlayerJoinOrLogin)
	addEventHandler('onPlayerWasted', g_Root, StOnPlayerWasted)
	addEventHandler('onVehicleExplode', g_Root, StOnVehicleExplode)
	table.insert(AccountData.onChangeHandlers, StAccountDataChange)
	table.insert(AccountData.onChangeDoneHandlers, StAccountDataChangeDone)
end

addInitFunc(StInit)
