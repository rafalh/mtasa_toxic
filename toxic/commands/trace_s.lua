local g_TracedPlayers = {}
local TRACE_URL = 'http://ravin.tk/api/mta/trace.php?ip=%s'

local function onTraceResult(data, errno, player_name, player_id)
	if(not g_TracedPlayers[player_id]) then return end
	
	local msg = ''
	local trace, country = fromJSON(data)
	if(data ~= 'ERROR' and type(trace) == 'string' and type(country) == 'string') then
		country = country:upper()
		if(g_Countries[country]) then
			country = g_Countries[country]
		end
		
		msg = {"%s's trace: %s.", tostring(player_name), trace..', '..country}
	else
		msg = {"Trace error: %s!", tostring(data)..' '..tostring(errno)}
	end
	
	local oldScriptMsgState = g_ScriptMsgState
	for i, state in ipairs(g_TracedPlayers[player_id]) do
		g_ScriptMsgState = state
		scriptMsg(unpack(msg))
	end
	g_ScriptMsgState = oldScriptMsgState
	
	g_TracedPlayers[player_id] = nil
end

CmdMgr.register{
	name = 'trace',
	desc = "Checks where the player lives",
	args = {
		{'player', type = 'player', defValFromCtx = 'player'},
	},
	func = function(ctx, player)
		if(not player.id) then
			privMsg(ctx.player, "Guests cannot use this command")
			return
		end
		
		if(not g_TracedPlayers[player.id]) then
			g_TracedPlayers[player.id] = {}
		end
		table.insert(g_TracedPlayers[player.id], table.copy(g_ScriptMsgState, true))
	
		local url = TRACE_URL:format(urlEncode(player:getIP()))
		if(not fetchRemote(url, onTraceResult, '', false, player:getName(true), player.id)) then
			privMsg(ctx.player, "Failed to get player trace")
		end
	end
}

local function TrcOnPlayerQuit()
	local pdata = Player.fromEl(source)
	if(pdata.id) then
		g_TracedPlayers[pdata.id] = nil
	end
end

addInitFunc(function()
	addEventHandler('onPlayerQuit', g_Root, TrcOnPlayerQuit)
end)
