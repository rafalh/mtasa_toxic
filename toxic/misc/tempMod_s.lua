local g_TempModGroup = aclGetGroup('PremiumModerator')
local g_ModGroup = aclGetGroup('Moderator')
local g_SuperModGroup = aclGetGroup('SuperModerator')

function giveTempModAccount(account, days)
	local days = tonumber(days or 30)
	if(not days or not g_TempModGroup) then return false end
	
	aclGroupAddObject(g_TempModGroup, 'user.'..getAccountName(account))
	
	local now = getRealTime().timestamp
	local timestamp = math.max(getAccountData(account, 'toxic.tempModLimit') or 0, now) + days*24*60*60
	setAccountData(account, 'toxic.tempModLimit', timestamp)
	
	local tm = getRealTime(timestamp)
	
	local dateStr = ('%u.%02u.%u %u:%02u GMT.'):format(tm.monthday, tm.month+1, tm.year+1900, tm.hour, tm.minute)
	outputServerLog('Temporary Moderator activated for '..getAccountName(account)..'. It will be active until '..dateStr)
	
	return timestamp
end

function giveTempMod(player, days)
	local account = player and getPlayerAccount(player.el)
	if(not account or isGuestAccount(account)) then return false end
	return giveTempModAccount(account, days)
end

CmdMgr.register{
	name = 'givemod',
	desc = "Gives temporary moderator to specified player",
	accessRight = AccessRight('givemod'),
	args = {
		{'player', type = 'player'},
		{'days', type = 'int', defVal = 30, min = 1},
	},
	func = function(ctx, player, days)
		local timestamp = player and giveTempMod(player, days)
		if(timestamp) then
			local tm = getRealTime(timestamp)
			local dateStr = ('%u.%02u.%u %u:%02u GMT'):format(tm.monthday, tm.month+1, tm.year+1900, tm.hour, tm.minute)
			
			privMsg(ctx.player, "Temporary Moderator successfully given to %s! It will be valid until %s.", player:getName(), dateStr)
			outputMsg(player, Styles.green, "You have become Temporary Moderator! It will be valid until %s.", dateStr)
		else
			privMsg(ctx.player, "Failed to give temporary moderator")
		end
	end
}

CmdMgr.register{
	name = 'givemodaccount',
	desc = "Gives temporary moderator to specified account",
	accessRight = AccessRight('givemod'),
	args = {
		{'accountName', type = 'str'},
		{'days', type = 'int', defVal = 30, min = 1},
	},
	func = function(ctx, accountName, days)
		local account = getAccount(accountName)
		if(not account) then
			privMsg(ctx.player, "Cannot find account '%s'!", accountName)
			return
		end
			
		local timestamp = giveTempModAccount(account, days)
		if(timestamp) then
			local tm = getRealTime(timestamp)
			local dateStr = ('%u.%02u.%u %u:%02u GMT'):format(tm.monthday, tm.month+1, tm.year+1900, tm.hour, tm.minute)
			
			privMsg(ctx.player, "Temporary Moderator successfully given to %s! It will be valid until %s.", accountName, dateStr)
		else
			privMsg(ctx.player, "Failed to give temporary moderator")
		end
	end
}

CmdMgr.register{
	name = 'modinfo',
	desc = "Displays information about moderator",
	accessRight = AccessRight('modinfo'),
	args = {
		{'player', type = 'player'},
	},
	func = function(ctx, player)
		local account = getPlayerAccount(player.el)
		if(isGuestAccount(account)) then
			privMsg(ctx.player, "Player is not logged in!")
			return
		end
		
		local objStr = 'user.'..getAccountName(account)
		local now = getRealTime().timestamp
		local timestamp = getAccountData(account, 'toxic.tempModLimit')
		if(timestamp and timestamp > now and isObjectInACLGroup(objStr, g_TempModGroup)) then
			local tm = getRealTime(timestamp)
			local dateStr = ('%u.%02u.%u %u:%02u GMT'):format(tm.monthday, tm.month+1, tm.year+1900, tm.hour, tm.minute)
			scriptMsg("%s is a Temporary Moderator (valid until %s).", player:getName(), dateStr)
		elseif(isObjectInACLGroup(objStr, g_ModGroup)) then
			scriptMsg("%s is a Moderator.", player:getName())
		elseif(isObjectInACLGroup(objStr, g_SuperModGroup)) then
			scriptMsg("%s is a Super Moderator.", player:getName())
		else
			scriptMsg("%s is not a Moderator.", player:getName())
		end
	end
}

CmdMgr.register{
	name = 'checkmods',
	desc = "Checks all premium moderators for expired time",
	accessRight = AccessRight('modinfo'),
	func = function(ctx)
		local objList = aclGroupListObjects(g_TempModGroup)
		local vipGroup = aclGetGroup('VIP')
		local now = getRealTime().timestamp
		local msg = true
		
		for i, obj in ipairs(objList) do
			local accountName = obj:match('^user%.(.+)$')
			local account = accountName and getAccount(accountName)
			local modLimit = account and getAccountData(account, 'toxic.tempModLimit')
			local vipLimit = account and getAccountData(account, 'rafalh_vip_time')
			local isTempMod = modLimit and modLimit > now
			local isVip = account and isObjectInACLGroup('user.'..accountName, vipGroup) and (not vipLimit or vipLimit > now)
			
			if(account and not isTempMod and not isVip) then
				local modLimitDate = modLimit and getRealTime(modLimit)
				local vipLimitDate = vipLimit and getRealTime(vipLimit)
				local modLimitDateStr = modLimitDate and ('%d-%d-%d'):format(modLimitDate.monthday, modLimitDate.month + 1, modLimitDate.year + 1900)
				local vipLimitDateStr = vipLimitDate and ('%d-%d-%d'):format(vipLimitDate.monthday, vipLimitDate.month + 1, vipLimitDate.year + 1900)
				privMsg(ctx.player, "%s's Premium Moderator has expired (VIP: %s, Mod: %s)!",
					accountName, vipLimitDateStr or 'no', modLimitDateStr or 'no')
				msg = false
			end
			
			--outputDebugString(accountName..' - '..tostring(account)..' '..tostring(isTempMod)..' '..tostring(isVip), 3)
		end
		
		if(msg) then
			privMsg(ctx.player, "Everything is all right!")
		end
	end
}

local function onPlayerLogin(prevAccount, account)
	local player = Player.fromEl(source)
	
	local timestamp = getAccountData(account, 'toxic.tempModLimit')
	if(not timestamp) then return end
	
	local now = getRealTime().timestamp
	if(timestamp >= now) then return end
	
	local objStr = 'user.'..getAccountName(account)
	if(isObjectInACLGroup(objStr, g_TempModGroup)) then
		aclGroupRemoveObject(g_TempModGroup, objStr)
		outputServerLog('Temporary Moderator deactivated for '..getAccountName(account)..'.')
		outputMsg(player, Styles.red, "Your Moderator rank has expired!")
	end
end

addInitFunc(function()
	Event('onPlayerLogin'):addHandler(onPlayerLogin)
end)
