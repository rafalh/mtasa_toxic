
#include "include/internal_events.lua"

g_Locales = {}

function LngGetPlayerLang(player)
	if(g_Players[player] and g_Players[player].lang and g_Locales[g_Players[player].lang]) then
		return g_Players[player].lang
	end
	return "en"
end

function LngInit()
	local node, i = xmlLoadFile("conf/languages.xml"), 0
	if(not node) then return end
	
	while(true) do
		local subnode = xmlFindChild(node, "lang", i)
		if(not subnode) then break end
		
		local code = xmlNodeGetValue(subnode)
		g_Locales[code] = true
		i = i + 1
	end
	
	xmlUnloadFile(node)
end

local function LngOnSetLangRequest(lang)
	if(not lang or not g_Locales[lang]) then return end
	
	local pdata = g_Players[client]
	pdata.lang = lang
	DbQuery("UPDATE rafalh_players SET lang=? WHERE player=?", lang, pdata.id)
	setElementData(client, "lang", lang, false)
	triggerClientEvent(client, "onClientLangChange", g_Root, lang)
	triggerEvent("onPlayerLangChange", client, lang)
end

addInternalEventHandler($(EV_SET_LANG_REQUEST), LngOnSetLangRequest)
