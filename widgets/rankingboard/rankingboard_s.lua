local g_Root = getRootElement ()
local g_ReadyPlayers = {}
local g_Items = {} -- in chronology order
local TEST = false

addEvent("rb_onPlayerReady", true)

local function RbAddItem(player, rank, time)
	-- don't add the same player twice
	if(not TEST) then
		for i, item in ipairs(g_Items) do
			if(item[1] == player) then return end
		end
	end
	
	-- add new item
	local item = {player, rank, time}
	table.insert(g_Items, item)
	
	-- send it to all clients
	for player, v in pairs(g_ReadyPlayers) do
		triggerClientEvent(player, "rb_addItem", resourceRoot, unpack(item))
	end
end

local function RbClear()
	g_Items = {}
	for player, v in pairs(g_ReadyPlayers) do
		triggerClientEvent(player, "rb_clear", resourceRoot)
	end
end

local function RbPlayerFinish(rank, time)
	RbAddItem(source, rank, time/1000)
end

local function RbMapStart(mapRes)
	RbClear()
end

local function RbMapStop(mapRes)
	RbClear()
end

local function RbPlayerReady()
	g_ReadyPlayers[client] = true
	
	triggerClientEvent(client, "rb_clear", resourceRoot)
	
	for i, item in ipairs(g_Items) do
		triggerClientEvent(client, "rb_addItem", resourceRoot, unpack(item))
	end
end

local function RbPlayerQuit()
	g_ReadyPlayers[source] = nil
	
	for i, item in ipairs(g_Items) do
		if(item[1] == source) then
			local playerName = getPlayerName(source)
			local r, g, b = getPlayerNametagColor(source)
			playerName = ("#%02X%02X%02X"):format(r, g, b)..playerName
			item[1] = playerName
		end
	end
end

addEventHandler("onPlayerFinish", root, RbPlayerFinish)
addEventHandler("onPlayerFinishDD", root, RbPlayerFinish)
addEventHandler("onPlayerQuit", root, RbPlayerQuit)
addEventHandler("onGamemodeMapStart", root, RbMapStart)
addEventHandler("onGamemodeMapStop", root, RbMapStop)
addEventHandler("rb_onPlayerReady", resourceRoot, RbPlayerReady)

if(TEST) then
	addCommandHandler("testrb", function(player, cmd, arg, arg2)
		local n = tonumber(arg) or 1
		local dir = arg2 and true
		local sec = g_Items[#g_Items] and g_Items[#g_Items][3] or 0
		local pos = g_Items[#g_Items] and g_Items[#g_Items][2] or (dir and 15 or 0)
		for i = 1, n do
			sec = sec + math.random(20, 100)
			pos = pos + (dir and -1 or 1)
			RbAddItem(player, pos, sec)
		end
	end)
end
