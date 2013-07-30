local right = AccessRight('teams')

function Teams.getList()
	if(not right:check(client)) then return false end
	return Teams.list
end
allowRPC('Teams.getList')

function Teams.updateItem(teamInfo)
	if(not right:check(client)) then return false end
	assert(teamInfo and teamInfo.name and teamInfo.tag and teamInfo.aclGroup and teamInfo.color)
	
	if(teamInfo.id) then
		local teamCopy = Teams.fromID[teamInfo.id]
		if(not teamCopy) then
			privMsg(client, "Failed to modify team")
			return false
		end
		
		Teams.fromName[teamCopy.name] = nil
		for k, v in pairs(teamInfo) do
			teamCopy[k] = v
		end
		Teams.fromName[teamCopy.name] = teamCopy
		if(not DbQuery('UPDATE '..DbPrefix..'teams '..
				'SET name=?, tag=?, aclGroup=?, color=? WHERE id=?',
				teamInfo.name, teamInfo.tag, teamInfo.aclGroup, teamInfo.color, teamInfo.id)) then
			return false
		end
	else
		local rows = DbQuery('SELECT id FROM '..DbPrefix..'teams WHERE name=? AND tag=? AND aclGroup=?', teamInfo.name, teamInfo.tag, teamInfo.aclGroup)
		if(rows and rows[1]) then
			privMsg(client, "Failed to add team %s", teamInfo.name)
			return false
		end
		
		DbQuery('INSERT INTO '..DbPrefix..'teams (name, tag, aclGroup, color, priority) VALUES(?, ?, ?, ?, ?)',
			teamInfo.name, teamInfo.tag, teamInfo.aclGroup, teamInfo.color, #Teams.list + 1)
		local rows = DbQuery('SELECT last_insert_rowid() AS id')
		teamInfo.id = rows[1].id
		Teams.fromName[teamInfo.name] = teamInfo
		Teams.fromID[teamInfo.id] = teamInfo
		table.insert(Teams.list, teamInfo)
	end
	
	return teamInfo
end
allowRPC('Teams.updateItem')

function Teams.delItem(id)
	if(not right:check(client)) then return false end
	assert(id)
	
	local teamInfo = Teams.fromID[id]
	if(not teamInfo) then
		privMsg(client, "Failed to delete team")
		return false
	end
	
	DbQuery('UPDATE '..DbPrefix..'teams SET priority=priority-1 WHERE priority > ?', teamInfo.priority)
	DbQuery('DELETE FROM '..DbPrefix..'teams WHERE id=?', teamInfo.id)
	table.removeValue(Teams.list, teamInfo)
	Teams.fromName[teamInfo.name] = nil
	Teams.fromID[teamInfo.id] = nil
	return true
end
allowRPC('Teams.delItem')

function Teams.changePriority(id, up)
	local teamInfo = id and Teams.fromID[id]
	if(not right:check(client) or not teamInfo) then return false end
	
	local i = table.find(Teams.list, teamInfo)
	local j = up and (i - 1) or (i + 1)
	local teamInfo2 = Teams.list[j]
	if(not teamInfo2) then return false end
	
	local tmp = teamInfo.priority
	teamInfo.priority = teamInfo2.priority
	teamInfo2.priority = tmp
	Teams.list[j] = teamInfo
	Teams.list[i] = teamInfo2
	
	DbQuery('UPDATE '..DbPrefix..'teams SET priority=? WHERE id=?', teamInfo.priority, teamInfo.id)
	DbQuery('UPDATE '..DbPrefix..'teams SET priority=? WHERE id=?', teamInfo2.priority, teamInfo2.id)
	
	return Teams.list
end
allowRPC('Teams.changePriority')
