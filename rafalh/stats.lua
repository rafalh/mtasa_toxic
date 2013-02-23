local g_Ranks = {}
local g_Stats = {
	"cash", "points",
	"mapsPlayed", "mapsBought", "mapsRated",
	"dmVictories", "huntersTaken", "dmPlayed",
	"ddVictories", "ddPlayed",
	"raceVictories", "racesFinished", "racesPlayed",
	"maxWinStreak", "toptimes_count",
	"bidlvl", "time_here", "exploded", "drowned"}

function StGet(elOrId, name)
	assert(elOrId and name)
	outputDebugString("StGet is deprecated", 2)
	
	local accountData
	if(isElement(elOrId)) then
		accountData = g_Players[elOrId].accountData
	elseif(g_IdToPlayer[elOrId]) then
		local playerEl = g_IdToPlayer[elOrId]
		accountData = g_Players[playerEl].accountData
	else
		accountData = PlayerAccountData.create(elOrId)
	end
	
	return accountData:get(name)
end

function StSet(elOrId, name, value)
	assert(elOrId and name)
	outputDebugString("StSet is deprecated", 2)
	
	local accountData
	if(isElement(elOrId)) then
		accountData = g_Players[elOrId].accountData
	elseif(g_IdToPlayer[elOrId]) then
		local playerEl = g_IdToPlayer[elOrId]
		accountData = g_Players[playerEl].accountData
	else
		accountData = PlayerAccountData.create(elOrId)
	end
	
	accountData:set(name, value)
end

local function StAccountDataChange(accountData, name, newValue)
	if(not table.find(g_Stats, name)) then return end -- not a stat
	
	local player = g_IdToPlayer[accountData.id]
	
	if(player and name == "points") then
		setPlayerAnnounceValue(player, "score", tostring(newValue))
		
		local oldRank = StRankFromPoints(accountData:get("points"))
		local newRank = StRankFromPoints(newValue)
		if(newRank ~= oldRank) then
			customMsg(255, 255, 255, "%s has new rank: %s!", getPlayerName(player), newRank)
		end
	end
	
	if(player) then
		AchvCheckPlayer(player)
	end
	
	notifySyncerChange("stats", accountData.id)
end

function StAdd(elOrId, name, n)
	outputDebugString("StAdd is deprecated", 2)
	StSet(elOrId, name, StGet(elOrId, name) + n)
end

function StRankFromPoints(points)
	local pt = -1
	local rank = nil
	
	for pt_i, rank_i in pairs(g_Ranks) do
		if(pt_i > pt and pt_i <= points) then
			rank = rank_i
			pt = pt_i
		end
	end
	
	return rank or "none"
end

local function StPlayerStatsSyncCallback ( id )
	id = touint(id)
	if(id) then
		local data = PlayerAccountData.create(id):getTbl()
		if(data) then
			data._rank = StRankFromPoints(data.points)
			local player = g_IdToPlayer[id]
			if(player) then
				data._join_time = g_Players[player].join_time
			end
			data.name = data.name:gsub("#%x%x%x%x%x%x", "")
			return data
		end
	end
	
	return false
end

local function StInit ()
	local node, i = xmlLoadFile("conf/ranks.xml"), 0
	if(node) then
		while(true) do
			local subnode = xmlFindChild(node, "rank", i)
			if(not subnode) then break end
			i = i + 1
			
			local pts = touint(xmlNodeGetAttribute(subnode, "points" ), 0)
			local name = xmlNodeGetAttribute(subnode, "name")
			assert(name)
			g_Ranks[pts] = name
		end
		xmlUnloadFile(node)
	end
	
	for player, pdata in pairs(g_Players) do
		local pts = pdata.accountData:get("points")
		if(not pdata.is_console) then
			setPlayerAnnounceValue(player, "score", tostring(pts))
		end
	end
	
	addSyncer("stats", StPlayerStatsSyncCallback)
end

local function StCleanupPlayer(playerEl)
	local player = g_Players[playerEl]
	local now = getRealTime().timestamp
	local timeSpent = now - player.join_time
	local playTime = player.accountData:get("time_here") + timeSpent
	player.join_time = now
	player.accountData:set({time_here = playTime, last_visit = now})
end

local function StCleanup()
	for playerEl, player in pairs(g_Players) do
		StCleanupPlayer(playerEl)
	end
end

local function StOnPlayerJoin()
	local player = g_Players[source]
	local pts = player.accountData:get("points")
	setPlayerAnnounceValue(source, "score", tostring(pts))
end

local function StOnPlayerConnect(playerNick, playerIP, playerUsername, playerSerial)
	local max_warns = SmGetUInt("max_warns", 0)
	if(max_warns > 0) then
		local rows = DbQuery("SELECT warnings FROM rafalh_players WHERE serial=? LIMIT 1", playerSerial)
		local data = rows and rows[1]
		if(data and data.warnings > max_warns) then
			cancelEvent(true, "You have "..data.warnings.." warnings (limit: "..max_warns..")!")
		end
	end
end

local function StOnPlayerQuit()
	StCleanupPlayer(source)
end

local function StOnPlayerWasted(totalAmmo, killer, weapon)
	local player = g_Players[source]
	if(wasEventCancelled() or not player) then return end
	
	if(weapon == 53) then -- drowned
		player.accountData:add("drowned", 1)
	end
end

local function StOnVehicleExplode()
	local playerEl = getVehicleOccupant(source)
	local player = playerEl and g_Players[playerEl]
	if(wasEventCancelled() or not player) then return end
	
	-- Note: Blow in Admin Panel generates two onVehicleExplode but only one has health > 0
	if(getElementHealth(source) > 0) then
		player.accountData:add("exploded", 1)
	end
end

addEventHandler("onResourceStart", g_ResRoot, StInit)
addEventHandler("onResourceStop", g_ResRoot, StCleanup)
addEventHandler("onPlayerConnect", g_Root, StOnPlayerConnect)
addEventHandler("onPlayerJoin", g_Root, StOnPlayerJoin)
addEventHandler("onPlayerQuit", g_Root, StOnPlayerQuit)
addEventHandler("onPlayerWasted", g_Root, StOnPlayerWasted)
addEventHandler("onVehicleExplode", g_Root, StOnVehicleExplode)
table.insert(PlayerAccountData.onChangeHandlers, StAccountDataChange)
