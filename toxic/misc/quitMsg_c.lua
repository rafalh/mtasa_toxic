local function onPlayerQuit(reason)
	local nick = getPlayerName(source)
	
	if (reason == 'Kicked') then outputMsg(Styles.joinQuit, "* %s has been kicked from the game.", nick)
	elseif (reason == 'Banned') then outputMsg(Styles.joinQuit, "* %s has been banned from the game.", nick)
	elseif (reason == 'Quit') then outputMsg(Styles.joinQuit, "* %s has left the game.", nick)
	else outputMsg(Styles.joinQuit, "* %s has left the game [%s].", nick, reason) end
end

addInitFunc(function()
	addEventHandler('onClientPlayerQuit', g_Root, onPlayerQuit)
end)
