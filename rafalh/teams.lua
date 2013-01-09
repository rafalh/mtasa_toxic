local g_Teams = {}
local g_TeamNameMap = {}
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

local function TmGetClanFromName ( name )
	name = name:gsub ( "#%x%x%x%x%x%x", "" )
	
	for i, pattern in ipairs ( g_Patterns ) do
		local tag = name:match ( pattern )
		if ( tag ) then
			return tag
		end
	end
	
	return false
end

local function TmUpdatePlayerTeam ( player, name )
	local account = getPlayerAccount ( player )
	local account_name = account and getAccountName ( account )
	if ( not name ) then
		name = getPlayerName ( player )
	end
	local player_clan = TmGetClanFromName ( name )
	local player_team_data = false
	
	for i, team_data in ipairs ( g_Teams ) do
		if ( team_data.acl_group and account_name and isObjectInACLGroup ( "user."..account_name, aclGetGroup ( team_data.acl_group ) ) ) then
			player_team_data = team_data
			break
		elseif ( team_data.clan and player_clan == team_data.clan ) then
			player_team_data = team_data
			break
		end
	end
	
	if ( not player_team_data and SmGetBool ( "clan_teams" ) and player_clan and not g_TeamNameMap[player_clan] ) then
		player_team_data = { name = player_clan }
	end
	
	if ( player_team_data ) then
		local team = getTeamFromName ( player_team_data.name )
		if ( not team ) then
			local r, g, b = getColorFromString ( player_team_data.color )
			if ( not r ) then
				r, g, b = math.random ( 0, 255 ), math.random ( 0, 255 ), math.random ( 0, 255 )
			end
			team = createTeam ( player_team_data.name, r, g, b )
		end
		setPlayerTeam ( player, team )
	end
end

local function TmUpdateTeams ()
	for i, team in ipairs ( getElementsByType ( "team", g_ResRoot ) ) do
		if ( countPlayersInTeam ( team ) == 0 ) then -- in team there was only source player
			destroyElement ( team )
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

local function TmInitDelayed ()
	for player, pdata in pairs ( g_Players ) do
		pdata.team = false
		TmUpdatePlayerTeam ( player )
	end
	
	setTimer(TmDetectTeamChange, 1000, 0)
end

local function TmInit ()
	local node, i = xmlLoadFile ( "conf/teams.xml" ), 0
	if ( node ) then
		while ( true ) do
			local subnode = xmlFindChild ( node, "team", i )
			if ( not subnode ) then break end
			i = i + 1
			
			local team = {}
			team.name = tostring ( xmlNodeGetAttribute ( subnode, "name" ) )
			team.acl_group = xmlNodeGetAttribute ( subnode, "acl_group" )
			team.clan = xmlNodeGetAttribute ( subnode, "clan" )
			team.color = xmlNodeGetAttribute ( subnode, "color" )
			g_TeamNameMap[team.name] = team
			table.insert ( g_Teams, team )
		end
		xmlUnloadFile ( node )
	end
	
	-- Don't setup teams in onResourceStart event - see MTA bug #6861
	setTimer ( TmInitDelayed, 50, 1 )
end

local function TmOnPlayerLogout ()
	if ( wasEventCancelled () ) then return end
	
	setPlayerTeam ( source, nil )
	TmUpdatePlayerTeam ( source )
	TmUpdateTeams ()
end

local function TmOnPlayerJoinLogin ()
	if ( wasEventCancelled () ) then return end
	
	TmUpdatePlayerTeam ( source )
	TmUpdateTeams ()
end

local function TmOnPlayerChangeNick ( old_nick, new_nick )
	if ( wasEventCancelled () ) then return end
	
	TmUpdatePlayerTeam ( source, new_nick )
	TmUpdateTeams ()
end

local function TmOnPlayerQuit ()
	if ( wasEventCancelled () ) then return end
	
	setPlayerTeam ( source, nil )
	TmUpdateTeams ()
end

addEventHandler ( "onResourceStart", g_ResRoot, TmInit )
addEventHandler ( "onPlayerJoin", g_Root, TmOnPlayerJoinLogin )
addEventHandler ( "onPlayerLogin", g_Root, TmOnPlayerJoinLogin )
addEventHandler ( "onPlayerLogout", g_Root, TmOnPlayerLogout )
addEventHandler ( "onPlayerChangeNick", g_Root, TmOnPlayerChangeNick )
addEventHandler ( "onPlayerQuit", g_Root, TmOnPlayerQuit )
local function test2()
	_G.outputDebugString("test2 g_Global "..tostring(g_Global), 3)
end
local function test()
	--g_Global = "123"
	_G.outputDebugString("test g_Global ".._G.tostring(g_Global), 3)
	test2()
end
g_Global = "lol"
setfenv(1, {_G = _G})
test()
_G.outputDebugString("g_Global ".._G.tostring(g_Global), 3)
