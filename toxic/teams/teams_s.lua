Teams = {}
Teams.list = {} -- used by admin_s.lua
Teams.fromName = {}
Teams.fromID = {}
Teams.autoFromName = {}
local g_Patterns = {
	'^%[([^%]][^%]]?[^%]]?[^%]]?[^%]]?[^%]]?)%]',
	'^%(([^%)][^%)]?[^%)]?[^%)]?[^%)]?[^%)]?)%)',
	'^%-|?([^|][^|]?[^|]?[^|]?[^|]?[^|]?)|%-',
	'^~([^~][^~]?[^~]?[^~]?[^~]?[^~]?)~',
	'^%-?([^-][^-]?[^-]?[^-]?[^-]?[^-]?)%-',
	'^<([^>][^>]?[^>]?[^>]?[^>]?[^>]?)>',
	'^|?([^|][^|]?[^|]?[^|]?[^|]?[^|]?)|',
	'^#?([^#][^#]?[^#]?[^#]?[^#]?[^#]?)#',
	'^=([^=][^=]?[^=]?[^=]?[^=]?[^=]?)=',
	'^>([^<][^<]?[^<]?[^<]?[^<]?[^<]?)<',
}

local g_NameToTeam = {}

TeamsTable = Database.Table{
	name = 'teams',
	{'id', 'INT UNSIGNED', pk = true},
	{'name', 'VARCHAR(255)'},
	{'tag', 'VARCHAR(255)', default = ''},
	{'aclGroup', 'VARCHAR(255)', default = ''},
	{'color', 'VARCHAR(7)', default = ''},
	{'priority', 'INT'},
	{'lastUsage', 'INT UNSIGNED', default = 0},
}

addEvent('onPlayerChangeTeam')

local function Teams_getClanFromName(name)
	name = name:gsub('#%x%x%x%x%x%x', '')
	
	for i, pattern in ipairs(g_Patterns) do
		local tag = name:match(pattern)
		if(tag) then
			return tag
		end
	end
	
	return false
end

local function Teams_findTeamForPlayer(player, name)
	local account = getPlayerAccount(player)
	local accName = account and getAccountName(account)
	if(not name) then
		name = getPlayerName(player)
	end
	local clanTag = Teams_getClanFromName(name)
	
	-- Find team for specified player
	for i, teamInfo in ipairs(Teams.list) do
		if(teamInfo.aclGroup ~= '' and accName and isObjectInACLGroup('user.'..accName, aclGetGroup(teamInfo.aclGroup))) then
			return teamInfo
		end
		if(teamInfo.tag ~= '' and clanTag == teamInfo.tag) then
			return teamInfo
		end
	end
	
	if(not clanTag or not Settings.clan_teams) then
		-- Clan tag cannot create a team
		return false
	end
	
	local teamInfo = Teams.fromName[clanTag]
	if(teamInfo) then
		-- Don't allow teams from database here
		return false
	end
	
	local teamInfo = Teams.autoFromName[clanTag]
	if(not teamInfo) then
		teamInfo = {name = clanTag}
		Teams.autoFromName[clanTag] = teamInfo
	end
	
	return teamInfo
end

local function Teams_createTeamFromInfo(teamInfo)
	if(isElement(teamInfo.el)) then
		destroyElement(teamInfo.el)
	end
	
	teamInfo.el = getTeamFromName(teamInfo.name)
	if(not teamInfo.el) then
		-- Create team
		local r, g, b
		if(teamInfo.color) then
			r, g, b = getColorFromString(teamInfo.color)
		end
		if(not r) then
			r, g, b = math.random(0, 255), math.random(0, 255), math.random(0, 255)
		end
		
		teamInfo.el = createTeam(teamInfo.name, r, g, b)
	end
	
	return teamInfo.el
end

local function Teams_removePlayerFromTeam(player)
	local pdata = Player.fromEl(player)
	local teamInfo = pdata.teamInfo or false
	if(not teamInfo) then return end
	
	setPlayerTeam(player, nil)
	
	teamInfo.count = teamInfo.count - 1
	if(teamInfo.count < Settings.min_team) then
		if(isElement(teamInfo.el)) then
			destroyElement(teamInfo.el)
		end
		teamInfo.el = false
	end
	if(teamInfo.count == 0 and not teamInfo.id) then
		Teams.autoFromName[teamInfo.name] = nil
	end
end

local function Teams_updatePlayerTeam(player, name)
	local pdata = Player.fromEl(player)
	local teamInfo = Teams_findTeamForPlayer(player, name)
	
	local oldTeamInfo = pdata.teamInfo or false
	if(oldTeamInfo == teamInfo) then
		-- Nothing has changed
		return
	end
	
	Teams_removePlayerFromTeam(player)
	
	pdata.teamInfo = teamInfo
	if(not teamInfo) then return end
	
	teamInfo.count = (teamInfo.count or 0) + 1
	
	if(teamInfo.id) then
		-- Update last team usage field
		local now = getRealTime().timestamp
		teamInfo.lastUsage = now
		DbQuery('UPDATE '..TeamsTable..' SET lastUsage=? WHERE id=?', now, teamInfo.id)
	end
	
	-- Create team if needed
	local created = false
	if(not isElement(teamInfo.el) and teamInfo.count >= Settings.min_team) then
		--outputDebugString('Creating team '..teamInfo.name, 3)
		created = Teams_createTeamFromInfo(teamInfo) and true
	end
	
	if(isElement(teamInfo.el)) then
		if(created) then
			-- Find all players for this team
			for player, pdata in pairs(g_Players) do
				if(pdata.teamInfo == teamInfo) then
					setPlayerTeam(player, teamInfo.el)
				end
			end
		else
			-- Update only current player
			setPlayerTeam(player, teamInfo.el)
		end
	end
end

local function Teams_destroyEmpty()
	for i, team in ipairs(getElementsByType('team', g_ResRoot)) do
		if(countPlayersInTeam(team) == 0) then -- in team there was only source player
			outputDebugString('Destroying team '..getTeamName(team), 3)
			destroyElement(team)
		end
	end
end

local function Teams_detectTeamChange()
	for player, pdata in pairs(g_Players) do
		local team = not pdata.is_console and getPlayerTeam(player)
		if(team ~= pdata.team) then
			pdata.team = team
			triggerEvent('onPlayerChangeTeam', player, team)
		end
	end
end

local function Teams_onPlayerLogout()
	setPlayerTeam(source, nil)
	Teams_updatePlayerTeam(source)
	--Teams_destroyEmpty()
end

local function Teams_onPlayerJoinLogin()
	Teams_updatePlayerTeam(source)
	--Teams_destroyEmpty()
end

local function Teams_onPlayerChangeNick(oldNick, newNick)
	Teams_updatePlayerTeam(source, newNick)
	--Teams_destroyEmpty()
end

local function Teams_onPlayerQuit()
	Teams_removePlayerFromTeam(source)
	--Teams_destroyEmpty()
end

local function Teams_loadFromXML()
	local node, i = xmlLoadFile('conf/teams.xml'), 0
	if(not node) then return false end
	
	local teams = {}
	while(true) do
		local subnode = xmlFindChild(node, 'team', i)
		if(not subnode) then break end
		i = i + 1
		
		local team = {}
		team.name = tostring(xmlNodeGetAttribute(subnode, 'name'))
		team.tag = xmlNodeGetAttribute(subnode, 'clan') or ''
		team.aclGroup = xmlNodeGetAttribute(subnode, 'acl_group') or ''
		team.color = xmlNodeGetAttribute(subnode, 'color') or ''
		if(team.aclGroup or team.tag) then
			table.insert(teams, team)
		else
			outputDebugString('Invalid team definition', 2)
		end
	end
	xmlUnloadFile(node)
	return teams
end

function Teams.updateAllPlayers()
	for player, pdata in pairs(g_Players) do
		Teams_updatePlayerTeam(player)
	end
	--Teams_destroyEmpty()
end
RPC.allow('Teams.updateAllPlayers')

local function Teams_initDelayed()
	Teams.updateAllPlayers()
	setTimer(Teams_detectTeamChange, 1000, 0)
end

local function Teams_init()
	local oldTeams = Teams_loadFromXML()
	if(oldTeams) then
		fileDelete('conf/teams.xml')
		local cnt = DbQuery('SELECT COUNT(id) AS c FROM '..TeamsTable)[1].c
		for i, teamInfo in ipairs(oldTeams) do
			if(not DbQuery('INSERT INTO '..TeamsTable..' (name, tag, aclGroup, color, priority) VALUES(?, ?, ?, ?, ?)',
				teamInfo.name, teamInfo.tag, teamInfo.aclGroup, teamInfo.color, cnt + 1)) then break end
			cnt = cnt + 1
		end
	end
	Teams.list = DbQuery('SELECT * FROM '..TeamsTable..' ORDER BY priority')
	
	for i, teamInfo in ipairs(Teams.list) do
		Teams.fromName[teamInfo.name] = teamInfo
		Teams.fromID[teamInfo.id] = teamInfo
	end
	
	for player, pdata in pairs(g_Players) do
		pdata.team = false
	end
	
	addEventHandler('onPlayerJoin', g_Root, Teams_onPlayerJoinLogin)
	addEventHandler('onPlayerLogin', g_Root, Teams_onPlayerJoinLogin)
	addEventHandler('onPlayerLogout', g_Root, Teams_onPlayerLogout)
	addEventHandler('onPlayerChangeNick', g_Root, Teams_onPlayerChangeNick)
	addEventHandler('onPlayerQuit', g_Root, Teams_onPlayerQuit)
	
	-- Don't setup teams in onResourceStart event - see MTA bug #6861
	setTimer(Teams_initDelayed, 50, 1)
end

addInitFunc(Teams_init)
