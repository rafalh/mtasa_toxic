local function CmdAlias(message, arg)
	local player = (#arg >= 2 and findPlayer(message:sub (arg[1]:len () + 2)))
	if (player) then
		local alias = (arg[1] == "alias" or arg[1] == "/alias" or arg[1] == "alias")
		if(alias) then
			scriptMsg("Aliases for %s:", getPlayerName (player))
		else
			privMsg(source,  "Aliases for %s:", getPlayerName (player))
		end
		
		local pdata = Player.fromEl(player)
		local aliasList = AlGetPlayerAliases(pdata)
		local aliasListStr = table.concat(aliasList, ", ")
		if(alias) then
			scriptMsg("%s", aliasListStr..".")
		else
			privMsg(source, "%s", aliasListStr..".")
		end
	else privMsg(source, "Usage: %s", arg[1].." <player>") end
end

CmdRegister("alias", CmdAlias, "resource."..g_ResName..".alias", "Displays all player nicknames")
CmdRegisterAlias("pma", "alias")
