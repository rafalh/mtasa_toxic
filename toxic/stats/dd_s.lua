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
	
	local respawn = map and map:getRespawn()
	if(not respawn and victimPlayer:isAlive()) then
		outputDebugString('Ignoring killer info - client alive: '..tostring(victimPlayer:isAlive()), 2)
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
		icon = 'img/skull.png',
		{"You have been killed by %s", killerPlayer:getName()}}
	
	--local victimExp = victimPlayer.accountData.exp
	--local victimLvl = LvlFromExp(victimExp)
	--local expBonus = math.floor(victimLvl^0.5*5)
	
	killerPlayer:addNotify{
		icon = 'img/skull.png',
		{"You have killed %s and receive %s", victimPlayer:getName()}}
	--killerPlayer.accountData:add('exp', expBonus)
	--killerPlayer.accountData:add('kills', 1)
	killerPlayer.currentMapKills = (killerPlayer.currentMapKills or 0) + 1
	
	if(assistPlayer) then
		--local expBonus = math.floor(expBonus/2)
		assistPlayer:addNotify{
			icon = 'img/skull.png',
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

addInitFunc(function()
	addEventHandler('stats.onDDKillersList', resourceRoot, onKillersList)
	addEventHandler('onGamemodeMapStop', root, onMapStop)
end)
