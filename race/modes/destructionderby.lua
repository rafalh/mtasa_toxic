DestructionDerby = setmetatable({}, RaceMode)
DestructionDerby.__index = DestructionDerby

DestructionDerby:register('Destruction derby')

function DestructionDerby:isDmWinningVeh ( veh_type )
	veh_type = tonumber ( veh_type )
	return ( veh_type == 520 or veh_type == 425 or veh_type == 464 or veh_type == 447 )
end

function DestructionDerby:isDeathMatch ()
	local mapName = g_MapInfo.name
	local mapType = mapName:match("^%[(%w+)%].+$")
	if(mapType) then
		return (mapType:lower() == "dm")
	end
	
	for i, pickup in ipairs ( getElementsByType ( "racepickup" ) ) do
		if ( getElementData ( pickup, "type" ) == "vehiclechange" ) then
			local veh_type = tonumber ( getElementData ( pickup, "vehicle" ) )
			if ( self:isDmWinningVeh ( veh_type ) ) then
				return true
			end
		end
	end
	
	return false
end

function DestructionDerby:isApplicable()
	self.dm = self:isDeathMatch ()
	return not RaceMode.checkpointsExist() and RaceMode.getMapOption('respawn') == 'none'
end

function DestructionDerby:getPlayerRank(player)
	return #getActivePlayers()
end

-- Copy of old updateRank
function DestructionDerby:updateRanks()
	for i,player in ipairs(g_Players) do
		if not isPlayerFinished(player) then
			local rank = self:getPlayerRank(player)
			if not rank or rank > 0 then
				setElementData(player, 'race rank', rank)
			end
		end
	end
	-- Make text look good at the start
	if not self.running then
		for i,player in ipairs(g_Players) do
			setElementData(player, 'race rank', '' )
			setElementData(player, 'checkpoint', '' )
		end
	end
end

function DestructionDerby:onPlayerWasted(player)
	if isActivePlayer(player) then
		self:handleFinishActivePlayer(player)
		if getActivePlayerCount() <= ( self.dm and 0 or 1 ) then
			RaceMode.endMap()
		else
			TimerManager.createTimerFor("map",player):setTimer(clientCall, 2000, 1, player, 'Spectate.start', 'auto')
		end
	end
	RaceMode.setPlayerIsFinished(player)
	showBlipsAttachedTo(player, false)
end

function DestructionDerby:onPlayerQuit(player)
	if isActivePlayer(player) then
		self:handleFinishActivePlayer(player)
		if getActivePlayerCount() <= ( self.dm and 0 or 1 ) then
			RaceMode.endMap()
		end
	end
end

addEvent( "onPlayerWinDD" )
addEvent( "onPlayerFinishDD" )
function DestructionDerby:handleFinishActivePlayer(player)
	local timePassed = self:getTimePassed()
	triggerEvent("onPlayerFinishDD", player, self:getPlayerRank(player), timePassed)
	-- Do remove
	finishActivePlayer(player)
	-- Update ranking board if one player left
	local activePlayers = getActivePlayers()
	if #activePlayers == 1 then
		triggerEvent("onPlayerWinDD", activePlayers[1])
		triggerEvent("onPlayerFinishDD", activePlayers[1], self:getPlayerRank(player), timePassed)
		showMessage(getPlayerName(activePlayers[1]) .. ' is the final survivor!', 0, 255, 0)
	end
end

function DestructionDerby:onPlayerPickUpRacePickup ( pickupID, type, vehicle )
	if ( self.dm and self:isDmWinningVeh ( vehicle ) ) then
		if ( getActivePlayerCount () == 1 ) then
			RaceMode.endMap ()
		end
		self.dm = false -- end the game if one player left
	end
end


------------------------------------------------------------
-- activePlayerList stuff
--

function isActivePlayer( player )
	return table.find( g_CurrentRaceMode.activePlayerList, player )
end

function addActivePlayer( player )
	table.insertUnique( g_CurrentRaceMode.activePlayerList, player )
end

function removeActivePlayer( player )
	table.removevalue( g_CurrentRaceMode.activePlayerList, player )
end

function finishActivePlayer( player )
	table.removevalue( g_CurrentRaceMode.activePlayerList, player )
	table.insertUnique( g_CurrentRaceMode.finishedPlayerList, _getPlayerName(player) )
end

function getFinishedPlayerCount()
	return #g_CurrentRaceMode.finishedPlayerList
end

function getActivePlayerCount()
	return #g_CurrentRaceMode.activePlayerList
end

function getActivePlayers()
	return g_CurrentRaceMode.activePlayerList
end
