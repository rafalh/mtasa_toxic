CmdMgr.register{
	name = 'alias',
	aliases = {'pma'},
	cat = 'Admin',
	desc = "Displays all player nicknames",
	accessRight = AccessRight('alias'),
	args = {
		{'player', type = 'player'},
	},
	func = function(ctx, player)
		local alias = (ctx.cmdName == 'alias')
		if(alias) then
			scriptMsg("Aliases for %s:", player:getName())
		else
			privMsg(ctx.player, "Aliases for %s:", player:getName())
		end
		
		local aliasList = AlGetPlayerAliases(player)
		local aliasListStr = table.concat(aliasList, ', ')
		if(alias) then
			scriptMsg('%s', aliasListStr..'.')
		else
			privMsg(ctx.player, '%s', aliasListStr..'.')
		end
	end
}
