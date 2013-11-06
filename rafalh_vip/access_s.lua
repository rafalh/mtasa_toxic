-- Defines
#local ACTIVATION_URL = 'http://mtatoxic.tk/scripts/NGWm5LtQ5fmnnmpx/activate_code.php?code=%s'

#local PROMO_MONTHS = 2
#local PROMO_TEXT = "It's CHRISTMAS PROMOTION so you get one month more for free."

#local PROMO_DAY1 = 20
#local PROMO_MONTH1 = 12
#local PROMO_YEAR1 = 2010

#local PROMO_DAY2 = 4
#local PROMO_MONTH2 = 1
#local PROMO_YEAR2 = 2011

local function VipGetPlayerFromAccount(account)
	for i, player in ipairs(getElementsByType("player")) do
		if(getPlayerAccount(player) == account) then
			return player
		end
	end
	
	return false
end

local function VipActivationError(reason, player)
	local fmt = "VIP activation failed: %s. Please contact administrator."
	outputChatBox(fmt:format(reason), player or root, 255, 0, 0)
	outputDebugString('VIP activation failed: '..reason..' for '..(player and getPlayerName(player) or 'unknown'), 3)
end

local function VipActivatePlayerPromoCode(player)
	local account = getPlayerAccount(player)
	if(getAccountData(account, "rafalh_vip_promo")) then
		outputChatBox("You have already used VIP promotion code.", player, 255, 0, 0)
		return false
	elseif(not g_VipGroup) then
		VipActivationError("VIP group has not been found.")
		return false
	end
	
	local accName = getAccountName(account)
	setAccountData(account, 'rafalh_vip_promo', 1)
	
	local status, limit = VipAdd(account, 60*60)
	if(not status) then
		VipActivationError("VipAdd failed")
		return false
	end
	
	outputChatBox("VIP activated successfully! Rank will be valid for 1 hour untill "..(limit and formatDateTime(limit) or 'N/A'), player, 0, 255, 0)
	return true
end

local function VipActivationCallback(data, errno, account)
	local player = VipGetPlayerFromAccount(account)
	
	if(errno ~= 0) then
		VipActivationError("fetchRemote failed with code "..tostring(errno), player)
		return
	end
	
	local accName = account and getAccountName(account)
	if(not accName) then
		VipActivationError("account is invalid", player)
		return
	end
	
	local days, statusMsg = fromJSON(data)
	local days = tonumber(days)
	if(not days or days <= 0 or days > 100) then
		if(statusMsg) then
			statusMsg = tostring(statusMsg):sub(1, 64)
		else
			statusMsg = tostring(data):gsub("<[^>]+>", ""):sub(1, 64)
		end
		VipActivationError(statusMsg, player)
		return
	elseif(not g_VipGroup) then
		VipActivationError("VipGroup does not exist", player)
		return
	end
	
	-- Check if this is a promotion
	local tm = getRealTime()
	local promo = false
	if(tm.year*12*31 + tm.month*31 + tm.monthday >= $((PROMO_YEAR1-1900)*12*31+(PROMO_MONTH1-1)*31+PROMO_DAY1) and tm.year*12*31 + tm.month*31 + tm.monthday <= $((PROMO_YEAR2-1900)*12*31+(PROMO_MONTH2-1)*31+PROMO_DAY2)) then
		days = days + $(PROMO_MONTHS)*30
		promo = true
	end
	
	local status, limit = VipAdd(account, days*24*3600)
	if(not status) then
		VipActivationError('giveVip failed', player)
		return
	end
	
	if(player) then
		local limitStr = limit and formatDateTime(limit) or 'N/A'
		local msg
		if(not promo) then
			msg = "VIP activated successfully! Rank will be valid untill "..limitStr
		else
			msg = "VIP activated successfully! Rank will be valid untill "..limitStr
		end
		outputChatBox(msg, player, 0, 255, 0)
	end
end

----------------------
-- Global functions --
----------------------

function VipCheck(playerOrAccount)
	local account = isPlayer(playerOrAccount) and getPlayerAccount(playerOrAccount) or playerOrAccount
	assert(account)
	
	local status, limit = false, false
	local now = getRealTime().timestamp
	
	local promoEnd = tonumber(get("promo_end"))
	if(promoEnd > now) then
		status = true
		limit = promoEnd
	end
	
	local accountName = getAccountName(account)
	if(hasObjectPermissionTo('user.'..accountName, g_VipRight, false)) then
		local accLimit = getAccountData(account, "rafalh_vip_time")
		if(accLimit and accLimit < now) then
			-- Expired
			VipRemove(account)
		elseif(not status or not accLimit or accLimit > limit) then
			-- Account limit is better
			status = true
			limit = accLimit
		end
	end
	
	return status, limit
end

function VipAdd(playerOrAccount, seconds)
	local player = isPlayer(playerOrAccount) and playerOrAccount or VipGetPlayerFromAccount(playerOrAccount)
	local account = isPlayer(playerOrAccount) and getPlayerAccount(playerOrAccount) or playerOrAccount
	local seconds = tonumber(seconds)
	assert(account and seconds)
	
	if(isGuestAccount(account) or not g_VipGroup) then
		return false
	end
	
	local now = getRealTime().timestamp
	local newLimit
	local access, limit = VipCheck(account)
	if(access) then
		if(limit) then
			-- extend access
			newLimit = math.max(math.max(limit, now) + seconds, now)
		else
			-- endless access
			return true, false 
		end
	else
		if(seconds <= 0) then
			-- Trying to give negative number for not VIP
			return false, false
		else
			-- new VIP
			newLimit = now + seconds
		end
	end
	
	--outputDebugString('VipAdd '..getAccountName(account)..' '..seconds..' - old '..tostring(limit)..', new '..tostring(newLimit), 3)
	
	-- Update limit
	setAccountData(account, 'rafalh_vip_time', newLimit)
	
	if(newLimit > now) then
		-- Add to group if needed
		local accountName = getAccountName(account)
		aclGroupAddObject(g_VipGroup, 'user.'..accountName)
		outputServerLog("VIP rank activated for "..accountName..". It will be active untill "..formatDateTime(newLimit))
	elseif(access) then
		-- Not VIP anymore
		VipRemove(account)
	end
	
	if(player) then
		-- Send VIP limit to player (even if he was a VIP)
		triggerClientEvent(player, 'vip.onVerified', resourceRoot, newLimit)
	end
	
	return true, newLimit
end

function VipRemove(playerOrAccount)
	local player = isPlayer(playerOrAccount) and playerOrAccount or VipGetPlayerFromAccount(playerOrAccount)
	local account = isPlayer(playerOrAccount) and getPlayerAccount(playerOrAccount) or playerOrAccount
	assert(account)
	
	local accName = getAccountName(account)
	if(not aclGroupRemoveObject(g_VipGroup, 'user.'..accName)) then return false end
	
	outputServerLog("VIP rank disactivated for "..accName..".")
	if(player) then
		outputChatBox("Your VIP rank has been disactivated!", player, 255, 0, 0)
	end
end

function VipActivatePlayerCode(player, code)
	if(code == 'PROMO') then
		return VipActivatePlayerPromoCode(player)
	end
	
	local account = getPlayerAccount(player)
	local url = ('$ACTIVATION_URL'):format(urlEncode(code))
	if(not fetchRemote(url, VipActivationCallback, '', false, account)) then
		VipActivationError('fetchRemote failed', player)
		return false
	end
	
	return true
end

function VipGetAll()
	local ret = {}
	local vips = aclGroupListObjects(g_VipGroup)
	for i, objName in ipairs(vips) do
		if(objName:sub(1, 5) == 'user.') then
			local accountName = objName:sub(6)
			local account = getAccount(accountName)
			if(not account) then
				table.insert(ret, {accountName, false})
			else
				local access, limit = VipCheck(account)
				--if(access) then
					table.insert(ret, {account, limit})
				--end
			end
		end
	end
	return ret
end

function giveVip(playerOrAccount, days)
	local days = tonumber(days or 30)
	assert(playerOrAccount and days)
	local success = VipAdd(playerOrAccount, days*24*3600)
	--outputDebugString('giveVip '..getPlayerName(playerOrAccount)..' '..days..': '..tostring(success), 3)
	return success
end

function isVip(player, account)
	return VipCheck(account or player)
end