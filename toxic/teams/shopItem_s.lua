
#include 'include/config.lua'

namespace('Teams')

ShpRegisterItem
{
	id = 'team',
	field = 'ownedTeam',
	onBuy = function(player, val)
		if(val) then return false end
		
		local pdata = Player.fromEl(player)
		local teamInfo, err = updateItem{name = pdata:getName(), tag = '', aclGroup = false, color = '#FFFFFF'}
		if(not teamInfo) then
			privMsg(pdata, err)
			return false
		end
		pdata.accountData.ownedTeam = teamInfo.id
		return true
	end,
	onSell = function(player, val)
		if(not val) then return false end
		
		local pdata = Player.fromEl(player)
		local status, err = delItem(val)
		if(not status) then
			privMsg(pdata, err)
			return false
		end
		
		return pdata.accountData:set('ownedTeam', nil)
	end
}

function updateOwnedRPC(teamInfo)
	local pdata = Player.fromEl(client)
	if(not teamInfo or not teamInfo.id or not pdata.accountData.ownedTeam or teamInfo.id ~= pdata.accountData.ownedTeam) then
		return false, 'Unknown error '..tostring(teamInfo.id)..' '..tostring(pdata.accountData.ownedTeam)
	end
	
	if(teamInfo.tag ~= '') then
		local rows = DbQuery('SELECT COUNT(*) AS c FROM '..TeamsTable..' WHERE tag=? AND id<>?', teamInfo.tag, teamInfo.id)
		if(rows[1].c > 0) then
			return false, 'Team with specified tag already exists'
		end
	end
	
	teamInfo.aclGroup = false
	teamInfo.owner = pdata.id
	
	local status, err = updateItem(teamInfo)
	if(status) then
		updateAllPlayers()
	end
	
	return status, err
end
RPC.allow('Teams.updateOwnedRPC')

function getOwnedInfoRPC()
	local pdata = Player.fromEl(client)
	if(not pdata.accountData.ownedTeam) then return false end
	
	local teamInfo = g_TeamFromID[pdata.accountData.ownedTeam]
	return teamInfo
end
RPC.allow('Teams.getOwnedInfoRPC')
