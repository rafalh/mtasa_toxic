local g_Root = getRootElement()
local g_MapMode = ""
local g_KillReq = false

addEvent("onMapStarting")
addEvent("onRequestKillPlayer", true)
addEvent("onPlayerToptimeImprovement")

local function playAudio(player, filename)
	-- outputDebugString("play sound "..filename.." for "..getPlayerName(player))
	triggerClientEvent(player, "playClientAudio", getRootElement(), filename)
end

local function onMapStarting(mapInfo)
	g_MapMode = mapInfo.modename
end

local function onPlayerWasted()
	if g_MapMode == "Destruction derby" then
		playAudio(source, "jobfail.mp3")
	elseif(g_KillReq) then
		g_KillReq = false
	else
		playAudio(source, "wasted.mp3")
	end
end

local function onRequestKillPlayer()
	g_KillReq = true
end

local function onPlayerToptimeImprovement(newPos, newTime, oldPos, oldTime, displayTopCount, validEntryCount)
	--TODO: Fix this event
	if newPos <= displayTopCount and newPos <= validEntryCount then
		playAudio(source, "nicework.mp3")
	end
end

local function onPlayerWinDD()
	playAudio(source, "jobcomplete.mp3")
end

addEventHandler('onMapStarting', g_Root, onMapStarting)
addEventHandler('onPlayerWasted', g_Root, onPlayerWasted)
addEventHandler('onRequestKillPlayer', g_Root, onRequestKillPlayer)
addEventHandler("onPlayerToptimeImprovement", g_Root, onPlayerToptimeImprovement)
addEventHandler("onPlayerWinDD", g_Root, onPlayerWinDD)
