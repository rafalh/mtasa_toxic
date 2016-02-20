----------------------
-- Global variables --
----------------------

g_Root = getRootElement()
g_ThisRes = getThisResource()
g_ResRoot = getResourceRootElement(g_ThisRes)
g_Players = {}
g_VipGroup = aclGetGroup('VIP')
g_VipRight = 'resource.rafalh_vip'

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

local function VipAutopilotFunc(player)
	local pdata = g_Players[player]
	pdata.autopilot = not pdata.autopilot
	setTimer(setControlState, 50, 1, player, "accelerate", pdata.autopilot)
end

local function VipFixUpgradesList(upgrades)
	for slot, upg in pairs(upgrades) do
		-- 11-Unknown, 8-Nitro
		if(not slot and slot == 11 or slot == 8 or slot ~= VipGetVehicleUpgradeSlot(upg)) then
			upgrades[slot] = nil
		end
	end
	return upgrades
end

local function VipUpdateVehicle(player, veh)
	local pdata = g_Players[player]
	local settings = pdata and pdata.settings
	if(not settings) then return end
	
	if(veh) then
		-- Used later in VipOnPlayerPickUpRacePickup to detect vehicle change
		pdata.vehModel = getElementModel(veh)
		
		if(settings.vehcolor) then
			local r1, g1, b1 = getColorFromString(settings.vehcolor1)
			local r2, g2, b2 = getColorFromString(settings.vehcolor2)
			setVehicleColor(veh, r1, g1, b1, r2, g2, b2)
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
		
		local ignoreHydraulicsUpgrade = {[444] = true, [556] = true, [557] = true}
		for slot, upg in pairs(settings.vehupgrades) do
			if(slot ~= 9 or not ignoreHydraulicsUpgrade[pdata.vehModel]) then
				addVehicleUpgrade(veh, upg)
			end
		end
		
		--[[if(settings.wheels and settings.wheels >= 1073 and settings.wheels <= 1098) then
			if(getVehicleType(veh) == 'Automobile') then
				if(not addVehicleUpgrade(veh, settings.wheels)) then
					outputDebugString('addVehicleUpgrade failed', 2)
				else
					--outputDebugString('Wheels added', 3)
				end
			end
		else
			local upg = getVehicleUpgradeOnSlot(veh, 12)
			if(upg) then
				--outputDebugString('Wheels removed', 3)
				removeVehicleUpgrade(veh, upg)
			end
		end]]
	end
	
	if(settings.driver and tonumber(settings.driver_id)) then
		setElementData(player, "fixed_skin", settings.driver_id, false)
		setElementModel(player, settings.driver_id) -- may fail if model is already set
	else
		setElementData(player, "fixed_skin", false, false)
	end
end

local function VipCheckAvatarFormat(data)
	local data4b = data:sub(1, 4)
	if(data4b:sub(1, 2) == 'BM') then return true end -- Bitmap
	if(data4b:sub(1, 2) == '\255\216') then return true end -- JPEG (\xFF\xD8)
	if(data4b:sub(1, 4) == '\137PNG') then return true end -- PNG (\x89PNG)
	if(data4b:sub(1, 3) == 'GIF') then return true end -- GIF
	return false
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
	elseif(not VipCheckAvatarFormat(data)) then
		outputChatBox("Unknown avatar image format!", player, 255, 0, 0)
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

local function VipBroadcastGlobalInfo(srcPlayer)
	local srcData = g_Players[srcPlayer]
	
	for player, pdata in pairs(g_Players) do
		triggerClientEvent(player, 'vip.onPlayerInfo', resourceRoot, srcPlayer, srcData.globalInfo)
	end
end

local function VipApplySettings(player, veh, oldSettings)
	local pdata = g_Players[player]
	local settings = pdata and pdata.settings
	if(not settings) then return end
	
	VipUpdateVehicle(player, veh)
	
	pdata.globalInfo = {
		rainbow = settings.vehrainbow and settings.vehrainbow_speed,
	}
	
	VipBroadcastGlobalInfo(player)
	
	settings.avatar = tostring(settings.avatar)
	if(not oldSettings or oldSettings.avatar ~= settings.avatar) then
		if(settings.avatar ~= "") then
			local playerName = getPlayerName(player):gsub("#%x%x%x%x%x%x", "")
			outputDebugString("Downloading "..playerName.." avatar: "..settings.avatar, 3)
			VipSetAvatar(player, settings.avatar)
		else
			setElementData(player, "avatar", false)
		end
	end
	
	setElementData(player, "ignored_players", settings.ignored, false)
	
	if(veh and oldSettings and not table.compare(settings.vehupgrades, oldSettings.vehupgrades)) then
		for slot, upg in pairs(oldSettings.vehupgrades) do
			if(not settings.vehupgrades[slot]) then
				removeVehicleUpgrade(veh, upg)
			end
		end
	end
end

local function VipOnPlayerQuit()
	local pdata = g_Players[source]
	if(not pdata) then return end
	
	if(pdata.neon) then
		VipDestroyNeon(source)
	end
	
	g_Players[source] = nil
end

local function VipOnPlayerLogin(thePreviousAccount, theCurrentAccount)
	local pdata = g_Players[source]
	local access, timestamp = isVip(source, theCurrentAccount)
	if(access and pdata) then
		pdata.access = true
		pdata.settings = nil
		triggerClientEvent(source, "vip.onVerified", resourceRoot, timestamp)
	end
end

local function VipOnPlayerVehicleEnter(veh)
	--outputDebugString("VipOnPlayerVehicleEnter ("..getPlayerName(source)..")")
	local pdata = g_Players[source]
	if(not pdata) then return end
	
	if(pdata.settings) then
		VipUpdateVehicle(source, veh)
	end
end

local function VipOnPlayerVehicleExit(veh)
	local pdata = g_Players[source]
	if(not pdata) then return end
	
	if(pdata.neon and pdata.neon.veh == veh) then
		VipDestroyNeon(source)
	end
end

local function VipOnPlayerWasted()
	local pdata = g_Players[source]
	if(not pdata) then return end
	
	if(pdata.neon) then
		VipDestroyNeon(source)
	end
end

local function VipOnPlayerPickUpRacePickup()
	local veh = getPedOccupiedVehicle(source)
	local pdata = g_Players[source]
	local settings = g_Players[source] and g_Players[source].settings
	if(not pdata or not settings or not veh) then return end
	
	-- Check if model has changed - vehiclechange pickup
	local curModel = getElementModel(veh)
	if(pdata.vehModel == curModel) then return end
	
	VipUpdateVehicle(source, veh)
end

local function VipOnClientReady()
	local pdata = {}
	g_Players[client] = pdata
	
	local access, timestamp = isVip(client, getPlayerAccount(client))
	
	if(access) then
		triggerClientEvent(client, "vip.onVerified", resourceRoot, timestamp)
		pdata.access = true
	end
	
	if(VipIsPromoActive()) then
		addEvent("vip.onShowPromoBannerReq", true)
		triggerClientEvent(client, "vip.onShowPromoBannerReq", g_Root)
		pdata.access = true
	end
	
	for curPlayer, curData in pairs(g_Players) do
		if(curData.globalInfo) then
			triggerClientEvent(client, 'vip.onPlayerInfo', curPlayer, curData.globalInfo)
		end
	end
end

local function VipOnPlayerSettings(settings)
	local pdata = g_Players[client]
	if(not pdata or not pdata.access) then return end
	
	local oldSettings = pdata.settings
	pdata.settings = settings
	pdata.settings.vehupgrades = VipFixUpgradesList(pdata.settings.vehupgrades)
	
	local veh = getPedOccupiedVehicle(client)
	VipApplySettings(client, veh, oldSettings)
end

local function VipCleanup()
	for player, pdata in pairs(g_Players) do
		if(pdata.neon) then
			VipDestroyNeon(player)
		end
	end
end

local function setupAcl()
	-- Create ACL with 'resource.rafalh_vip' right and group with that ACL
	local acl = aclGet('VIP')
	local rightSet = acl and aclGetRight(acl, g_VipRight)
	
	if (g_VipGroup and acl and rightSet) then
		-- Everything is ok
		return true
	end
	
	local neededFunctions = {'aclCreate', 'aclSetRight', 'aclCreateGroup', 'aclGroupAddACL'}
	for i, v in ipairs(neededFunctions) do
		if (not hasObjectPermissionTo(resource, 'function.'..v)) then
			outputChatBox('Add VIP group and ACL manually!')
			return false
		end
	end

	if (not acl) then
		acl = aclCreate('VIP')
	end
	if (rightSet) then
		rightSet = aclSetRight(acl, g_VipRight, true)
	end
	if (not g_VipGroup) then
		g_VipGroup = aclCreateGroup('VIP')
		aclGroupAddACL(g_VipGroup, acl)
	end
	return (g_VipGroup and acl and rightSet)
end

local function VipInit()
	if (not setupAcl()) then
		cancelEvent()
	end
	
	addEventHandler("vip.onReady", g_Root, VipOnClientReady)
	addEventHandler("vip.onSettings", g_Root, VipOnPlayerSettings)
	addEventHandler("onResourceStop", g_ResRoot, VipCleanup)
	addEventHandler("onPlayerQuit", g_Root, VipOnPlayerQuit)
	addEventHandler("onPlayerLogin", g_Root, VipOnPlayerLogin)
	addEventHandler("onPlayerVehicleEnter", g_Root, VipOnPlayerVehicleEnter)
	addEventHandler("onPlayerVehicleExit", g_Root, VipOnPlayerVehicleExit)
	addEventHandler("onPlayerWasted", g_Root, VipOnPlayerWasted)
	addEventHandler("onPlayerPickUpRacePickup", g_Root, VipOnPlayerPickUpRacePickup)
end

------------
-- Events --
------------

addEventHandler('onResourceStart', g_ResRoot, VipInit)
