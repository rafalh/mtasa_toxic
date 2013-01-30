local g_TracedPlayers = {}

local function onTraceResult (data, player_name, player_id)
	if (not g_TracedPlayers[player_id]) then return end
	
	local msg = ""
	local trace, country = fromJSON (data)
	if (type (trace) == "string" and type (country) == "string") then
		country = country:upper ()
		if (g_Countries[country]) then
			country = g_Countries[country]
		end
		
		msg = { "%s's trace: %s.", tostring (player_name), trace..", "..country }
	else
		msg = { "Trace error: %s!", tostring (data) }
	end
	
	local oldScriptMsgState = g_ScriptMsgState
	for i, state in ipairs (g_TracedPlayers[player_id]) do
		g_ScriptMsgState = state
		scriptMsg (unpack (msg))
	end
	g_ScriptMsgState = oldScriptMsgState
	
	g_TracedPlayers[player_id] = nil
end

local function CmdTrace (message, arg)
	local player = (#arg >= 2 and findPlayer (message:sub (arg[1]:len () + 2))) or source
	local player_id = g_Players[player].id
	
	if (not g_TracedPlayers[player_id]) then
		g_TracedPlayers[player_id] = {}
	end
	table.insert(g_TracedPlayers[player_id], table.copy(g_ScriptMsgState, true))
	
	local shared_res = getResourceFromName ("rafalh_shared")
	if (shared_res and getResourceState (shared_res) == "running") then
		local url = "http://toxic.no-ip.eu/scripts/trace2.php?ip="..getPlayerIP (player)
		local req = call (shared_res, "HttpSendRequest", url, false, "GET", false, getPlayerName (player), player_id)
		if (req) then
			addEventHandler ("onHttpResult", req, onTraceResult)
		else
			privMsg (source, "Failed to get player trace")
		end
	else
		privMsg (source, "Failed to get player trace")
	end
end

CmdRegister ("trace", CmdTrace, false, "Checks where player live")

local function TrcOnPlayerQuit ()
	g_TracedPlayers[g_Players[source].id] = nil
end

addEventHandler ("onPlayerQuit", g_ResRoot, TrcOnPlayerQuit)
