function AsProcessMsg(player)
	local pdata = g_Players[player]
	local spam_interval = SmGetUInt("spam_interval", 500)
	local ticks = getTickCount()
	
	if(pdata.last_msg and (ticks - pdata.last_msg) < spam_interval) then
		if(pdata.antispam_warning and (ticks - pdata.antispam_warning) < spam_interval) then
			if(SmGetBool("spammer_kick")) then
				scriptMsg("%s has been kicked for spamming.", getPlayerName(player))
				kickPlayer(player, "Spam")
			else
				customMsg(255, 0, 0, "%s has been muted for spamming.", getPlayerName(player))
				mutePlayer(player, 60, false, true)
			end
			return true
		else
			if(SmGetBool("spammer_kick")) then
				privMsg(player, "Do not spam %s! Otherwise you will get kicked.", getPlayerName(player))
			else
				privMsg(player, "Do not spam %s! Otherwise you will get muted.", getPlayerName(player))
			end
			pdata.antispam_warning = ticks
		end
	end
	pdata.last_msg = ticks
	return false
end

function AsCanPlayerChangeNick(player, oldNick, newNick)
	oldNick = oldNick:gsub("#%x%x%x%x%x%x", "")
	newNick = newNick:gsub("#%x%x%x%x%x%x", "")
	
	if(oldNick ~= newNick) then
		local pdata = g_Players[player]
		local min_delay = SmGetUInt("min_nick_change_delay", 0)
		local ticks = getTickCount()
		
		if(pdata.last_nick_change and min_delay > 0 and (ticks - pdata.last_nick_change) < min_delay*1000) then
			privMsg(player, "Nick change spam! Wait %u seconds and try again.", min_delay - (ticks - pdata.last_nick_change)/1000)
			return false
		end
		
		pdata.last_nick_change = ticks
	end
	
	return true
end

--addEventHandler("onPlayerChangeNick", g_Root, AsOnPlayerChangeNick)
