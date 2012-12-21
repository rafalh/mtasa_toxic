local g_Root = getRootElement ()
local g_ReadyPlayers = {}
local g_Items = {}
local g_Dir = "down"
local g_Respawn = true

addEvent("rb_onPlayerReady", true)

local function RbAddItem(player, rank, time)
	-- don't add the same player twice
	if(g_Items[rank] and g_Items[rank][1] == player) then return end
	
	-- add new item
	local item = {player, time}
	g_Items[rank] = item
	
	-- send it to all clients
	for player, v in pairs(g_ReadyPlayers) do
		triggerClientEvent(player, "rb_addItem", resourceRoot, rank, unpack(item))
	end
end

local function RbClear()
	g_Items = {}
	for player, v in pairs(g_ReadyPlayers) do
		triggerClientEvent(player, "rb_clear", resourceRoot, g_Dir)
	end
end

local function RbPlayerFinish(rank, time)
	RbAddItem(source, rank, time/1000)
end

local function RbMapStart(mapRes)
	-- Note: don't use source here (this function is called from RbInit)
	local checkpoints = getElementsByType("checkpoint")
	g_Dir = #checkpoints > 0 and "down" or "up"
	
	local mapResName = getResourceName(mapRes)
	local respawnStr = (get(mapResName..".respawn") or get("race.respawnmode"))
	
	g_Respawn = (respawnStr ~= "none")
	
	RbClear()
end

local function RbMapStop(mapRes)
	g_Respawn = true -- don't add items on player death
	RbClear()
end

local function RbInit()
	local mapManagerRes = getResourceFromName("mapmanager")
	if(mapManagerRes and getResourceState(mapManagerRes) == "running") then
		local mapRes = call(mapManagerRes, "getRunningGamemodeMap")
		if(mapRes) then
			RbMapStart(mapRes)
		end
	end
end

local function RbPlayerReady()
	g_ReadyPlayers[client] = true
	
	triggerClientEvent(client, "rb_clear", resourceRoot, g_Dir)
	
	for rank, item in pairs(g_Items) do
		triggerClientEvent(client, "rb_addItem", resourceRoot, rank, unpack(item))
	end
end

local function RbPlayerQuit()
	g_ReadyPlayers[source] = nil
	
	for rank, item in pairs(g_Items) do
		if(item[1] == source) then
			local playerName = getPlayerName(source)
			local r, g, b = getPlayerNametagColor(source)
			playerName = ("#%02X%02X%02X"):format(r, g, b)..playerName
			item[1] = playerName
		end
	end
end

local function RbPlayerWasted()
	--[[if(not g_Respawn) then
		local raceRes = getResourceFromName("race")
		if(raceRes and getResourceState(raceRes) == "running") then
			local timePassed = call(raceRes, "getTimePassed")
			setTimer(RbAddItem, 50, 1, source, 1, timePassed / 1000)
		end
	end]]
end

addEventHandler("onResourceStart", resourceRoot, RbInit)
addEventHandler("onPlayerFinish", root, RbPlayerFinish)
addEventHandler("onPlayerFinishDD", root, RbPlayerFinish)
addEventHandler("onPlayerQuit", root, RbPlayerQuit)
addEventHandler("onPlayerWasted", root, RbPlayerWasted)
addEventHandler("onGamemodeMapStart", root, RbMapStart)
addEventHandler("onGamemodeMapStop", root, RbMapStop)
addEventHandler("rb_onPlayerReady", resourceRoot, RbPlayerReady)
