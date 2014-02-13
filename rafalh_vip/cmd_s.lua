local function findPlayer(str)
	if(not str) then
		return false
	end
	
	local player = getPlayerFromName(str) -- returns player or false
	if(player) then
		return player
	end
	
	str = str:lower()
	for i, player in ipairs(getElementsByType('player')) do
		local name = getPlayerName(player):gsub('#%x%x%x%x%x%x', ''):lower()
		if(name:find(str, 1, true)) then
			return player
		end
	end
	
	return false
end

addCommandHandler('activatevip', function(source, cmd, code)
	local account = getPlayerAccount(source)
	
	if(isGuestAccount(account)) then
		outputChatBox("PM: Register an account and log in before using this command.", source, 255, 0, 0)
	elseif(code) then
		VipActivatePlayerCode(source, code)
	else
		outputChatBox("PM: Usage: /activatevip <code>", source, 255, 96, 96)
	end
end, false, false)

addCommandHandler('givevip', function(source, cmd, name, days)
	if(not hasObjectPermissionTo(source, 'resource.rafalh_vip.givevip', false)) then
		outputChatBox("PM: Access is denied!", source, 255, 0, 0)
		return
	end
	
	local player = findPlayer(name)
	local days = math.floor(tonumber(days or 30))
	
	if(not player or not days) then
		outputChatBox("PM: Usage: /givevip <name> [<days>]", source, 255, 96, 96)
		return
	end
	
	local success, limit = VipAdd(player, days*24*3600)
	if(success) then
		local name = getPlayerName(player):gsub('#%x%x%x%x%x%x', '')
		local limitStr = limit and formatDateTime(limit) or 'N/A'
		outputChatBox("PM: VIP rank successfully given to "..name.."! It will be valid untill "..limitStr, source, 255, 96, 96, true)
		
		local now = getRealTime().timestamp
		if(limit and limit > now) then
			outputChatBox("VIP activated successfully! It will be valid untill "..limitStr, player, 0, 255, 0)
		end
	else
		outputChatBox("PM: Failed to give VIP rank", source, 255, 96, 96)
	end
end, false, false)

addCommandHandler('giveviptoall', function(source, cmd, days)
	if(not hasObjectPermissionTo(source, 'resource.rafalh_vip.givevip', false)) then
		outputChatBox("PM: Access is denied!", source, 255, 0, 0)
		return
	end
	
	local days = math.floor(tonumber(days) or 0)
	
	if(days < 1) then
		outputChatBox("PM: Usage: /giveviptoall <days>", source, 255, 96, 96)
		return
	end
	
	local now = getRealTime().timestamp
	local vips = VipGetAll()
	for i, info in ipairs(vips) do
		if(type(info[1]) == 'userdata' and info[2] and info[2] > now) then
			local account = info[1]
			local accountName = getAccountName(account)
			local success, limit = VipAdd(account, days*24*3600)
			if(success) then
				outputChatBox("PM: VIP rank successfully extended for "..accountName.."!", source, 255, 96, 96, true)
			else
				outputChatBox("PM: Failed to extend VIP rank for "..accountName, source, 255, 96, 96)
			end
		end
	end
end, false, false)

addCommandHandler('isvip', function(source, cmd, name)
	local player = findPlayer(name)
	
	if(not player) then
		outputChatBox("PM: Usage: /isvip <name>", source, 255, 96, 96)
		return
	end
	
	local name = getPlayerName(player):gsub('#%x%x%x%x%x%x', '')
	local access, limit = VipCheck(player)
	
	local msg
	if(access) then
		if(limit) then
			msg = name.." is a VIP untill "..formatDateTime(limit)
		else
			msg = name.." is a VIP (endless)."
		end
	else
		if(limit) then
			msg = name.." was a VIP untill "..formatDateTime(limit)
		else
			msg = name.." is not a VIP."
		end
	end
	outputChatBox('PM: '..msg, source, 255, 96, 96)
end, false, false)

addCommandHandler('checkallvips', function(source, cmd, name)
	if(not hasObjectPermissionTo(source, 'resource.rafalh_vip.checkallvips', false)) then
		outputChatBox("PM: Access is denied!", source, 255, 0, 0)
		return
	end
	
	local found = false
	local now = getRealTime().timestamp
	local vips = VipGetAll()
	for i, info in ipairs(vips) do
		local msg = false
		if(type(info[1]) == 'string') then
			msg = info[1]..' is invalid account!'
		else
			local name = getAccountName(info[1])
			if(not info[2]) then
				msg = name..' is endless VIP!'
			elseif(info[2] > now + 100*24*3600) then
				msg = name..' is a VIP untill '..formatDateTime(info[2])
			elseif(info[2] < now) then
				msg = name..' is still in VIP group but his rank has expired '..formatDateTime(info[2])
			end
		end
		
		if(msg) then
			outputChatBox(msg, source, 255, 96, 96)
			found = true
		end
	end
	
	if(not found) then
		outputChatBox(msg, "All VIPs seems alright.", 255, 96, 96)
	end
end, false, false)
