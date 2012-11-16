local g_LastVotenext = 0

addEvent("onRafalhVotenextResult")
addEvent("onClientDisplayVotenextGuiReq", true)
addEvent("onVotenextReq", true)

local function onRafalhVotenextResult(roomEl, map_res)
	if (map_res) then
		local room = Room.create(roomEl)
		local map = Map.create(map_res)
		MqAdd(room, map, true)
	end
end

local function VtnStart (pattern, player)
	if (not SmGetBool("votenext_enabled")) then
		privMsg(player, "Votenext is disabled!")
		return
	end
	
	local now = getTickCount ()
	local votenext_locktime = SmGetUInt ("votenext_locktime", 30)
	if(now - g_LastVotenext < votenext_locktime * 1000) then
		privMsg(player, "You have to wait %u seconds!", (votenext_locktime * 1000 - (now - g_LastVotenext)) / 1000)
		return
	end
	
	if(pattern == "") then
		triggerClientEvent(player, "onClientDisplayVotenextGuiReq", g_ResRoot)
		return
	end
	
	local room = g_Players[player].room
	local map = findMap (pattern)
	if(not map) then
		privMsg(player, "Cannot find map \"%s\"!", pattern)
		return
	end
	
	if(MqGetMapPos(room, map)) then
		privMsg(player, "Next map is already set.")
		return
	end
	
	local forb_reason, arg = map:isForbidden(room)
	if(forb_reason) then
		privMsg (player, forb_reason, arg)
		return
	end
	
	local mapName = map:getName()
	local voteMgrRes = getResourceFromName ("votemanager")
	if(not voteMgrRes or getResourceState (voteMgrRes) ~= "running") then
		return
	end
	
	-- Actual vote started here
	local pollDidStart = call (voteMgrRes, "startPoll", {
		title = "Set next map to "..mapName.."?",
		percentage = SmGetUInt ("votenext_percentage", 50),
		timeout = SmGetUInt ("votenext_timeout", 30),
		allowchange = SmGetBool ("votenext_allowchange"),
		visibleTo = g_Root,
		[1] = { "Yes", "onRafalhVotenextResult", g_ResRoot, room.el, map.res },
		[2] = { "No", "onRafalhVotenextResult", g_ResRoot, room.el, false; default=true },
	})
	
	if (pollDidStart) then
		g_LastVotenext = now
		customMsg (128, 255, 196, "%s started vote for next map: %s.", getPlayerName (player), mapName)
	else
		privMsg (player, "Error! Poll did not started.")
	end
end

local function CmdVoteNext(message, arg)
	local pattern = message:sub(arg[1]:len() + 2)
	VtnStart(pattern, source)
end

CmdRegister ("votenext", CmdVoteNext, false, "Starts a vote for next map")

local function onVotenextReq(map_res_name)
	VtnStart(map_res_name, client)
end

addEventHandler("onRafalhVotenextResult", g_ResRoot, onRafalhVotenextResult)
addEventHandler("onVotenextReq", g_ResRoot, onVotenextReq)
