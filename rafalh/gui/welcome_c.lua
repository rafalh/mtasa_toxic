--------------
-- Includes --
--------------

#include "include/internal_events.lua"

---------------------
-- Local variables --
---------------------

local g_Wnd, g_LangButtons

---------------------------------
-- Local function declarations --
---------------------------------

local onClientInit
local onOkClick

--------------------------------
-- Local function definitions --
--------------------------------

onClientInit = function ( accountId, welcomeWnd )
	if ( welcomeWnd ) then
		local langs = { en = { "English", "img/en.png" } }
		local langs_count = 0
		local node = xmlLoadFile ( "conf/languages.xml" )
		if ( node ) then
			local subnode = xmlNodeGetChildren ( node, 0 )
			while ( subnode ) do
				local lang = xmlNodeGetValue ( subnode )
				local name = xmlNodeGetAttribute ( subnode, "name" ) or lang
				local img = xmlNodeGetAttribute ( subnode, "img" )
				langs[lang] = { name, img }
				langs_count = langs_count + 1
				subnode = xmlNodeGetChildren ( node, langs_count )
			end
			xmlUnloadFile ( node )
		end
		
		local w, h = math.max(320, langs_count*75 + 10), 180
		local x = (g_ScreenSize[1] - w)/2
		local y = (g_ScreenSize[2] - h)/2
		g_Wnd = guiCreateWindow ( x, y, w, h, "Welcome to ToXiC server!", false )
		
		guiCreateLabel ( 10, 20, w - 20, 15, "Choose your language:", false, g_Wnd )
		
		g_LangButtons = {}
		local i = 0
		for lang, data in pairs ( langs ) do
			g_LangButtons[lang] = guiCreateRadioButton ( 10 + i*75, 40, 75, 15, data[1], false, g_Wnd )
			local img = guiCreateStaticImage ( 10 + i*75, 56, 65, 42, data[2], false, g_Wnd )
			addEventHandler ( "onClientGUIClick", img, function ()
				guiRadioButtonSetSelected ( g_LangButtons[lang], true )
			end, false )
			i = i + 1
		end
		
		guiCreateLabel ( 10, 110, w - 20, 15, "Language can be changed in User Panel (F2) -> Settings", false, g_Wnd )
		
		local btn = guiCreateButton ( (w - 40)/2, h - 40, 40, 25, "OK", false, g_Wnd )
		addEventHandler ( "onClientGUIClick", btn, onOkClick, false )
		
		guiSetInputEnabled ( true )
	end
end

onOkClick = function ()
	for lang, radio_btn in pairs ( g_LangButtons ) do
		if ( guiRadioButtonGetSelected ( radio_btn ) ) then
			--setLang ( lang )
			triggerServerInternalEvent ( $(EV_SET_LANG_REQUEST), g_Me, lang )
			break
		end
	end
	
	destroyElement ( g_Wnd )
	guiSetInputEnabled ( false )
end

------------
-- Events --
------------

addInternalEventHandler ( $(EV_CLIENT_INIT), onClientInit )
