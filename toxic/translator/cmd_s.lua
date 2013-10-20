local function validateLangCode(lang)
	lang = lang:upper ()
	
	if(g_IsoLangs[lang]) then
		return true
	end
	
	local best_code, best_lang = false, false
	for code, name in pairs(g_IsoLangs) do
		if(name:upper ():find (lang, 1, true)) then
			best_code = code
			best_lang = name
			break
		end
	end
	
	if(best_code) then
		privMsg (source, "Invalid language code. Maybe you wanted to use %s (%s).", best_code, best_lang)
	else
		privMsg (source, "Invalid language code. It should be two letters long.")
	end
	return false
end

CmdMgr.register{
	name = 'translate',
	desc = "Translates text to any language",
	aliases = {'t'},
	args = {
		{'langCode', type = 'string'},
		{'text', type = 'string'},
	},
	func = function(ctx, langCode, text)
		if(validateLangCode(langCode)) then
			local state = table.copy(g_ScriptMsgState, true)
			translate(text, false, langCode, function (text, state)
				local oldState = g_ScriptMsgState
				g_ScriptMsgState = state
				scriptMsg("Translation: %s", text)
				g_ScriptMsgState = oldState
			end, state)
		else
			privMsg(ctx.player, "Invalid language code!")
		end
	end
}

CmdMgr.register{
	name = 'tsay',
	desc = "Translates message and says it",
	args = {
		{'langCode', type = 'string'},
		{'text', type = 'string'},
	},
	func = function(ctx, langCode, text)
		if(validateLangCode(langCode)) then
			translate(text, false, langCode, function(text, player)
				if(not isElement(player)) then return end
				sayAsPlayer(text, player)
			end, ctx.player.el)
		else
			privMsg(ctx.player, "Invalid language code!")
		end
	end
}
