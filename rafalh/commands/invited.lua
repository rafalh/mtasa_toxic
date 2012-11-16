local function CmdInvitedBy (message, arg)
	local player = #arg >= 2 and findPlayer (message:sub (arg[1]:len () + 2))
	
	if (player) then
		local data = (DbQuery ("SELECT time_here, first_visit FROM rafalh_players WHERE player=? LIMIT 1", g_Players[source].id))[1]
		local data2 = (DbQuery ("SELECT invitedby, first_visit FROM rafalh_players WHERE player=? LIMIT 1", g_Players[player].id))[1]
		local playtime = getRealTime ().timestamp - g_Players[source].join_time + data.time_here
		
		if (playtime > 3600) then
			privMsg (source, "Failed. You can use this command only before your playtime reaches 1 hour.")
		elseif (data2.invited == g_Players[source].id) then
			privMsg (source, "Failed. He set you as player who invited him.")
		elseif (data.first_visit > data2.first_visit) then
			privMsg (source, "Failed. Your first visit was earlier than his.")
		else
			DbQuery ("UPDATE rafalh_players SET invitedby=? WHERE player=?", g_Players[player].id, g_Players[source].id)
			privMsg (source, "Successed! "..getPlayerName (player).." will get an award when your playtime will reach 10 hours.")
		end
	else privMsg (source, "Usage: %s", arg[1].." <player>") end
end

CmdRegister ("invitedby", CmdInvitedBy, false, "Sets player who invited you so he can win an avard")
