
#include "include/internal_events.lua"

g_Locales = {}

function LngGetPlayerLang ( player )
	if ( g_Players[player] and g_Players[player].lang and g_Locales[g_Players[player].lang] ) then
		return g_Players[player].lang
	end
	return "en"
end

function LngParseTbl ( str_tbl, lang )
	assert ( false )
end

function LngInit ()
	local node, i = xmlLoadFile ( "conf/languages.xml" ), 0
	if ( node ) then
		while ( true ) do
			local subnode = xmlFindChild ( node, "lang", i )
			if ( not subnode ) then break end
			
			local code = xmlNodeGetValue ( subnode )
			g_Locales[code] = true
			i = i + 1
		end
		xmlUnloadFile ( node )
	end
end

local function LngOnSetLangRequest ( lang )
	if ( lang and g_Locales[lang] ) then
		g_Players[client].lang = lang
		DbQuery ( "UPDATE rafalh_players SET lang=? WHERE player=?", lang, g_Players[client].id )
		setElementData ( client, "lang", lang, false )
		triggerClientEvent ( client, "onClientLangChange", g_Root, lang )
		triggerEvent ( "onPlayerLangChange", client, lang )
	end
end

addInternalEventHandler ( $(EV_SET_LANG_REQUEST), LngOnSetLangRequest )
