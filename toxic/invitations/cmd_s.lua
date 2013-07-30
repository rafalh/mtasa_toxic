local function CmdInvitedBy(message, arg)
	local sourcePlayer = Player.fromEl(source)
	local targetEl = #arg >= 2 and findPlayer(message:sub(arg[1]:len () + 2))
	local targetPlayer = targetEl and Player.fromEl(targetEl)
	
	if(targetPlayer and sourcePlayer.id and targetPlayer.id) then
		if(sourcePlayer:getPlayTime() > 3600) then
			privMsg(source, "Failed. You can use this command only before your playtime reaches 1 hour.")
		elseif(targetPlayer.accountData:get('invitedby') == sourcePlayer.id) then
			privMsg(source, "Failed. He set you as player who invited him.")
		elseif(sourcePlayer.accountData:get('first_visit') > targetPlayer.accountData:get('first_visit')) then
			privMsg(source, "Failed. Your first visit was earlier than his.")
		else
			targetPlayer.accountData:set('invitedby', sourcePlayer.id)
			privMsg(source, "Successed! %s will get an award when your playtime will reach 10 hours.", targetPlayer:getName())
		end
	else privMsg(source, "Usage: %s", arg[1]..' <player>') end
end

CmdRegister('invitedby', CmdInvitedBy, false, "Sets player who invited you so he can win an avard")
