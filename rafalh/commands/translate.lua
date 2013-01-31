local g_Queries = {}
local g_BingAppId = "3F57A5F6F90AA286DB6B0557CC897B1C4C88206E"
local g_Langs = false

addEvent("onHttpResult")

local function onTranslateResult (new_text, old_text, lang_to)
	if (new_text == "ERROR" or not new_text) then
		outputDebugString (tostring (old_text), 1)
	else
		-- remove UTF-8 BOM
		local b1, b2, b3 = new_text:byte (1, 3)
		if (b1 == 0xEF and b2 == 0xBB and b3 == 0xBF) then
			new_text = new_text:sub (4)
		end
		
		if (g_Queries[old_text]) then
			for i, data in ipairs (g_Queries[old_text]) do
				-- Note: unpack must be last arg
				data.func (new_text, unpack (data.args))
			end
			
			g_Queries[old_text] = nil
		end
	end
end

local function validateLangCode (lang)
	lang = lang:upper ()
	
	if (g_IsoLangs[lang]) then
		return true
	end
	
	local best_code, best_lang = false, false
	for code, name in pairs (g_IsoLangs) do
		if (name:upper ():find (lang, 1, true)) then
			best_code = code
			best_lang = name
			break
		end
	end
	
	if (best_code) then
		privMsg (source, "Invalid language code. Maybe you wanted to use %s (%s).", best_code, best_lang)
	else
		privMsg (source, "Invalid language code. It should be two letters long.")
	end
	return false
end

local function translate (text, from, to, callback, ...)
	if (not g_Queries[text]) then
		g_Queries[text] = {}
	end
	table.insert (g_Queries[text], { func = callback, args = { ... } })
	
	local text_enc = exports.rafalh_shared:HttpEncodeUrl (text)
	local from_enc = exports.rafalh_shared:HttpEncodeUrl (from or "")
	local to_enc = exports.rafalh_shared:HttpEncodeUrl (to or "en")
	local url = "http://api.microsofttranslator.com/v1/Http.svc/Translate?appId="..g_BingAppId.."&text="..text_enc.."&from="..from_enc.."&to="..to_enc
	--outputDebugString (url, 2)
	local req_el = exports.rafalh_shared:HttpSendRequest (url, false, "GET", false, text, to, from)
	if (not req_el) then return false end
	addEventHandler ("onHttpResult", req_el, onTranslateResult)
	
	--[[if (not callRemote ("http://toxic.no-ip.eu/scripts/translate.php", onTranslateResult, text, to, from)) then
		outputDebugString ("callRemote failed.", 1)
		return false
	end]]
	
	return true
end

local function CmdTranslate(message, arg)
	local lang = arg[2] or ""
	local text = message:sub(arg[1]:len () + lang:len () + 3)
	
	if (text ~= "") then
		if (validateLangCode (lang)) then
			local state = table.copy(g_ScriptMsgState, true)
			translate (text, false, lang, function (text, state)
				local old_state = g_ScriptMsgState
				g_ScriptMsgState = state
				scriptMsg ("Translation: %s", text)
				g_ScriptMsgState = old_state
			end, state)
		end
	else
		privMsg (source, "Usage: %s", "translate <langcode> <text>")
	end
end

CmdRegister ("translate", CmdTranslate, false, "Translates text to any language")
CmdRegisterAlias ("t", "translate")

local function sayAsPlayer (text, player)
	if (isPlayerMuted (player)) then
		outputChatBox ("translate: You are muted!", player, 255, 128, 0)
		return
	end
	
	local r, g, b
	if (getElementType (player) == "player") then
		r, g, b = getPlayerNametagColor (player)
	else
		r, g, b = 255, 128, 255 -- console
	end
	local msg = getPlayerName (player)..": #FFFF00"..text
	outputChatBox (msg, g_Root, r, g, b, true)
end

local function CmdTranslateSay (message, arg)
	local lang = arg[2] or ""
	local text = message:sub (arg[1]:len () + lang:len() + 3)
	
	if (text ~= "") then
		if (validateLangCode (lang)) then
			translate (text, false, lang, function (text, player)
				if (not isElement (player)) then return end
				
				sayAsPlayer (text, player)
			end, source)
		end
	else
		privMsg (source, "Usage: %s", "tsay <langcode> <text>")
	end
end

CmdRegister ("tsay", CmdTranslateSay, false, "Translate message and says it")

-- FIXME
addEvent("onTranslateReq", true)
addEvent("onTranslateLangListReq", true)
addEvent("onClientTranslate", true)
addEvent("onClientTranslateLangList", true)

local function onTranslateReq (text, from, to, say)
	translate (text, from, to, function (text, player)
		if (not isElement (player)) then return end
		
		if (say) then
			sayAsPlayer (text, player)
		end
		triggerClientEvent (player, "onClientTranslate", g_Root, text)
	end, client)
	
	AchvActivate(client, "Try built-in translator")
end

local function onTranslateLangList (data, player)
	if (not data) then
		outputDebugString ("Failed to get translator languages", 2)
		return
	end
	
	g_Langs = split (data, "\r\n")
	triggerClientEvent (player, "onClientTranslateLangList", g_Root, g_Langs)
end

local function onTranslateLangListReq ()
	if (not g_Langs) then
		local url = "http://api.microsofttranslator.com/v1/Http.svc/GetLanguages?appId="..g_BingAppId
		local sharedRes = getResourceFromName("rafalh_shared")
		local req_el = sharedRes and call(sharedRes, "HttpSendRequest", url, false, "GET", false, client)
		if (not req_el) then return false end
		addEventHandler ("onHttpResult", req_el, onTranslateLangList)
	else
		triggerClientEvent (client, "onClientTranslateLangList", g_Root, g_Langs)
	end
end

addEventHandler("onTranslateReq", g_Root, onTranslateReq)
addEventHandler("onTranslateLangListReq", g_Root, onTranslateLangListReq)
