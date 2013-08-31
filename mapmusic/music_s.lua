local g_Root = getRootElement()
local g_ResRoot = getResourceRootElement()
local g_Players = {}
local g_Music = {}
local g_ServerAddress = get("server_address")

addEvent("mapmusic.onStartReq", true)
addEvent("mapmusic.onStopReq", true)
addEvent("mapmusic.onPlayerReady", true)
addEvent("onRaceStateChanging")
addEvent("onPlayerJoinRoom")
addEvent("onPlayerLeaveRoom")

local function getMapRes(room)
	local mapMgrRes = getResourceFromName("mapmanager")
	if(mapMgrRes and getResourceState(mapMgrRes) == "running") then
		return call(mapMgrRes, "getRunningGamemodeMap")
	end
	
	local roomMgrRes = getResourceFromName("roommgr")
	if(roomMgrRes and getResourceState(roomMgrRes) == "running" and room) then
		return call(roomMgrRes, "getRoomMapResource", room)
	end
	return false
end

local function getRooms()
	local roomMgrRes = getResourceFromName("roommgr")
	if(roomMgrRes and getResourceState(roomMgrRes) == "running") then
		return call(roomMgrRes, "getRooms")
	end
	return {false}
end

local function getPlayerRoom(player)
	local roomID = getElementData(player, "roomid")
	return roomID and getElementByID(roomID)
end

local function startMusic(res, room)
	--outputDebugString("startMusic", 3)
	local res_name = getResourceName(res)
	local path = getResourceInfo(res, "music") or get(res_name..".music")
	if(path) then
		g_Music[room] = {}
		g_Music[room].res = res
		g_Music[room].res_name = res_name
		g_Music[room].path = path
		local url = path
		if(not url:match("^%a+://")) then
			url =  "http://"..g_ServerAddress.."/"..g_Music[room].res_name.."/"..path
		end
		g_Music[room].url = url
		
		for player, playerRoom in pairs(g_Players) do
			if(playerRoom == room) then
				triggerClientEvent(player, "mapmusic.onStartReq", g_ResRoot, g_Music[room].url)
			end
		end
	else
		--outputDebugString("No music!", 3)
	end
end

local function stopMusic(room)
	if(not g_Music[room]) then return end
	
	g_Music[room] = false
	
	for player, playerRoom in pairs(g_Players) do
		if(playerRoom == room) then
			triggerClientEvent(player, "mapmusic.onStopReq", g_ResRoot)
		end
	end
end

local function onResStop(res)
	local roomID = getElementData(getResourceRootElement(res), "roomid")
	local room = roomID and getElementByID(roomID)
	if(not g_Music[room] or g_Music[room].res ~= res) then return end
	stopMusic(room)
end

local function onPlayerReady()
	--outputDebugString ( "onPlayerReady", 3 )
	local room = getPlayerRoom(client)
	g_Players[client] = room
	if(g_Music[room]) then
		--outputDebugString ( "Start music", 3 )
		triggerClientEvent(client, "mapmusic.onStartReq", g_ResRoot, g_Music[room].url)
	end
end

local function onPlayerQuit()
	g_Players[source] = nil
end

local function onPlayerJoinRoom(room)
	if(g_Players[source] == nil) then return end
	local oldRoom = g_Players[source]
	g_Players[source] = room
	
	if(g_Music[room]) then
		triggerClientEvent(source, "mapmusic.onStartReq", g_ResRoot, g_Music[room].url)
	elseif(g_Music[oldRoom]) then
		triggerClientEvent(source, "mapmusic.onStopReq", g_ResRoot)
	end
end

local function onPlayerLeaveRoom()
	if(g_Players[source] == nil) then return end
	
	local room = false
	local oldRoom = g_Players[source]
	g_Players[source] = room
	
	if(g_Music[room]) then
		triggerClientEvent(source, "mapmusic.onStartReq", g_ResRoot, g_Music[room].url)
	elseif(g_Music[oldRoom]) then
		triggerClientEvent(source, "mapmusic.onStopReq", g_ResRoot)
	end
end

local function onElDestroy()
	if(g_Music[source]) then
		stopMusic(source)
	end
end

local function onRaceStateChanging(state, oldState, room)
	if(state == "GridCountdown") then
		local map_res = getMapRes(room or false)
		startMusic(map_res, room or false)
	end
end

local function init()
	--outputDebugString ( "init", 3 )
	local rooms = getRooms()
	for i, room in ipairs(rooms) do
		local mapRes = getMapRes(room)
		if(mapRes) then
			startMusic(mapRes, room)
		end
	end
	
	--addEventHandler("onGamemodeMapStart", g_Root, startMusic)
	addEventHandler("onResourceStop", g_Root, onResStop)
	addEventHandler("onPlayerQuit", g_Root, onPlayerQuit)
	addEventHandler("onPlayerLeaveRoom", g_Root, onPlayerLeaveRoom)
	addEventHandler("onPlayerJoinRoom", g_Root, onPlayerJoinRoom)
	addEventHandler("onElementDestroy", g_Root, onElDestroy)
	addEventHandler("onRaceStateChanging", g_Root, onRaceStateChanging)
	addEventHandler("mapmusic.onPlayerReady", g_ResRoot, onPlayerReady)
end

addEventHandler("onResourceStart", g_ResRoot, init)
