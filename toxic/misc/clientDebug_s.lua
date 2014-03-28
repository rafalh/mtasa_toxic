namespace('ClientDebug')

local DEBUG_LEVELS = {[0] = 'CUSTOM', [1] = 'ERROR', [2] = 'WARN', [3] = 'INFO'}
local g_Logger = Logger('client', true)

function addMsg(msg, lvl, file, line)
	--Debug.info('ClientDebug.addMsg '..msg)
	
	local player = Player.fromEl(client)
	if(not player) then return end
	
	local ticks = getTickCount()
	if(player.clientDbgTicks and ticks - player.clientDbgTicks < 60000) then
		if(player.clientDbgCounter > 20) then return end
		player.clientDbgCounter = player.clientDbgCounter + 1
	else
		player.clientDbgTicks = ticks
		player.clientDbgCounter = 1
	end
	
	local lvlName = DEBUG_LEVELS[lvl] or 'UNK'
	local clientName = player:getName()
	local logMsg = lvlName..': '..file
	if(line) then
		logMsg = logMsg..':'..line
	end
	logMsg = logMsg..': '..msg..' (client '..clientName..')'
	g_Logger:print(logMsg)
end
RPC.allow('ClientDebug.addMsg')
