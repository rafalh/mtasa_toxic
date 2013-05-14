----------------------
-- Global variables --
----------------------

g_Root = getRootElement()
g_ThisRes = getThisResource()
g_ResRoot = getResourceRootElement(g_ThisRes)
local g_Players = {}
local g_VipGroup = aclGetGroup("VIP")

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

local function VipAvatarCallback(data, errno, player)
	if(errno == 0 and data:len() > 0) then
		if(data:len() > 1024 * 64) then
			outputChatBox("Maximal avatar size is 64 KB!", player, 255, 0, 0)
		else
			setElementData(player, "avatar", data)
			local playerName = getPlayerName(player):gsub("#%x%x%x%x%x%x", "")
			outputDebugString(playerName.." avatar set ("..data:len().." bytes)", 3)
		end
	else
		outputChatBox("Failed to download avatar: "..tostring(errno), player, 255, 0, 0)
	end
end

local function VipHttpResult(data, player)
	VipAvatarCallback(data, data and 0 or -1, player)
	g_Players[player].avatar_req_el = false
end

addEvent("onHttpResult")

local function VipSetAvatar(player, avatar)
	local pdata = g_Players[player]
	if(pdata.avatar_req_el) then
		destroyElement(pdata.avatar_req_el)
	end
	
	-- remove previous avatar first (in case of error no avatar is set)
	setElementData(player, "avatar", false)
	
	if(curl_init and false) then -- crashes
		local curl = curl_init()
		local avatar = "mtatoxic.tk"
		outputDebugString("cURL detected: "..avatar.." ("..curl_escape(curl, avatar)..")", 3)
		local avatar2 = curl_escape(curl, avatar)
		curl_setopt(curl, CURLOPT_URL, avatar2)
		local code = curl_perform(curl, {
			writefunction = function(data)
				outputDebugString("Avatar: "..#data, 2)
			end,
			headerfunction = function(data)
				outputDebugString("Header: "..#data, 2)
			end})
		if(ret ~= CURLE_OK) then
			outputDebugString("curl_perform failed: "..curl_strerror(curl, code), 2)
		end
		curl_close(curl)
	elseif(sockOpen) then
		outputDebugString("Sockets module detected", 3)
		local sharedRes = getResourceFromName("rafalh_shared")
		local req_el = sharedRes and getResourceState(sharedRes) == "running" and call(sharedRes, "HttpSendRequest", avatar, false, false, false, player)
		if(req_el) then
			pdata.avatar_req_el = req_el
			addEventHandler("onHttpResult", req_el, VipHttpResult)
		else
			outputChatBox("Invalid URL: "..avatar, player, 255, 0, 0)
		end
	elseif(not fetchRemote(avatar, VipAvatarCallback, "", false, player)) then
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

local function VipGetPlayerFromAccount(account)
	for i, player in ipairs(getElementsByType("player")) do
		if(getPlayerAccount(player) == account) then
			return player
		end
	end
	
	return false
end

local function VipOnActivationResult2(data, account)
	local account_name = account and getAccountName(account)
	if(not account_name) then
		outputChatBox("Error! VIP activation failed (account is invalid). Please contact administrator.", g_Root, 255, 0, 0)
		return
	end
	
	local player = VipGetPlayerFromAccount(account)
	local activated, descr = fromJSON(data)
	
	local err = false
	if(activated == nil) then
		err = tostring(data):gsub("<[^>]+>", "")
	elseif(not activated) then
		err = tostring(descr)
	elseif(not g_VipGroup) then
		err = "VipGroup does not exist"
	end
	
	if(err) then
		outputChatBox("PM: VIP activation failed ("..err:sub(1, 64).."). Please contact administrator.", player or g_Root, 255, 96, 96, true)
		return
	end
	
	local msg, timestamp
	local tm = getRealTime()
	
	aclGroupAddObject(g_VipGroup, "user."..account_name)
	timestamp = math.max(getAccountData(account, "rafalh_vip_time") or tm.timestamp, tm.timestamp)
	
	if(tm.year*12*31 + tm.month*31 + tm.monthday >= $((PROMO_YEAR1-1900)*12*31+(PROMO_MONTH1-1)*31+PROMO_DAY1) and tm.year*12*31 + tm.month*31 + tm.monthday <= $((PROMO_YEAR2-1900)*12*31+(PROMO_MONTH2-1)*31+PROMO_DAY2)) then
		timestamp = timestamp + (1 + $(PROMO_MONTHS))*30*24*60*60
		tm = getRealTime(timestamp)
		msg = "#00FF00Vip activated successfully! $(PROMO_TEXT) Rank will be valid untill "..("%u.%02u.%u %u:%02u GMT."):format(tm.monthday, tm.month + 1, tm.year + 1900, tm.hour, tm.minute)
	else
		timestamp = timestamp + 30*24*60*60
		tm = getRealTime(timestamp)
		msg = "#00FF00Vip activated successfully! Rank will be valid untill "..("%u.%02u.%u %u:%02u GMT."):format(tm.monthday, tm.month + 1, tm.year + 1900, tm.hour, tm.minute)
	end
	
	setAccountData(account, "rafalh_vip_time", timestamp)
	
	outputServerLog("VIP rank activated for "..account_name..". It will be valid untill "..("%u.%02u.%u %u:%02u GMT."):format(tm.monthday, tm.month + 1, tm.year + 1900, tm.hour, tm.minute))
	
	if(player) then
		outputChatBox("PM: "..msg, player, 255, 96, 96, true)
		if(g_Players[player].synced) then
			triggerClientEvent(player, "vip.onVerified", g_Root, timestamp)
		end
	end
end

addCommandHandler("activatevip", function(source, cmd, code)
	local account = getPlayerAccount(source)
	
	if(isGuestAccount(account)) then
		outputChatBox("PM: Register an account and log in before using this command.", source)
	elseif(code) then
		if(code == "PROMO") then
			if(getAccountData(account, "rafalh_vip_promo")) then
				outputChatBox("PM: You have already used VIP promotion code.", source, 255, 96, 96)
			elseif(g_VipGroup) then
				setAccountData(account, "rafalh_vip_promo", 1)
				aclGroupAddObject(g_VipGroup, "user."..getAccountName(account))
				local tm = getRealTime ()
				local t = math.max(getAccountData(account, "rafalh_vip_time") or tm.timestamp, tm.timestamp)
				t = t + 60*60
				setAccountData(account, "rafalh_vip_time", t)
				
				local tm = getRealTime(t)
				
				outputServerLog("VIP rank activated for "..getAccountName(account)..". It will be valid untill "..("%u.%02u.%u %u:%02u GMT."):format(tm.monthday, tm.month+1, tm.year+1900, tm.hour, tm.minute))
				outputChatBox("#00FF00Vip activated successfully! It will be valid for 1 hour untill "..("%u.%02u.%u %u:%02u GMT."):format(tm.monthday, tm.month+1, tm.year+1900, tm.hour, tm.minute), source, 255, 96, 96)
			end
		else
			local err = false
			
			local shared_res = getResourceFromName("rafalh_shared")
			if(shared_res and getResourceState(shared_res) == "running") then
				local code_encoded = call(shared_res, "HttpEncodeUrl", code)
				local url = "http://mtatoxic.tk/scripts/NGWm5LtQ5fmnnmpx/activate_code.php?code="..code_encoded
				local req = call(shared_res, "HttpSendRequest", url, false, "GET", false, account, player)
				if(req) then
					addEventHandler("onHttpResult", req, VipOnActivationResult2)
				else
					err = 2
				end
			else
				err = 1
			end
			
			if(err) then
				outputChatBox("Error "..err.."! Failed to activate VIP account. Please contact administrator.", source, 255, 96, 96)
			end
		end
	else
		outputChatBox("PM: Usage: /activatevip <code>", source, 255, 96, 96)
	end
end, false, false)

local function findPlayer(str)
	if(not str) then
		return false
	end
	
	local player = getPlayerFromName(str) -- returns player or false
	if(player) then
		return player
	end
	
	str = str:lower()
	for i, player in ipairs(getElementsByType("player")) do
		local name = getPlayerName(player):gsub("#%x%x%x%x%x%x", ""):lower()
		if(name:find(str, 1, true)) then
			return player
		end
	end
	
	return false
end

addCommandHandler("givevip", function(source, cmd, name, days)
	if(hasObjectPermissionTo(source, "resource.rafalh_vip.givevip", false)) then
		local player = findPlayer(name)
		local days = math.floor(tonumber(days) or 30)
		local account = player and getPlayerAccount(player)
		
		if(giveVip(player, days)) then
			local timestamp = getAccountData(account, "rafalh_vip_time")
			local tm = timestamp and getRealTime(timestamp)
			local name = getPlayerName(player):gsub("#%x%x%x%x%x%x", "")
			
			outputChatBox("PM: VIP rank successfully given to "..name.."! It will be valid untill "..("%u.%02u.%u %u:%02u GMT."):format(tm.monthday, tm.month+1, tm.year+1900, tm.hour, tm.minute), source, 255, 96, 96, true)
			outputChatBox("#00FF00Vip activated successfully! It will be valid untill "..("%u.%02u.%u %u:%02u GMT."):format(tm.monthday, tm.month+1, tm.year+1900, tm.hour, tm.minute), player, 255, 96, 96, true)
		else
			outputChatBox("PM: Usage: /givevip <name> [<days>]", source, 255, 96, 96)
		end
	else
		outputChatBox("PM: Access is denied!", source, 255, 96, 96)
	end
end, false, false)

addCommandHandler("isvip", function(source, cmd, name)
	local player = findPlayer(name)
	
	if(player) then
		local name = getPlayerName(player):gsub("#%x%x%x%x%x%x", "")
		local is_vip, timestamp = isVip(player)
		local tm = timestamp and getRealTime(timestamp)
		
		if(is_vip) then
			if(timestamp) then
				outputChatBox("PM: "..name.." is a VIP untill "..("%u.%02u.%u %u:%02u GMT."):format(tm.monthday, tm.month+1, tm.year+1900, tm.hour, tm.minute), source, 255, 96, 96, true)
			else
				outputChatBox("PM: "..name.." is a VIP.", source, 255, 96, 96, true)
			end
		else
			if(timestamp) then
				outputChatBox("PM: "..name.." was a VIP untill "..("%u.%02u.%u %u:%02u GMT."):format(tm.monthday, tm.month+1, tm.year+1900, tm.hour, tm.minute), source, 255, 96, 96, true)
			else
				outputChatBox("PM: "..name.." is not a VIP.", source, 255, 96, 96, true)
			end
		end
	else
		outputChatBox("PM: Usage: /isvip <name>", source, 255, 96, 96)
	end
end, false, false)

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

----------------------
-- Global functions --
----------------------

function giveVip(player, days)
	local days = tonumber(days) or 30
	local account = player and getPlayerAccount(player)
	
	if(not account or isGuestAccount(account) or not g_VipGroup) then
		return false
	end
	
	aclGroupAddObject(g_VipGroup, "user."..getAccountName(account))
	
	local now = getRealTime().timestamp
	local timestamp = math.max(getAccountData(account, "rafalh_vip_time") or 0, now) + days*24*60*60
	
	setAccountData(account, "rafalh_vip_time", timestamp)
	
	local tm = getRealTime(timestamp)
	
	outputServerLog("VIP rank activated for "..getAccountName(account)..". It will be active untill "..("%u.%02u.%u %u:%02u GMT."):format(tm.monthday, tm.month+1, tm.year+1900, tm.hour, tm.minute))
	
	if(timestamp > now) then
		triggerClientEvent(player, "vip.onVerified", g_Root, timestamp)
	end
	
	return true
end

function isVip(player, account)
	local is_vip, timestamp = false, false
	local now = getRealTime().timestamp
	
	if(not account) then
		account = getPlayerAccount(player)
	end
	
	local promo_end = tonumber(get("promo_end"))
	if(promo_end > now) then
		timestamp = promo_end
		is_vip = true
	end
	
	if(hasObjectPermissionTo(player, "resource.rafalh_vip", false)) then
		local acc_timestamp = getAccountData(account, "rafalh_vip_time")
		timestamp = acc_timestamp and math.max(timestamp or 0, acc_timestamp)
		if(not acc_timestamp or timestamp > now) then
			is_vip = true
		end
		
		if(timestamp and timestamp < now) then
			aclGroupRemoveObject(g_VipGroup, "user."..getAccountName(account))
			outputServerLog("VIP rank disactivated for "..getAccountName(account)..".")
			outputChatBox("PM: Your VIP rank has been disactivated.", player, 255, 0, 0)
		end
	end
	
	return is_vip, timestamp
end

------------
-- Events --
------------

addEventHandler("onResourceStart", g_ResRoot, VipInit)
