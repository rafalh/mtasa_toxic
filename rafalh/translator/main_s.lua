local g_Queries = {}
local g_BingAppId = "3F57A5F6F90AA286DB6B0557CC897B1C4C88206E"
local g_Langs = false

addEvent("onTranslateReq", true)
addEvent("onTranslateLangListReq", true)
addEvent("onClientTranslate", true)
addEvent("onClientTranslateLangList", true)
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

function translate (text, from, to, callback, ...)
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

addInitFunc(function()
	addEventHandler("onTranslateReq", g_Root, onTranslateReq)
	addEventHandler("onTranslateLangListReq", g_Root, onTranslateLangListReq)
end)
