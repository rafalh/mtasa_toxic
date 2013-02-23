local g_Achievements = {}
local g_NameToAchv = {}

addEvent("main.onAchvActivate", true)

local function AchvInitPlayer(player)
	local pdata = g_Players[player]
	if(not pdata.achvSet) then
		local achvList, achvSet = AchvGetActive(player)
		pdata.achvCount = #achvList
		pdata.achvSet = achvSet
	end
end

function AchvGetActive(player)
	local pdata = g_Players[player]
	
	local achvStr = pdata.accountData:get("achievements")
	local activeList = {string.byte(achvStr, 1, achvStr:len())}
	local activeSet = {}
	for i, id in ipairs(activeList) do
		activeSet[id] = true
	end
	
	local stats = pdata.accountData:getTbl()
	for i, achv in ipairs(g_Achievements) do
		local active = false
		if(achv.checkStats and not activeSet[achv.id] and achv.checkStats(stats)) then
			table.insert(activeList, achv.id)
			activeSet[achv.id] = true
		end
	end
	
	return activeList, activeSet
end

function AchvCheckPlayer(player)
	local pdata = g_Players[player]
	AchvInitPlayer(player)
	
	local activeList, activeSet = AchvGetActive(player)
	if(pdata.achvCount == #activeList) then return end
	
	local newAchv = {}
	for i, achv in ipairs(g_Achievements) do
		if(activeSet[achv.id] and not pdata.achvSet[achv.id]) then
			table.insert(newAchv, achv.name)
		end
	end
	
	if(#newAchv > 0) then
		AchvActivate(player, newAchv)
	end
end

function AchvRegister(achv)
	table.insert(g_Achievements, achv)
	assert(not g_NameToAchv[achv.name])
	g_NameToAchv[achv.name] = achv
end

function AchvActivate(player, names)
	if(type(names) ~= "table") then
		names = {names}
	end
	
	AchvInitPlayer(player)
	local pdata = player and g_Players[player]
	local achvStr = pdata.accountData:get("achievements")
	local achvList = {}
	
	for i, name in ipairs(names) do
		local achv = g_NameToAchv[name]
		assert(pdata and achv, name)
		
		if(not pdata.achvSet[achv.id]) then
			if(achv.save or achv.client) then
				achvStr = achvStr..string.char(achv.id)
				--outputDebugString("add "..achv.id.." to DB", 3)
			end
			
			outputDebugString("Achievement "..achv.name.." activated for "..tostring(getPlayerName(player)), 3)
			pdata.achvSet[achv.id] = true
			pdata.achvCount = pdata.achvCount + 1
			table.insert(achvList, achv.id)
			pdata.accountData:add("cash", achv.prize)
		end
	end
	
	pdata.accountData:set("achievements", achvStr, true)
	
	if(pdata.sync) then
		triggerClientEvent(player, "main.onAchvUpdate", g_ResRoot, achvList)
	end
end

local function AchvPlayerReady()
	AchvInitPlayer(client)
	local achvList = AchvGetActive(client)
	triggerClientEvent(client, "main.onAchvUpdate", g_ResRoot, achvList)
end

local function AchvClientActivate(name)
	--outputDebugString("AchvClientActivate", 3)
	
	local achv = g_NameToAchv[name]
	if(not achv or not achv.client) then return end -- hacking attempt
	
	AchvActivate(client, name)
end

addEventHandler("main.onPlayerReady", g_ResRoot, AchvPlayerReady)
addEventHandler("main.onAchvActivate", g_ResRoot, AchvClientActivate)

