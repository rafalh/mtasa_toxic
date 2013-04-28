g_Teams = {} -- used by admin_s.lua
g_TeamNameMap = {}
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
		if(teamInfo.acl_group and accName and isObjectInACLGroup("user."..accName, aclGetGroup(teamInfo.acl_group))) then
			foundTeamInfo = teamInfo
			break
		elseif(teamInfo.clan and clanTag == teamInfo.clan) then
			foundTeamInfo = teamInfo
			break
		end
	end
	
	if(not foundTeamInfo and Settings.clan_teams and clanTag and not g_TeamNameMap[clanTag]) then
		foundTeamInfo = {name = clanTag}
	end
	
	if(foundTeamInfo) then
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

local function TmInitDelayed()
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

local function TmLoad()
	local node, i = xmlLoadFile("conf/teams.xml"), 0
	if(not node) then return false end
	
	while(true) do
		local subnode = xmlFindChild(node, "team", i)
		if(not subnode) then break end
		i = i + 1
		
		local team = {}
		team.name = tostring(xmlNodeGetAttribute(subnode, "name"))
		team.acl_group = xmlNodeGetAttribute(subnode, "acl_group")
		team.clan = xmlNodeGetAttribute(subnode, "clan")
		team.color = xmlNodeGetAttribute(subnode, "color")
		if(team.acl_group or team.clan) then
			g_TeamNameMap[team.name] = team
			table.insert(g_Teams, team)
		else
			outputDebugString("Invalid team definition", 2)
		end
	end
	xmlUnloadFile(node)
	return true
end

function TmSave()
	local node = xmlCreateFile("conf/teams.xml", "teams")
	if(not node) then return false end
	
	for i, teamInfo in ipairs(g_Teams) do
		local subnode = xmlCreateChild(node, "team")
		if(teamInfo.name) then
			xmlNodeSetAttribute(subnode, "name", teamInfo.name)
		end
		if(teamInfo.acl_group) then
			xmlNodeSetAttribute(subnode, "acl_group", teamInfo.acl_group)
		end
		if(teamInfo.clan) then
			xmlNodeSetAttribute(subnode, "clan", teamInfo.clan)
		end
		if(teamInfo.color) then
			xmlNodeSetAttribute(subnode, "color", teamInfo.color)
		end
	end
	xmlSaveFile(node)
	xmlUnloadFile(node)
	return true
end

local function TmInit()
	if(not TmLoad()) then
		outputDebugString("Failed to load team definitions", 2)
		return
	end
	
	-- Don't setup teams in onResourceStart event - see MTA bug #6861
	setTimer(TmInitDelayed, 50, 1)
end

addInitFunc(TmInit)
