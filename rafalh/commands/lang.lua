local function CmdSetLang (message, arg)
	if (arg[2] and g_Locales[arg[2]]) then
		g_Players[source].lang = arg[2]
		DbQuery ("UPDATE rafalh_players SET lang=? WHERE player=?", arg[2], g_Players[source].id)
		setElementData (source, "lang", arg[2], false)
		triggerClientEvent (source, "onClientLangChange", g_Root, lang)
		triggerEvent ("onPlayerLangChange", source, lang)
		privMsg (source, "Language successfully set to %s!")
	else
		local buf = ""
		for lang, v in pairs (g_Locales) do
			buf = buf.."/"..lang
		end
		privMsg (source, "Usage: %s", arg[1].." <"..(buf:sub (2))..">")
	end
end

CmdRegister ("setlang", CmdSetLang, false, "Sets your language")
