local TEAMS_RIGHT = "resource."..g_ResName..".teams"

local function CmdTeamsAdmin()
	RPC("openTeamsAdmin", g_Teams):setClient(source):exec()
end

function saveTeamInfo(teamInfo)
	if(not hasObjectPermissionTo(client, TEAMS_RIGHT, false)) then return false end
	assert(teamInfo and teamInfo.name and teamInfo.tag and teamInfo.aclGroup and teamInfo.color)
	
	if(teamInfo.id) then
		local teamCopy = g_TeamFromID[teamInfo.id]
		if(not teamCopy) then
			privMsg(client, "Failed to modify team")
			return false
		end
		
		g_TeamFromName[teamCopy.name] = nil
		for k, v in pairs(teamInfo) do
			teamCopy[k] = v
		end
		g_TeamFromName[teamCopy.name] = teamCopy
		if(not DbQuery("UPDATE "..DbPrefix.."teams "..
				"SET name=?, tag=?, aclGroup=?, color=? WHERE id=?",
				teamInfo.name, teamInfo.tag, teamInfo.aclGroup, teamInfo.color, teamInfo.id)) then
			return false
		end
	else
		DbQuery("INSERT INTO "..DbPrefix.."teams (name, tag, aclGroup, color) VALUES(?, ?, ?, ?)",
			teamInfo.name, teamInfo.tag, teamInfo.aclGroup, teamInfo.color)
		local rows = DbQuery("SELECT last_insert_rowid() AS id")
		teamInfo.id = rows[1].id
		g_TeamFromName[teamInfo.name] = teamInfo
		table.insert(g_Teams, teamInfo)
	end
	
	return teamInfo
end
allowRPC('saveTeamInfo')

function deleteTeamInfo(id)
	if(not hasObjectPermissionTo(client, TEAMS_RIGHT, false)) then return end
	assert(teamInfo)
	
	local teamInfo = g_TeamFromID[id]
	if(not teamInfo) then
		privMsg(client, "Failed to delete team")
		return
	end
	
	DbQuery("DELETE FROM "..DbPrefix.."teams WHERE id=?", teamInfo.id)
	table.removeValue(g_Teams, teamInfo)
	g_TeamFromName[teamInfo.name] = nil
	g_TeamFromID[teamInfo.id] = nil
end
allowRPC('deleteTeamInfo')

CmdRegister("teamsadmin", CmdTeamsAdmin, TEAMS_RIGHT)