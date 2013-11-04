namespace('Teams')

g_List = {} -- used by admin_s.lua
g_TeamFromName = {}
g_TeamFromID = {}
g_AutoTeamFromName = {}
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

local function getClanFromName(name)
	name = name:gsub('#%x%x%x%x%x%x', '')
	
	for i, pattern in ipairs(g_Patterns) do
		local tag = name:match(pattern)
		if(tag) then
			return tag
		end
	end
	
	return false
end

local function findTeamForPlayer(player, name)
	local account = getPlayerAccount(player)
	local accName = account and getAccountName(account)
	if(not name) then
		name = getPlayerName(player)
	end
	local clanTag = getClanFromName(name)
	
	-- Find team for specified player
	for i, teamInfo in ipairs(g_List) do
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
	
	local teamInfo = g_TeamFromName[clanTag]
	if(teamInfo) then
		-- Don't allow teams from database here
		return false
	end
	
	local teamInfo = g_AutoTeamFromName[clanTag]
	if(not teamInfo) then
		teamInfo = {name = clanTag}
		g_AutoTeamFromName[clanTag] = teamInfo
	end
	
	return teamInfo
end

local function createTeamFromInfo(teamInfo)
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

local function removePlayerFromTeam(player)
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
		g_AutoTeamFromName[teamInfo.name] = nil
	end
end

local function updatePlayerTeam(player, name)
	local pdata = Player.fromEl(player)
	if(not pdata) then return end -- happens when setPlayerNick is called in onPlayerJoin handler
	local teamInfo = findTeamForPlayer(player, name)
	
	local oldTeamInfo = pdata.teamInfo or false
	if(oldTeamInfo == teamInfo) then
		-- Nothing has changed
		return
	end
	
	removePlayerFromTeam(player)
	
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
		created = createTeamFromInfo(teamInfo) and true
	end
	
	if(isElement(teamInfo.el)) then
		if(created) then
			-- Find all players for this team
			for player, pdata in pairs(g_Players) do
				if(not pdata.is_console and pdata.teamInfo == teamInfo) then
					assert(isElement(player))
					setPlayerTeam(player, teamInfo.el)
				end
			end
		else
			-- Update only current player
			setPlayerTeam(player, teamInfo.el)
		end
	end
end

local function destroyEmptyTeams()
	for i, team in ipairs(getElementsByType('team', g_ResRoot)) do
		if(countPlayersInTeam(team) == 0) then -- in team there was only source player
			outputDebugString('Destroying team '..getTeamName(team), 3)
			destroyElement(team)
		end
	end
end

local function detectTeamChange()
	for player, pdata in pairs(g_Players) do
		local team = not pdata.is_console and getPlayerTeam(player)
		if(team ~= pdata.team) then
			pdata.team = team
			triggerEvent('onPlayerChangeTeam', player, team)
		end
	end
end

local function onPlayerLogout()
	setPlayerTeam(source, nil)
	updatePlayerTeam(source)
	--destroyEmptyTeams()
end

local function onPlayerJoinLogin()
	updatePlayerTeam(source)
	--destroyEmptyTeams()
end

local function onPlayerChangeNick(oldNick, newNick)
	updatePlayerTeam(source, newNick)
	--destroyEmptyTeams()
end

local function onPlayerQuit()
	removePlayerFromTeam(source)
	--destroyEmptyTeams()
end

local function loadFromXML()
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

function updateAllPlayers()
	for player, pdata in pairs(g_Players) do
		if(not pdata.is_console) then
			updatePlayerTeam(player)
		end
	end
	--destroyEmptyTeams()
end
RPC.allow('Teams.updateAllPlayers')

local function initDelayed()
	updateAllPlayers()
	setTimer(detectTeamChange, 1000, 0)
end

local function init()
	local oldTeams = loadFromXML()
	if(oldTeams) then
		fileDelete('conf/teams.xml')
		local cnt = DbQuery('SELECT COUNT(id) AS c FROM '..TeamsTable)[1].c
		for i, teamInfo in ipairs(oldTeams) do
			if(not DbQuery('INSERT INTO '..TeamsTable..' (name, tag, aclGroup, color, priority) VALUES(?, ?, ?, ?, ?)',
				teamInfo.name, teamInfo.tag, teamInfo.aclGroup, teamInfo.color, cnt + 1)) then break end
			cnt = cnt + 1
		end
	end
	g_List = DbQuery('SELECT * FROM '..TeamsTable..' ORDER BY priority')
	
	for i, teamInfo in ipairs(g_List) do
		g_TeamFromName[teamInfo.name] = teamInfo
		g_TeamFromID[teamInfo.id] = teamInfo
	end
	
	for player, pdata in pairs(g_Players) do
		pdata.team = false
	end
	
	addEventHandler('onPlayerJoin', g_Root, onPlayerJoinLogin)
	addEventHandler('onPlayerLogin', g_Root, onPlayerJoinLogin)
	addEventHandler('onPlayerLogout', g_Root, onPlayerLogout)
	addEventHandler('onPlayerChangeNick', g_Root, onPlayerChangeNick)
	addEventHandler('onPlayerQuit', g_Root, onPlayerQuit)
	
	-- Don't setup teams in onResourceStart event - see MTA bug #6861
	setTimer(initDelayed, 50, 1)
end

addInitFunc(init)
