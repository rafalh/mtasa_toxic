local TEAMS_RIGHT = "resource."..g_ResName..".teams"

local function findTeam(teamInfo)
	for i, curInfo in ipairs(g_Teams) do
		if(curInfo.name == teamInfo.name and curInfo.acl_group == teamInfo.acl_group and curInfo.clan == teamInfo.clan) then
			return curInfo
		end
	end
	return false
end

local function CmdTeamsAdmin()
	RPC("openTeamsAdmin", g_Teams):exec()
end

function saveTeamInfo(newTeamInfo, oldTeamInfo)
	if(not hasObjectPermissionTo(client, TEAMS_RIGHT, false)) then return end
	assert(newTeamInfo)
	
	if(oldTeamInfo) then
		local teamInfo = findTeam(oldTeamInfo)
		if(not teamInfo) then
			privMsg(client, "Failed to modify team")
			return
		end
		
		g_TeamNameMap[teamInfo.name] = nil
		g_TeamNameMap[newTeamInfo.name] = teamInfo
		teamInfo.acl_group = false
		teamInfo.clan = false
		for k, v in pairs(newTeamInfo) do
			teamInfo[k] = v
		end
	else
		g_TeamNameMap[newTeamInfo.name] = newTeamInfo
		table.insert(g_Teams, newTeamInfo)
	end
	
	TmSave()
end
allowRPC('saveTeamInfo')

function deleteTeamInfo(teamInfo)
	if(not hasObjectPermissionTo(client, TEAMS_RIGHT, false)) then return end
	assert(teamInfo)
	
	teamInfo = findTeam(teamInfo)
	if(not teamInfo) then
		privMsg(client, "Failed to delete team")
		return
	end
	
	table.removeValue(g_Teams, teamInfo)
	g_TeamNameMap[teamInfo.name] = nil
	TmSave()
end
allowRPC('deleteTeamInfo')

CmdRegister("teamsadmin", CmdTeamsAdmin, TEAMS_RIGHT)