----------------------
-- Global variables --
----------------------

#local ACTIVATION_URL = 'http://mtatoxic.tk/scripts/NGWm5LtQ5fmnnmpx/activate_code.php?code=%s'

g_Root = getRootElement()
g_ThisRes = getThisResource()
g_ResRoot = getResourceRootElement(g_ThisRes)
local g_Players = {}
local g_VipGroup = aclGetGroup('VIP')
local g_VipRight = 'resource.rafalh_vip'

-----------------
-- Definitions --
-----------------

#PROMO_MONTHS = 2
#PROMO_TEXT = "It's CHRISTMAS PROMOTION so you get one month more for free."

#PROMO_DAY1 = 20
#PROMO_MONTH1 = 12
#PROMO_YEAR1 = 2010

#PROMO_DAY2 = 4
#PROMO_MONTH2 = 1
#PROMO_YEAR2 = 2011

-------------------
-- Custom events --
-------------------

addEvent("vip.onVerified", true)
addEvent("vip.onReady", true)
addEvent("vip.onSettings", true)
addEvent("onPlayerPickUpRacePickup")

--------------------------------
-- Local function definitions --
--------------------------------

local function VipIsPromoActive()
	local promo_end = tonumber(get("promo_end")) or 0
	local now = getRealTime().timestamp
	if(now <= promo_end) then
		return promo_end
	end
	return false
end

local function VipCreateNeon(player, veh)
	local pdata = g_Players[player]
	local settings = pdata and pdata.settings
	if(not isElement(veh) or not settings) then return end
	
	local r, g, b = getColorFromString(settings.neon_clr)
	if(not pdata.neon) then
		pdata.neon = {obj = createMarker(0, 0, 0, "corona", 2, r, g, b, 128, g_Root)}
	else
		setMarkerColor(pdata.neon.obj, r, g, b, 128)
	end
	pdata.neon.veh = veh
	attachElements(pdata.neon.obj, veh, 0, 0, -1.5)
	--outputDebugString("VipCreateNeon("..getPlayerName(player)..")")
end

local function VipDestroyNeon(player)
	local pdata = g_Players[player]
	if(pdata.neon) then
		destroyElement(pdata.neon.obj)
		pdata.neon = nil
	end
	--outputDebugString("VipDestroyNeon("..getPlayerName(player)..")")
end

local function VipCleanup()
	for player, pdata in pairs(g_Players) do
		if(pdata.neon) then
			VipDestroyNeon(player)
		end
		if(pdata.vehclrtimer) then
			killTimer(pdata.vehclrtimer)
		end
	end
end

local function VipOnRafalhVipStart()
	g_Players[client] = {}
	local is_vip, timestamp = isVip(client, getPlayerAccount(client))
	if(is_vip) then
		triggerClientEvent(client, "vip.onVerified", g_Root, timestamp)
	end
	if(VipIsPromoActive()) then
		addEvent("vip.onShowPromoBannerReq", true)
		triggerClientEvent(client, "vip.onShowPromoBannerReq", g_Root)
	end
end

local function VipRandVehColor(player)
	local veh = getPedOccupiedVehicle(player)
	if(veh) then
		local r1, g1, b1 = math.random(0, 255), math.random(0, 255), math.random(0, 255)
		local r2, g2, b2 = math.random(0, 255), math.random(0, 255), math.random(0, 255)
		setVehicleColor(veh, r1, g1, b1, r2, g2, b2)
	end
end

local function VipAutopilotFunc(player)
	local pdata = g_Players[player]
	pdata.autopilot = not pdata.autopilot
	setTimer(setControlState, 50, 1, player, "accelerate", pdata.autopilot)
end

local function VipUpdateVehicle(player, veh)
	local pdata = g_Players[player]
	local settings = pdata and pdata.settings
	if(not settings) then return end
	
	if(veh) then
		if(settings.vehcolor) then
			local r1, g1, b1 = getColorFromString(settings.vehcolor1)
			local r2, g2, b2 = getColorFromString(settings.vehcolor2)
			setVehicleColor(veh, r1, g1, b1, r2, g2, b2)
		end
		if(pdata.vehclrtimer) then
			killTimer(pdata.vehclrtimer)
			pdata.vehclrtimer = nil
		end
		if(settings.vehcolortimer) then
			pdata.vehclrtimer = setTimer(VipRandVehColor, math.max(tonumber(settings.vehcolortimer_int) or 3, 3)*1000, 0, player)
		end
		if(settings.vehlicolor) then
			local r, g, b = getColorFromString(settings.vehlicolor_clr)
			setVehicleHeadLightColor(veh, r, g, b)
		end
		setVehicleOverrideLights(veh, (settings.forcevehlion and 2) or 0)
		
		if(settings.neon) then
			setTimer(VipCreateNeon, 100, 1, player, veh)
			--VipCreateNeon(player, veh)
		elseif(pdata.neon) then
			VipDestroyNeon(player)
		end
		
		local paintjob = math.floor(tonumber(settings.paintjob) or 0)
		paintjob = math.max(math.min(paintjob, 3), 0)
		setVehiclePaintjob(veh, paintjob)
		
		if(settings.autopilot) then
			bindKey(player, "accelerate", "up", VipAutopilotFunc)
		else
			unbindKey(player, "accelerate", "up", VipAutopilotFunc)
		end
	end
	
	if(settings.driver and tonumber(settings.driver_id)) then
		setElementData(player, "fixed_skin", settings.driver_id, false)
		setElementModel(player, settings.driver_id) -- may fail if model is already set
	else
		setElementData(player, "fixed_skin", false, false)
	end
end

local function VipAvatarCallback(data, errno, player, reqID)
	local pdata = g_Players[player]
	if(not pdata) then return end
	
	if(pdata.avatarReq ~= reqID) then return end
	
	if(errno ~= 0 or data:len() == 0) then
		outputChatBox("Failed to download avatar: "..tostring(errno), player, 255, 0, 0)
		return
	end
	
	if(data:len() > 1024 * 64) then
		outputChatBox("Maximal avatar size is 64 KB!", player, 255, 0, 0)
	else
		setElementData(player, "avatar", data)
		local playerName = getPlayerName(player):gsub("#%x%x%x%x%x%x", "")
		outputDebugString(playerName.." avatar set ("..data:len().." bytes)", 3)
	end
end

local function VipSetAvatar(player, avatar)
	local pdata = g_Players[player]
	
	-- remove previous avatar first (in case of error no avatar is set)
	setElementData(player, "avatar", false)
	
	pdata.avatarReq = (pdata.avatarReq or 0) + 1
	if(not fetchRemote(avatar, VipAvatarCallback, "", false, player, pdata.avatarReq)) then
		outputDebugString("Failed to download avatar "..avatar, 2)
	end
end

local function VipApplySettings(player, veh, old_settings)
	local pdata = g_Players[player]
	local settings = pdata and pdata.settings
	if(not settings) then return end
	
	VipUpdateVehicle(player, veh)
	
	settings.avatar = tostring(settings.avatar)
	if(not old_settings or old_settings.avatar ~= settings.avatar) then
		if(settings.avatar ~= "") then
			local playerName = getPlayerName(player):gsub("#%x%x%x%x%x%x", "")
			outputDebugString("Downloading "..playerName.." avatar: "..settings.avatar, 3)
			VipSetAvatar(player, settings.avatar)
		else
			setElementData(player, "avatar", false)
		end
	end
	
	setElementData(player, "ignored_players", settings.ignored, false)
end

local function VipOnPlayerSettings(settings)
	if(isVip(client, getPlayerAccount(client)) and g_Players[client]) then
		local old_settings = g_Players[client].settings
		g_Players[client].settings = settings
		local veh = getPedOccupiedVehicle(client)
		VipApplySettings(client, veh, old_settings)
	end
end

local function VipOnPlayerQuit()
	if(g_Players[source]) then
		if(g_Players[source].neon) then
			VipDestroyNeon(source)
		end
		if(g_Players[source].vehclrtimer) then
			killTimer(g_Players[source].vehclrtimer)
		end
	end
	g_Players[source] = nil
end

local function VipOnPlayerLogin(thePreviousAccount, theCurrentAccount)
	local is_vip, timestamp = isVip(source, theCurrentAccount)
	if(is_vip and g_Players[source]) then
		g_Players[source].settings = nil
		triggerClientEvent(source, "vip.onVerified", g_Root, timestamp)
	end
end

local function VipOnPlayerVehicleEnter(veh)
	--outputDebugString("VipOnPlayerVehicleEnter ("..getPlayerName(source)..")")
	if(g_Players[source] and g_Players[source].settings) then
		VipUpdateVehicle(source, veh)
	end
end

local function VipOnPlayerVehicleExit(veh)
	local neon = g_Players[source] and g_Players[source].neon
	if(neon and neon.veh == veh) then
		VipDestroyNeon(source)
	end
end

local function VipOnPlayerWasted()
	local neon = g_Players[source] and g_Players[source].neon
	if(neon) then
		VipDestroyNeon(source)
	end
end

local function VipOnElementDestroy()
	if(getElementType(source) ~= "vehicle") then
		return
	end
	for player, data in pairs(g_Players) do
		if(data.neon and data.neon.veh == source) then
			VipDestroyNeon(player)
		end
	end
end

local function VipOnPlayerPickUpRacePickup()
	local veh = getPedOccupiedVehicle(source)
	local settings = g_Players[source] and g_Players[source].settings
	
	if(settings and settings.vehcolor and veh) then
		local r1, g1, b1 = getColorFromString(settings.vehcolor1)
		local r2, g2, b2 = getColorFromString(settings.vehcolor2)
		setVehicleColor(veh, r1, g1, b1, r2, g2, b2)
	end
end

local function VipInit()
	if(not g_VipGroup) then
		g_VipGroup = aclCreateGroup("VIP")
	end
	
	addEventHandler("vip.onReady", g_Root, VipOnRafalhVipStart)
	addEventHandler("vip.onSettings", g_Root, VipOnPlayerSettings)
	addEventHandler("onResourceStop", g_ResRoot, VipCleanup)
	addEventHandler("onPlayerQuit", g_Root, VipOnPlayerQuit)
	addEventHandler("onPlayerLogin", g_Root, VipOnPlayerLogin)
	addEventHandler("onPlayerVehicleEnter", g_Root, VipOnPlayerVehicleEnter)
	addEventHandler("onPlayerVehicleExit", g_Root, VipOnPlayerVehicleExit)
	addEventHandler("onPlayerWasted", g_Root, VipOnPlayerWasted)
	addEventHandler("onElementDestroy", g_Root, VipOnElementDestroy)
	addEventHandler("onPlayerPickUpRacePickup", g_Root, VipOnPlayerPickUpRacePickup)
end

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

function formatDateTime(timestamp)
	local tm = getRealTime(timestamp)
	return ("%u.%02u.%u %u:%02u GMT."):format(tm.monthday, tm.month+1, tm.year+1900, tm.hour, tm.minute)
end

function isPlayer(val)
	return isElement(val) and getElementType(val) == 'player'
end

function urlEncode(str)
	return str:gsub('[^%w%.%-_ ]', function(ch)
		return ('%%%02X'):format(ch:byte())
	end):gsub(' ', '+')
end

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
	
	local access, limit = VipCheck(account)
	if(access and not limit) then
		return true, false -- infinite VIP
	end
	
	local now = getRealTime().timestamp
	local newLimit = math.max(limit or now, now) + seconds
	
	local accountName = getAccountName(account)
	if(newLimit > now) then
		aclGroupAddObject(g_VipGroup, "user."..accountName)
		outputServerLog("VIP rank activated for "..accountName..". It will be active untill "..formatDateTime(newLimit))
	elseif(access) then
		-- Not VIP anymore
		VipRemove(account)
		setAccountData(account, "rafalh_vip_time", now)
	end
	
	if(player) then
		-- Send VIP limit to player (even if he was a VIP)
		triggerClientEvent(player, "vip.onVerified", g_Root, newLimit)
	end
	
	return true, newLimit
end

function VipRemove(playerOrAccount)
	local player = isPlayer(playerOrAccount) and playerOrAccount or VipGetPlayerFromAccount(playerOrAccount)
	local account = isPlayer(playerOrAccount) and getPlayerAccount(playerOrAccount) or playerOrAccount
	assert(account)
	
	local accName = getAccountName(account)
	if(not aclGroupRemoveObject(g_VipGroup, "user."..accName)) then return false end
	
	outputServerLog("VIP rank disactivated for "..accName..".")
	if(player) then
		outputChatBox("Your VIP rank has been disactivated!", player, 255, 0, 0)
	end
end

function VipActivatePlayerCode(player, code)
	if(code == "PROMO") then
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
				if(access) then
					table.insert(ret, {account, limit})
				end
			end
		end
	end
	return ret
end

function giveVip(playerOrAccount, days)
	local days = tonumber(days) or 30
	return VipAdd(playerOrAccount, days*24*3600)
end

function isVip(player, account)
	return VipCheck(account or player)
end

------------
-- Events --
------------

addEventHandler("onResourceStart", g_ResRoot, VipInit)
