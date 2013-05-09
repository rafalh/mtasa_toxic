local g_Ranks = {}
local g_Stats = {
	"cash", "points",
	"mapsPlayed", "mapsBought", "mapsRated",
	"dmVictories", "huntersTaken", "dmPlayed",
	"ddVictories", "ddPlayed",
	"raceVictories", "racesFinished", "racesPlayed",
	"maxWinStreak", "toptimes_count",
	"bidlvl", "time_here", "exploded", "drowned"}

PlayersTable:addColumns{
	-- Old stats
	{"cash",           "INT",                default = 0},
	{"points",         "MEDIUMINT",          default = 0},
	{"dm",             "MEDIUMINT UNSIGNED", default = 0},
	{"dm_wins",        "MEDIUMINT UNSIGNED", default = 0},
	{"first",          "MEDIUMINT UNSIGNED", default = 0},
	{"second",         "MEDIUMINT UNSIGNED", default = 0},
	{"third",          "MEDIUMINT UNSIGNED", default = 0},
	{"exploded",       "MEDIUMINT UNSIGNED", default = 0},
	{"drowned",        "MEDIUMINT UNSIGNED", default = 0},
	
	-- New stats
	{"maxWinStreak",  "SMALLINT UNSIGNED",  default = 0},
	{"mapsPlayed",    "MEDIUMINT UNSIGNED", default = 0},
	{"mapsBought",    "MEDIUMINT UNSIGNED", default = 0},
	{"mapsRated",     "SMALLINT UNSIGNED",  default = 0},
	{"huntersTaken",  "MEDIUMINT UNSIGNED", default = 0},
	{"dmVictories",   "MEDIUMINT UNSIGNED", default = 0},
	{"ddVictories",   "MEDIUMINT UNSIGNED", default = 0},
	{"raceVictories", "MEDIUMINT UNSIGNED", default = 0},
	{"racesFinished", "MEDIUMINT UNSIGNED", default = 0},
	{"dmPlayed",      "MEDIUMINT UNSIGNED", default = 0},
	{"ddPlayed",      "MEDIUMINT UNSIGNED", default = 0},
	{"racesPlayed",   "MEDIUMINT UNSIGNED", default = 0},
	{"achvCount",     "TINYINT UNSIGNED",   default = 0},
	
	-- Effectiveness
	{"efectiveness",      "FLOAT", default = 0},
	{"efectiveness_dd",   "FLOAT", default = 0},
	{"efectiveness_dm",   "FLOAT", default = 0},
	{"efectiveness_race", "FLOAT", default = 0},
}

local function StAccountDataChange(accountData, name, newValue)
	if(not table.find(g_Stats, name)) then return end -- not a stat
	
	local player = Player.fromId(accountData.id)
	
	if(player and name == "points") then
		setPlayerAnnounceValue(player.el, "score", tostring(newValue))
		
		local oldRank = StRankFromPoints(accountData:get("points"))
		local newRank = StRankFromPoints(newValue)
		if(newRank ~= oldRank) then
			outputMsg(g_Root, Styles.stats, "%s has new rank: %s!", player:getName(), newRank)
		end
	end
	
	if(player) then
		AchvCheckPlayer(player.el)
	end
	
	notifySyncerChange("stats", accountData.id)
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

local function StPlayerStatsSyncCallback(idOrPlayer)
	local id = touint(idOrPlayer)
	local player = Player.fromId(id) or Player.fromEl(idOrPlayer)
	
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
	data.name = data.name:gsub("#%x%x%x%x%x%x", "")
	return data
end

local function StLoadRanks()
	local node, i = xmlLoadFile("conf/ranks.xml"), 0
	if(not node) then return false end
	
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
	return true
end

local function StOnPlayerConnect(playerNick, playerIP, playerUsername, playerSerial)
	local max_warns = Settings.max_warns
	if(max_warns > 0) then
		local rows = DbQuery("SELECT warnings FROM "..PlayersTable.." WHERE serial=? LIMIT 1", playerSerial)
		local data = rows and rows[1]
		if(data and data.warnings > max_warns) then
			cancelEvent(true, "You have "..data.warnings.." warnings (limit: "..max_warns..")!")
		end
	end
end

local function StOnPlayerJoin()
	local player = Player.fromEl(source)
	local pts = player.accountData:get("points")
	setPlayerAnnounceValue(source, "score", tostring(pts))
end

local function StOnPlayerWasted(totalAmmo, killer, weapon)
	local player = Player.fromEl(source)
	if(wasEventCancelled() or not player) then return end
	
	if(weapon == 53) then -- drowned
		player.accountData:add("drowned", 1)
	end
end

local function StOnVehicleExplode()
	local playerEl = getVehicleOccupant(source)
	local player = playerEl and Player.fromEl(playerEl)
	if(wasEventCancelled() or not player) then return end
	
	-- Note: Blow in Admin Panel generates two onVehicleExplode but only one has health > 0
	if(getElementHealth(source) > 0) then
		player.accountData:add("exploded", 1)
	end
end

local function StInit()
	StLoadRanks()
	
	for player, pdata in pairs(g_Players) do
		local pts = pdata.accountData:get("points")
		if(not pdata.is_console) then
			setPlayerAnnounceValue(player, "score", tostring(pts))
		end
	end
	
	addSyncer("stats", StPlayerStatsSyncCallback)
	
	addEventHandler("onPlayerConnect", g_Root, StOnPlayerConnect)
	addEventHandler("onPlayerJoin", g_Root, StOnPlayerJoin)
	addEventHandler("onPlayerWasted", g_Root, StOnPlayerWasted)
	addEventHandler("onVehicleExplode", g_Root, StOnVehicleExplode)
	table.insert(AccountData.onChangeHandlers, StAccountDataChange)
end

addInitFunc(StInit)
