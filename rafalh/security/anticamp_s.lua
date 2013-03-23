local function AcmpClear(player)
	local pdata = g_Players[player]
	if(pdata.camp) then
		if(pdata.camp[2]) then
			removeScreenMsg(pdata.camp[2], player)
		end
		pdata.camp = nil
	end
end

local function AcmpCheckPlayer(player)
	local kill_afk = SmGetUInt("kill_afk", 0)
	local room = g_Players[player].room
	local currentMap = getCurrentMap(room)
	if(kill_afk == 0 or currentMap and currentMap:getRespawn()) then
		AcmpClear(player)
		return false
	end
	
	if(g_PlayersCount <= 1 or isPedDead(player)) then
		AcmpClear(player)
		return false
	end
	
	local race_res = getResourceFromName("race")
	if(race_res and getResourceState(race_res) == "running" and (call(race_res, "getTimePassed") or 0) <= 0) then
		AcmpClear(player)
		return false
	end
	
	local pdata = g_Players[player]
	local camp = pdata.camp
	local old_pos = pdata.camp_pos
	local pos = {getElementPosition(player)}
	
	if(old_pos and getDistanceBetweenPoints3D(old_pos[1], old_pos[2], old_pos[3], pos[1], pos[2], pos[3]) < 0.1) then --did not moved
		if(not camp) then
			camp = { getTickCount (), nil }
		elseif(getTickCount () - camp[1] > kill_afk * 1000) then
			setElementHealth(player, 0)
			privMsg(player, "You got killed for camping!")
		elseif(getTickCount () - camp[1] > kill_afk * 1000 - 10000 and not camp[2]) then
			camp[2] = addScreenMsg("Do not camp or you will be killed!", player)
		end
	elseif(camp) then
		if(camp[2]) then
			removeScreenMsg(camp[2], player)
		end
		camp = nil
	end
	
	pdata.camp = camp
	pdata.camp_pos = pos
	
	return false
end

local function AcmpCheckAllPlayers()
	for player, pdata in pairs(g_Players) do
		if(not pdata.is_console) then
			AcmpCheckPlayer(player)
		end
	end
end

local function AcmpInit ()
	setTimer(AcmpCheckAllPlayers, 1000, 0)
end

addEventHandler("onResourceStart", g_ResRoot, AcmpInit)
