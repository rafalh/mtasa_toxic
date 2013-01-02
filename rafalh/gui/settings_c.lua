--------------
-- Includes --
--------------

#include "include/internal_events.lua"

---------------------
-- Local variables --
---------------------

local g_LangButtons = {}
local g_EffectCheckBoxes = {}
local g_NickEdit, g_SuicideKeyEdit, g_StatsPanelKeyEdit, g_UserPanelKeyEdit
local g_CarHideCb, g_WinnerAnimCb
local g_NickColorWnd = nil
local g_Tab = nil

local SettingsPanel = {
	name = "Settings",
	img = "img/userpanel/options.png",
	height = 480,
}

--------------------------------
-- Local function definitions --
--------------------------------

local function onSaveClick ()
	local new_lang = false
	for lang, radio_btn in pairs ( g_LangButtons ) do
		if ( guiRadioButtonGetSelected ( radio_btn ) ) then
			new_lang = lang -- change lang at the end
			triggerServerInternalEvent ( $(EV_SET_LANG_REQUEST), g_Me, lang )
			break
		end
	end
	
	triggerServerInternalEvent ( $(EV_SET_NAME_REQUEST), g_Me, guiGetText ( g_NickEdit ) )
	
	local race_res = getResourceFromName ( "race" )
	local suicide_key = guiGetText ( g_SuicideKeyEdit )
	if ( race_res and suicide_key ~= g_ClientSettings.suicide_key and bindKey ( suicide_key, "down", suicide ) ) then
		unbindKey ( g_ClientSettings.suicide_key, "down", suicide )
		g_ClientSettings.suicide_key = suicide_key
	else
		guiSetText ( g_SuicideKeyEdit, g_ClientSettings.suicide_key )
	end
	
	local stats_panel_key = guiGetText ( g_StatsPanelKeyEdit )
	if ( stats_panel_key ~= g_ClientSettings.stats_panel_key and bindKey ( stats_panel_key, "up", openStatsPanel ) ) then
		unbindKey ( g_ClientSettings.stats_panel_key, "up", openStatsPanel )
		g_ClientSettings.stats_panel_key = stats_panel_key
	else
		guiSetText ( g_StatsPanelKeyEdit, g_ClientSettings.stats_panel_key )
	end
	
	local user_panel_key = guiGetText ( g_UserPanelKeyEdit )
	if ( user_panel_key ~= g_ClientSettings.user_panel_key and bindKey ( user_panel_key, "up", UpToggle ) ) then
		unbindKey ( g_ClientSettings.user_panel_key, "up", UpToggle )
		g_ClientSettings.user_panel_key = user_panel_key
	else
		guiSetText ( g_UserPanelKeyEdit, g_ClientSettings.user_panel_key )
	end
	
	g_ClientSettings.carHide = guiCheckBoxGetSelected(g_CarHideCb)
	ChSetEnabled(g_ClientSettings.carHide)
	
	g_ClientSettings.winAnim = guiCheckBoxGetSelected(g_WinnerAnimCb)
	
	for res, cb in pairs ( g_EffectCheckBoxes ) do
		local enabled = guiCheckBoxGetSelected ( cb )
		if ( g_Effects[res] ) then
			local res_name = getResourceName ( res )
			g_ClientSettings.effects[res_name] = enabled
			call ( res, "setEffectEnabled", enabled )
		end
	end
	
	saveSettings ()
	
	--setLang ( new_lang )
end

local function createGui ( tab )
	local w, h = guiGetSize ( tab, false )
	
	guiCreateLabel ( 10, 10, 100, 15, "Language:", false, tab  )
	
	local langs = { en = { "English", "img/en.png" } }
	local node = xmlLoadFile ( "conf/languages.xml" )
	local country_i = 0
	if ( node ) then
		local subnode = xmlNodeGetChildren ( node, 0 )
		while ( subnode ) do
			local lang = xmlNodeGetValue ( subnode )
			langs[lang] = { xmlNodeGetAttribute ( subnode, "name" ) or lang, xmlNodeGetAttribute ( subnode, "img" ) }
			
			country_i = country_i + 1
			subnode = xmlNodeGetChildren ( node, country_i )
		end
		xmlUnloadFile ( node )
	end
	
	local flag_w = ( w - 10 ) / country_i
	local i = 0
	for lang, data in pairs ( langs ) do
		g_LangButtons[lang] = guiCreateRadioButton ( 10 + i*flag_w, 30, flag_w, 15, data[1], false, tab )
		local img = guiCreateStaticImage ( 10 + i*flag_w, 46, flag_w - 10, flag_w * 2 / 3, data[2], false, tab )
		addEventHandler ( "onClientGUIClick", img, function ()
			guiRadioButtonSetSelected ( g_LangButtons[lang], true )
		end, false )
		i = i + 1
	end
	
	if ( g_LangButtons[g_Settings.lang] ) then -- select current language
		guiRadioButtonSetSelected ( g_LangButtons[g_Settings.lang], true )
	end
	
	local y = 55 + flag_w * 2 / 3
	
	guiCreateLabel ( 10, y, 160, 20, "Nick:", false, tab )
	g_NickEdit = guiCreateEdit ( 180, y, w - 180 - 60 - 10, 20, getPlayerName ( g_Me ), false, tab )
	guiSetProperty ( g_NickEdit, "MaxTextLength", "22" )
	local btn = guiCreateButton ( w - 60, y, 50, 25, "Color", false, tab )
	addEventHandler ( "onClientGUIClick", btn, function ()
		if ( g_NickColorWnd ) then
			guiBringToFront ( g_NickColorWnd )
		else
			local r, g, b = getColorFromString ( guiGetText ( g_NickEdit ):sub ( 1, 7 ) )
			g_NickColorWnd = call ( getResourceFromName ( "rafalh_shared" ), "createColorDlg", "onRafalhColorDlg", r, g, b )
			addEventHandler ( "onRafalhColorDlg", g_NickColorWnd, function ( r, g, b )
				if ( r ) then
					guiSetText ( g_NickEdit, ( "#%02x%02x%02x" ):format ( r, g, b )..guiGetText ( g_NickEdit ):gsub ( "^#%x%x%x%x%x%x", "" ) )
				end
				g_NickColorWnd = nil
			end, false )
		end
	end, false )
	
	guiCreateLabel ( 10, y + 25, 170, 20, "Suicide key:", false, tab )
	g_SuicideKeyEdit = guiCreateEdit ( 180, y+25, 40, 20, g_ClientSettings.suicide_key, false, tab )
	
	guiCreateLabel ( 10, y + 45, 170, 20, "Statistics Panel key:", false, tab )
	g_StatsPanelKeyEdit = guiCreateEdit ( 180, y+45, 40, 20, g_ClientSettings.stats_panel_key, false, tab )
	
	guiCreateLabel ( 10, y + 65, 170, 20, "User Panel key:", false, tab )
	g_UserPanelKeyEdit = guiCreateEdit ( 180, y + 65, 40, 20, g_ClientSettings.user_panel_key, false, tab )
	
	g_CarHideCb = guiCreateCheckBox ( 10, y + 85, 300, 20, "Hide other cars when GM is enabled", g_ClientSettings.carHide, false, tab )
	
	g_WinnerAnimCb = guiCreateCheckBox(10, y + 105, 300, 20, "Show stars animation above winner car", g_ClientSettings.winAnim, false, tab)
	
	y = y + 125
	guiCreateLabel ( 10, y, 160, 20, "Effects", false, tab )
	local effects_h = math.min(h - y - 60, g_EffectsCount * 20)
	local effects_pane = guiCreateScrollPane ( 10, y + 20, w - 20, effects_h, false, tab )
	local effect_y = 5
	for res, name in pairs ( g_Effects ) do
		local enabled = call ( res, "isEffectEnabled" )
		if ( type ( name ) == "table" ) then
			name = name[g_Settings.lang] or name[1]
		end
		if ( name ) then
			local cb = guiCreateCheckBox ( 10, effect_y, 300, 20, name, enabled, false, effects_pane )
			g_EffectCheckBoxes[res] = cb
			effect_y = effect_y + 20
		end
	end
	
	y = y + 20 + effects_h
	local btn = guiCreateButton ( ( w - 80 ) / 2, y + 10, 80, 25, "Save", false, tab )
	addEventHandler ( "onClientGUIClick", btn, onSaveClick, false )
end

function invalidateSettingsGui ()
	--outputDebugString("invalidateSettingsGui", 3)
	if ( not g_Tab ) then return end
	
	g_EffectCheckBoxes = {}
	for i, el in ipairs ( getElementChildren ( g_Tab ) ) do
		destroyElement ( el )
	end
	
	if ( guiGetVisible ( g_Tab ) ) then
		createGui ( g_Tab )
	else
		g_Tab = false
	end
end

function SettingsPanel.onShow ( tab )
	if ( not g_Tab ) then
		g_Tab = tab
		createGui ( g_Tab )
	end
end

function SettingsPanel.onHide ( tab )
	if ( g_NickColorWnd ) then
		destroyElement ( g_NickColorWnd )
		g_NickColorWnd = nil
	end
end

----------------------
-- Global variables --
----------------------

UpRegister ( SettingsPanel )
