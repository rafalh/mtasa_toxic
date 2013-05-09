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

local function CmdTranslate(message, arg)
	local lang = arg[2] or ""
	local text = message:sub(arg[1]:len () + lang:len () + 3)
	
	if(text ~= "") then
		if (validateLangCode (lang)) then
			local state = table.copy(g_ScriptMsgState, true)
			translate (text, false, lang, function (text, state)
				local old_state = g_ScriptMsgState
				g_ScriptMsgState = state
				scriptMsg("Translation: %s", text)
				g_ScriptMsgState = old_state
			end, state)
		end
	else
		privMsg(source, "Usage: %s", "translate <langcode> <text>")
	end
end

CmdRegister("translate", CmdTranslate, false, "Translates text to any language")
CmdRegisterAlias("t", "translate")

local function CmdTranslateSay(message, arg)
	local lang = arg[2] or ""
	local text = message:sub (arg[1]:len () + lang:len() + 3)
	
	if(text ~= "") then
		if(validateLangCode (lang)) then
			translate (text, false, lang, function (text, player)
				if(not isElement (player)) then return end
				
				sayAsPlayer(text, player)
			end, source)
		end
	else
		privMsg(source, "Usage: %s", "tsay <langcode> <text>")
	end
end

CmdRegister("tsay", CmdTranslateSay, false, "Translate message and says it")
