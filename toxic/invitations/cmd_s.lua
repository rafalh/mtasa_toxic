CmdMgr.register{
	name = 'invitedby',
	desc = "Sets player who invited you so he can win an award",
	args = {
		{'player', type = 'player'},
	},
	func = function(ctx, targetPlayer)
		if(not ctx.player.id or not targetPlayer.id) then
			privMsg(ctx.player, "Both players must be logged in.")
		elseif(ctx.player:getPlayTime() > 3600) then
			privMsg(ctx.player, "Failed. You can use this command only before your playtime reaches 1 hour.")
		elseif(targetPlayer.accountData:get('invitedby') == ctx.player.id) then
			privMsg(ctx.player, "Failed. He set you as player who invited him.")
		elseif(ctx.player.accountData:get('first_visit') > targetPlayer.accountData:get('first_visit')) then
			privMsg(ctx.player, "Failed. Your first visit was earlier than his.")
		else
			targetPlayer.accountData:set('invitedby', ctx.player.id)
			privMsg(ctx.player, "Succeeded! %s will get an award when your playtime will reach 10 hours.", targetPlayer:getName())
		end
	end
}
