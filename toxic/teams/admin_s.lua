namespace('Teams')

local g_Right = AccessRight('teams')

function getList()
	if(not g_Right:check(client)) then return false end
	return g_List
end
RPC.allow('Teams.getList')

function updateItemRPC(teamInfo)
	if(not g_Right:check(client)) then return false end
	
	local teamInfo, err = updateItem(teamInfo)
	if(not teamInfo) then
		privMsg(client, err)
	end
	
	return teamInfo
end
RPC.allow('Teams.updateItemRPC')

function delItemRPC(id)
	if(not g_Right:check(client)) then return false end
	
	local status, err = delItem(id)
	if(not status) then
		privMsg(client, err)
	end
	
	return status
end
RPC.allow('Teams.delItemRPC')

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
