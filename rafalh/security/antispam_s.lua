function AsProcessMsg(player)
	local pdata = Player.fromEl(player)
	local spamInterval = Settings.spam_interval
	local ticks = getTickCount()
	
	if(pdata.lastMsg and (ticks - pdata.lastMsg) < spamInterval) then
		local name = getPlayerName(player)
		if(pdata.antispamWarning and (ticks - pdata.antispamWarning) < spamInterval) then
			if(Settings.spammer_kick) then
				scriptMsg("%s has been kicked for spamming.", name)
				kickPlayer(player, "Spam")
			else
				outputMsg(g_Root, Styles.red, "%s has been muted for spamming.", name)
				mutePlayer(player, 60, false, true)
			end
			return true
		else
			if(Settings.spammer_kick) then
				privMsg(player, "Do not spam %s! Otherwise you will get kicked.", name)
			else
				privMsg(player, "Do not spam %s! Otherwise you will get muted.", name)
			end
			pdata.antispamWarning = ticks
		end
	end
	pdata.lastMsg = ticks
	return false
end

function AsCanPlayerChangeNick(player, newNick, oldNick)
	oldNick = oldNick and oldNick:gsub("#%x%x%x%x%x%x", "")
	newNick = newNick:gsub("#%x%x%x%x%x%x", "")
	
	if(oldNick ~= newNick) then
		local pdata = Player.fromEl(player)
		local minDelay = Settings.min_nick_change_delay
		local ticks = getTickCount()
		
		if(pdata.lastNickChange and minDelay > 0 and (ticks - pdata.lastNickChange) < minDelay*1000) then
			privMsg(player, "Nick change spam! Wait %u seconds and try again.", minDelay - (ticks - pdata.lastNickChange)/1000)
			return false
		end
	end
	
	return true
end

function AsNotifyOfNickChange(player)
	local pdata = Player.fromEl(player)
	pdata.lastNickChange = getTickCount()
end
