addEvent("main.onSetLocaleReq", true)

local function LngOnSetLangRequest(lang)
	if(not lang or not LocaleList.exists(lang)) then return end
	
	local pdata = g_Players[client]
	pdata.lang = lang
	DbQuery("UPDATE rafalh_players SET lang=? WHERE player=?", lang, pdata.id)
	setElementData(client, "lang", lang)
	triggerClientEvent(client, "onClientLangChange", g_Root, lang)
	triggerEvent("onPlayerLangChange", client, lang)
end

addEventHandler("main.onSetLocaleReq", g_ResRoot, LngOnSetLangRequest)
