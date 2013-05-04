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
		local rows = DbQuery("SELECT id FROM "..DbPrefix.."teams WHERE name=?", teamInfo.name)
		if(rows and rows[1]) then
			privMsg(client, "Failed to add team %s", teamInfo.name)
			return false
		end
		
		DbQuery("INSERT INTO "..DbPrefix.."teams (name, tag, aclGroup, color, priority) VALUES(?, ?, ?, ?, ?)",
			teamInfo.name, teamInfo.tag, teamInfo.aclGroup, teamInfo.color, #g_Teams + 1)
		local rows = DbQuery("SELECT last_insert_rowid() AS id")
		teamInfo.id = rows[1].id
		g_TeamFromName[teamInfo.name] = teamInfo
		g_TeamFromID[teamInfo.id] = teamInfo
		table.insert(g_Teams, teamInfo)
	end
	
	return teamInfo
end
allowRPC('saveTeamInfo')

function deleteTeamInfo(id)
	if(not hasObjectPermissionTo(client, TEAMS_RIGHT, false)) then return false end
	assert(id)
	
	local teamInfo = g_TeamFromID[id]
	if(not teamInfo) then
		privMsg(client, "Failed to delete team")
		return false
	end
	
	DbQuery("UPDATE "..DbPrefix.."teams SET priority=priority-1 WHERE priority > ?", teamInfo.priority)
	DbQuery("DELETE FROM "..DbPrefix.."teams WHERE id=?", teamInfo.id)
	table.removeValue(g_Teams, teamInfo)
	g_TeamFromName[teamInfo.name] = nil
	g_TeamFromID[teamInfo.id] = nil
	return true
end
allowRPC('deleteTeamInfo')

function changeTeamPriority(id, up)
	local teamInfo = id and g_TeamFromID[id]
	if(not hasObjectPermissionTo(client, TEAMS_RIGHT, false) or not teamInfo) then return false end
	
	local i = table.find(g_Teams, teamInfo)
	local j = up and (i - 1) or (i + 1)
	local teamInfo2 = g_Teams[j]
	if(not teamInfo2) then return false end
	
	local tmp = teamInfo.priority
	teamInfo.priority = teamInfo2.priority
	teamInfo2.priority = tmp
	g_Teams[j] = teamInfo
	g_Teams[i] = teamInfo2
	
	DbQuery("UPDATE "..DbPrefix.."teams SET priority=? WHERE id=?", teamInfo.priority, teamInfo.id)
	DbQuery("UPDATE "..DbPrefix.."teams SET priority=? WHERE id=?", teamInfo2.priority, teamInfo2.id)
	
	return g_Teams
end
allowRPC('changeTeamPriority')

CmdRegister("teamsadmin", CmdTeamsAdmin, TEAMS_RIGHT)