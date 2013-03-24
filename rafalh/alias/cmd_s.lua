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
		local aliases = ""
		if(pdata.id) then
			local rows = DbQuery("SELECT name FROM rafalh_names WHERE player=?", pdata.id)
			for i, data in ipairs(rows) do
				if(aliases ~= "") then
					aliases = aliases..", "
				end
				aliases = aliases..data.name
			end
		else
			aliases = getPlayerName(player)
		end
		if(alias) then
			scriptMsg("%s", aliases..".")
		else
			privMsg(source, "%s", aliases..".")
		end
	else privMsg(source, "Usage: %s", arg[1].." <player>") end
end

CmdRegister("alias", CmdAlias, "resource.rafalh.alias", "Displays all player nicknames")
CmdRegisterAlias("pma", "alias")
