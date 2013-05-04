g_Teams = {} -- used by admin_s.lua
g_TeamFromName = {}
g_TeamFromID = {}
local g_Patterns = { -- -FoH-S#808080treetch
	"^%[([^%]][^%]]?[^%]]?[^%]]?[^%]]?[^%]]?)%]",
	"^%(([^%)][^%)]?[^%)]?[^%)]?[^%)]?[^%)]?)%)",
	"^%-|?([^|][^|]?[^|]?[^|]?[^|]?[^|]?)|%-",
	"^~([^~][^~]?[^~]?[^~]?[^~]?[^~]?)~",
	"^%-?([^-][^-]?[^-]?[^-]?[^-]?[^-]?)%-",
	"^<([^>][^>]?[^>]?[^>]?[^>]?[^>]?)>",
	"^|?([^|][^|]?[^|]?[^|]?[^|]?[^|]?)|",
	"^#?([^#][^#]?[^#]?[^#]?[^#]?[^#]?)#",
	"^=([^=][^=]?[^=]?[^=]?[^=]?[^=]?)=",
	"^>([^<][^<]?[^<]?[^<]?[^<]?[^<]?)<",
}

addEvent("onPlayerChangeTeam")

local function TmGetClanFromName(name)
	name = name:gsub("#%x%x%x%x%x%x", "")
	
	for i, pattern in ipairs(g_Patterns) do
		local tag = name:match(pattern)
		if(tag) then
			return tag
		end
	end
	
	return false
end

local function TmUpdatePlayerTeam(player, name)
	local account = getPlayerAccount(player)
	local accName = account and getAccountName(account)
	if(not name) then
		name = getPlayerName(player)
	end
	local clanTag = TmGetClanFromName(name)
	local foundTeamInfo = false
	
	for i, teamInfo in ipairs(g_Teams) do
		if(teamInfo.aclGroup ~= "" and accName and isObjectInACLGroup("user."..accName, aclGetGroup(teamInfo.aclGroup))) then
			foundTeamInfo = teamInfo
			break
		end
		if(teamInfo.tag ~= "" and clanTag == teamInfo.tag) then
			foundTeamInfo = teamInfo
			break
		end
	end
	
	if(not foundTeamInfo and Settings.clan_teams and clanTag and not g_TeamFromName[clanTag]) then
		foundTeamInfo = {name = clanTag}
	end
	
	if(foundTeamInfo) then
		local now = getRealTime().timestamp
		DbQuery("UPDATE "..DbPrefix.."teams SET lastUsage=? WHERE id=?", now, foundTeamInfo.id)
		local team = getTeamFromName(foundTeamInfo.name)
		if(not team) then
			local r, g, b = getColorFromString(foundTeamInfo.color)
			if(not r) then
				r, g, b = math.random(0, 255), math.random(0, 255), math.random(0, 255)
			end
			team = createTeam(foundTeamInfo.name, r, g, b)
		end
		setPlayerTeam(player, team)
	end
end

local function TmUpdateTeams()
	for i, team in ipairs(getElementsByType("team", g_ResRoot)) do
		if(countPlayersInTeam(team) == 0) then -- in team there was only source player
			destroyElement(team)
		end
	end
end

local function TmDetectTeamChange()
	for player, pdata in pairs(g_Players) do
		local team = not pdata.is_console and getPlayerTeam(player)
		if(team ~= pdata.team) then
			pdata.team = team
			triggerEvent("onPlayerChangeTeam", player, team)
		end
	end
end

local function TmOnPlayerLogout()
	setPlayerTeam(source, nil)
	TmUpdatePlayerTeam(source)
	TmUpdateTeams()
end

local function TmOnPlayerJoinLogin()
	TmUpdatePlayerTeam(source)
	TmUpdateTeams()
end

local function TmOnPlayerChangeNick(oldNick, newNick)
	TmUpdatePlayerTeam(source, newNick)
	TmUpdateTeams()
end

local function TmOnPlayerQuit ()
	setPlayerTeam(source, nil)
	TmUpdateTeams()
end

function TmInitDatabase()
	local autoInc = DbGetType() == "mysql" and "AUTO_INCREMENT" or "AUTOINCREMENT"
	if(not DbQuery(
			"CREATE TABLE IF NOT EXISTS "..DbPrefix.."teams ("..
			"id INTEGER PRIMARY KEY "..autoInc.." NOT NULL,"..
			"name VARCHAR(255) NOT NULL,"..
			"tag VARCHAR(255) DEFAULT '' NOT NULL,"..
			"aclGroup VARCHAR(255) DEFAULT '' NOT NULL,"..
			"color VARCHAR(7) DEFAULT '' NOT NULL,"..
			"priority INT NOT NULL,"..
			"lastUsage INT UNSIGNED DEFAULT 0 NOT NULL)")) then
		return false, "Cannot create teams table."
	end
	
	return true
end

local function TmLoadFromXML()
	local node, i = xmlLoadFile("conf/teams.xml"), 0
	if(not node) then return false end
	
	local teams = {}
	while(true) do
		local subnode = xmlFindChild(node, "team", i)
		if(not subnode) then break end
		i = i + 1
		
		local team = {}
		team.name = tostring(xmlNodeGetAttribute(subnode, "name"))
		team.tag = xmlNodeGetAttribute(subnode, "clan") or ""
		team.aclGroup = xmlNodeGetAttribute(subnode, "acl_group") or ""
		team.color = xmlNodeGetAttribute(subnode, "color") or ""
		if(team.aclGroup or team.tag) then
			table.insert(teams, team)
		else
			outputDebugString("Invalid team definition", 2)
		end
	end
	xmlUnloadFile(node)
	return teams
end

local function TmInitDelayed()
	if(not TmInitDatabase()) then return end
	
	local oldTeams = TmLoadFromXML()
	if(oldTeams) then
		fileDelete("conf/teams.xml")
		local cnt = DbQuery("SELECT COUNT(id) AS c FROM "..DbPrefix.."teams")[1].c
		for i, teamInfo in ipairs(oldTeams) do
			if(not DbQuery("INSERT INTO "..DbPrefix.."teams (name, tag, aclGroup, color, priority) VALUES(?, ?, ?, ?, ?)",
				teamInfo.name, teamInfo.tag, teamInfo.aclGroup, teamInfo.color, cnt + 1)) then break end
			cnt = cnt + 1
		end
	end
	g_Teams = DbQuery("SELECT * FROM "..DbPrefix.."teams ORDER BY priority")
	
	for i, teamInfo in ipairs(g_Teams) do
		g_TeamFromName[teamInfo.name] = teamInfo
		g_TeamFromID[teamInfo.id] = teamInfo
	end
	
	for player, pdata in pairs(g_Players) do
		pdata.team = false
		TmUpdatePlayerTeam(player)
	end
	
	setTimer(TmDetectTeamChange, 1000, 0)
	
	addEventHandler("onPlayerJoin", g_Root, TmOnPlayerJoinLogin)
	addEventHandler("onPlayerLogin", g_Root, TmOnPlayerJoinLogin)
	addEventHandler("onPlayerLogout", g_Root, TmOnPlayerLogout)
	addEventHandler("onPlayerChangeNick", g_Root, TmOnPlayerChangeNick)
	addEventHandler("onPlayerQuit", g_Root, TmOnPlayerQuit)
end

local function TmInit()
	-- Don't setup teams in onResourceStart event - see MTA bug #6861
	setTimer(TmInitDelayed, 50, 1)
end

addInitFunc(TmInit)
