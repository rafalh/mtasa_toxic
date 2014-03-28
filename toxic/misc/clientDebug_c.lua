local MAX_LEVEL = 1
local g_LastMsgCounter1s, g_LastMsgTicks1s
local g_LastMsgCounter60s, g_LastMsgTicks60s

local function onDbgMsg(msg, lvl, file, line)
	-- Check message level
	if(lvl > MAX_LEVEL) then return end
	
	-- Check if this is message from Toxic resource
	if(not file) then return end
	if(not file:match('^'..g_ResName..'[/\\]') and not file:match('[/\\]'..g_ResName..'[/\\]')) then return end
	
	local ticks = getTickCount()
	if(g_LastMsgTicks1s and ticks - g_LastMsgTicks1s < 1000) then
		if(g_LastMsgCounter1s >= 10) then return end
		g_LastMsgCounter1s = g_LastMsgCounter1s + 1
	else
		g_LastMsgTicks1s = ticks
		g_LastMsgCounter1s = 1
	end
	
	if(g_LastMsgTicks60s and ticks - g_LastMsgTicks60s < 60000) then
		if(g_LastMsgCounter60s >= 20) then return end
		g_LastMsgCounter60s = g_LastMsgCounter60s + 1
	else
		g_LastMsgTicks60s = ticks
		g_LastMsgCounter60s = 1
	end
	
	RPC('ClientDebug.addMsg', msg, lvl, file, line):exec()
end

addEventHandler('onClientDebugMessage', root, onDbgMsg, false)
