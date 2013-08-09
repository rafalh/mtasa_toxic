addEvent('stats.onDDKillersList', true)

local function onKillersList(killer, assist)
	local victimPlayer = Player.fromEl(client)
	local killerPlayer = Player.fromEl(killer)
	local assistPlayer = assist and Player.fromEl(assist)
	
	local map = victimPlayer and getCurrentMap(victimPlayer.room)
	if(not victimPlayer or not killerPlayer or not map
		or killerPlayer == victimPlayer or assistPlayer == victimPlayer) then
		outputDebugString('Invalid args for onKillersList', 2)
		return
	end
	
	outputDebugString('KillersInfo '..victimPlayer:getName()..' '..tostring(victimPlayer:isAlive()), 3)
	
	local respawn = map and map:getRespawn()
	if(not respawn and victimPlayer:isAlive()) then
		outputDebugString('Ignoring killer info - client alive: '..tostring(victimPlayer:getName()), 2)
		return
	end
	
	if(map.isRace or map:getType().name ~= 'DD') then
		outputDebugString('Wrong map type: '..map:getType().name.." "..map:getName(), 2)
		return
	end
	
	if(victimPlayer.killed) then
		outputDebugString('Player is not allowed to send killer info again', 2)
		return
	elseif(not respawn) then
		victimPlayer.killed = true
	end
	
	--local killerLvl = LvlFromExp(killerPlayer.accountData.exp)
	victimPlayer:addNotify{
		icon = 'stats/img/skull.png',
		{"You have been killed by %s", killerPlayer:getName()}}
	
	--local victimExp = victimPlayer.accountData.exp
	--local victimLvl = LvlFromExp(victimExp)
	--local expBonus = math.floor(victimLvl^0.5*5)
	
	killerPlayer:addNotify{
		icon = 'stats/img/skull.png',
		{"You have killed %s", victimPlayer:getName()}}
	--killerPlayer.accountData:add('exp', expBonus)
	--killerPlayer.accountData:add('kills', 1)
	killerPlayer.currentMapKills = (killerPlayer.currentMapKills or 0) + 1
	
	if(assistPlayer) then
		--local expBonus = math.floor(expBonus/2)
		assistPlayer:addNotify{
			icon = 'stats/img/skull.png',
			{"You have killed %s (assist)", victimPlayer:getName()}}
		--assistPlayer.accountData:add('exp', expBonus)
	end
end

local function onMapStop()
	for player, pdata in pairs(g_Players) do
		pdata.currentMapKills = 0
		pdata.killed = false
	end
end

local function onPlayerWasted()
	local player = Player.fromEl(source)
	local map = player and getCurrentMap(player.room)
	if(not map) then return end
	
	if(map:getType().name == 'DD') then
		RPC('DdGetKillers'):setClient(source):onResult(onKillersList):exec()
		outputDebugString('onPlayerWasted '..player:getName(), 3)
	end
end

addInitFunc(function()
	--addEventHandler('stats.onDDKillersList', resourceRoot, onKillersList)
	addEventHandler('onGamemodeMapStop', root, onMapStop)
	addEventHandler('onPlayerWasted', root, onPlayerWasted)
end)
