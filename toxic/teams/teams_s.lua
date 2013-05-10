Teams = {}
Teams.list = {} -- used by admin_s.lua
Teams.fromName = {}
Teams.fromID = {}
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

TeamsTable = Database.Table{
	name = "teams",
	{"id", "INT UNSIGNED", pk = true},
	{"name", "VARCHAR(255)"},
	{"tag", "VARCHAR(255)", default = ""},
	{"aclGroup", "VARCHAR(255)", default = ""},
	{"color", "VARCHAR(7)", default = ""},
	{"priority", "INT"},
	{"lastUsage INT UNSIGNED DEFAULT 0", default = 0},
}

addEvent("onPlayerChangeTeam")

local function Teams_getClanFromName(name)
	name = name:gsub("#%x%x%x%x%x%x", "")
	
	for i, pattern in ipairs(g_Patterns) do
		local tag = name:match(pattern)
		if(tag) then
			return tag
		end
	end
	
	return false
end

local function Teams_updatePlayerTeam(player, name)
	local account = getPlayerAccount(player)
	local accName = account and getAccountName(account)
	if(not name) then
		name = getPlayerName(player)
	end
	local clanTag = Teams_getClanFromName(name)
	local foundTeamInfo = false
	
	for i, teamInfo in ipairs(Teams.list) do
		if(teamInfo.aclGroup ~= "" and accName and isObjectInACLGroup("user."..accName, aclGetGroup(teamInfo.aclGroup))) then
			foundTeamInfo = teamInfo
			break
		end
		if(teamInfo.tag ~= "" and clanTag == teamInfo.tag) then
			foundTeamInfo = teamInfo
			break
		end
	end
	
	if(not foundTeamInfo and Settings.clan_teams and clanTag and not Teams.fromName[clanTag]) then
		foundTeamInfo = {name = clanTag}
	end
	
	if(foundTeamInfo) then
		local now = getRealTime().timestamp
		DbQuery("UPDATE "..TeamsTable.." SET lastUsage=? WHERE id=?", now, foundTeamInfo.id)
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

local function Teams_destroyEmpty()
	for i, team in ipairs(getElementsByType("team", g_ResRoot)) do
		if(countPlayersInTeam(team) == 0) then -- in team there was only source player
			destroyElement(team)
		end
	end
end

local function Teams_detectTeamChange()
	for player, pdata in pairs(g_Players) do
		local team = not pdata.is_console and getPlayerTeam(player)
		if(team ~= pdata.team) then
			pdata.team = team
			triggerEvent("onPlayerChangeTeam", player, team)
		end
	end
end

local function Teams_onPlayerLogout()
	setPlayerTeam(source, nil)
	Teams_updatePlayerTeam(source)
	Teams_destroyEmpty()
end

local function Teams_onPlayerJoinLogin()
	Teams_updatePlayerTeam(source)
	Teams_destroyEmpty()
end

local function Teams_onPlayerChangeNick(oldNick, newNick)
	Teams_updatePlayerTeam(source, newNick)
	Teams_destroyEmpty()
end

local function Teams_onPlayerQuit()
	setPlayerTeam(source, nil)
	Teams_destroyEmpty()
end

local function Teams_loadFromXML()
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

function Teams.updateAllPlayers()
	for player, pdata in pairs(g_Players) do
		Teams_updatePlayerTeam(player)
	end
	Teams_destroyEmpty()
end
allowRPC('Teams.updateAllPlayers')

local function Teams_initDelayed()
	local oldTeams = Teams_loadFromXML()
	if(oldTeams) then
		fileDelete("conf/teams.xml")
		local cnt = DbQuery("SELECT COUNT(id) AS c FROM "..TeamsTable)[1].c
		for i, teamInfo in ipairs(oldTeams) do
			if(not DbQuery("INSERT INTO "..TeamsTable.." (name, tag, aclGroup, color, priority) VALUES(?, ?, ?, ?, ?)",
				teamInfo.name, teamInfo.tag, teamInfo.aclGroup, teamInfo.color, cnt + 1)) then break end
			cnt = cnt + 1
		end
	end
	Teams.list = DbQuery("SELECT * FROM "..TeamsTable.." ORDER BY priority")
	
	for i, teamInfo in ipairs(Teams.list) do
		Teams.fromName[teamInfo.name] = teamInfo
		Teams.fromID[teamInfo.id] = teamInfo
	end
	
	for player, pdata in pairs(g_Players) do
		pdata.team = false
	end
	
	Teams.updateAllPlayers()
	setTimer(Teams_detectTeamChange, 1000, 0)
	
	addEventHandler("onPlayerJoin", g_Root, Teams_onPlayerJoinLogin)
	addEventHandler("onPlayerLogin", g_Root, Teams_onPlayerJoinLogin)
	addEventHandler("onPlayerLogout", g_Root, Teams_onPlayerLogout)
	addEventHandler("onPlayerChangeNick", g_Root, Teams_onPlayerChangeNick)
	addEventHandler("onPlayerQuit", g_Root, Teams_onPlayerQuit)
end

local function Teams_init()
	-- Don't setup teams in onResourceStart event - see MTA bug #6861
	setTimer(Teams_initDelayed, 50, 1)
end

addInitFunc(Teams_init)
