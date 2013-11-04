namespace('Teams')

local g_Right = AccessRight('teams')

function getList()
	if(not g_Right:check(client)) then return false end
	return g_List
end
RPC.allow('Teams.getList')

function updateItem(teamInfo)
	if(not g_Right:check(client)) then return false end
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
		if(not DbQuery('UPDATE '..TeamsTable..' SET name=?, tag=?, aclGroup=?, color=? WHERE id=?',
				teamInfo.name, teamInfo.tag, teamInfo.aclGroup, teamInfo.color, teamInfo.id)) then
			return false
		end
	else
		local rows = DbQuery('SELECT id FROM '..TeamsTable..' WHERE name=? AND tag=? AND aclGroup=?', teamInfo.name, teamInfo.tag, teamInfo.aclGroup)
		if(rows and rows[1]) then
			privMsg(client, "Failed to add team %s", teamInfo.name)
			return false
		end
		
		DbQuery('INSERT INTO '..TeamsTable..' (name, tag, aclGroup, color, priority) VALUES(?, ?, ?, ?, ?)',
			teamInfo.name, teamInfo.tag, teamInfo.aclGroup, teamInfo.color, #g_List + 1)
		local rows = DbQuery('SELECT last_insert_rowid() AS id')
		teamInfo.id = rows[1].id
		g_TeamFromName[teamInfo.name] = teamInfo
		g_TeamFromID[teamInfo.id] = teamInfo
		table.insert(g_List, teamInfo)
	end
	
	return teamInfo
end
RPC.allow('Teams.updateItem')

function delItem(id)
	if(not g_Right:check(client)) then return false end
	assert(id)
	
	local teamInfo = g_TeamFromID[id]
	if(not teamInfo) then
		privMsg(client, "Failed to delete team")
		return false
	end
	
	DbQuery('UPDATE '..TeamsTable..' SET priority=priority-1 WHERE priority > ?', teamInfo.priority)
	DbQuery('DELETE FROM '..TeamsTable..' WHERE id=?', teamInfo.id)
	table.removeValue(g_List, teamInfo)
	g_TeamFromName[teamInfo.name] = nil
	g_TeamFromID[teamInfo.id] = nil
	return true
end
RPC.allow('Teams.delItem')

function changePriority(id, up)
	local teamInfo = id and g_TeamFromID[id]
	if(not g_Right:check(client) or not teamInfo) then return false end
	
	local i = table.find(g_List, teamInfo)
	local j = up and (i - 1) or (i + 1)
	local teamInfo2 = g_List[j]
	if(not teamInfo2) then return false end
	
	local tmp = teamInfo.priority
	teamInfo.priority = teamInfo2.priority
	teamInfo2.priority = tmp
	g_List[j] = teamInfo
	g_List[i] = teamInfo2
	
	DbQuery('UPDATE '..TeamsTable..' SET priority=? WHERE id=?', teamInfo.priority, teamInfo.id)
	DbQuery('UPDATE '..TeamsTable..' SET priority=? WHERE id=?', teamInfo2.priority, teamInfo2.id)
	
	return g_List
end
RPC.allow('Teams.changePriority')
