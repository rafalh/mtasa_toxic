--------------
-- Includes --
--------------

#include "include/internal_events.lua"

---------------------
-- Local variables --
---------------------

local g_Tab = nil
local g_Input, g_Output
local g_FromLang, g_ToLang
local g_TranslateBtn, g_SayBtn
local g_ChatMsgCb
local g_ChatMsg = {}
local g_MsgCount = 0
local g_Langs = { "en" }
local g_LangNames = { en = "English" }
local g_Timer = false

addEvent ( "onTranslateReq", true )
addEvent ( "onTranslateLangListReq", true )
addEvent ( "onClientTranslate", true )
addEvent ( "onClientTranslateLangList", true )

local TranslatorPanel = {
	name = "Translator",
	img = "img/userpanel/translator.png",
	tooltip = "Traslate any sentence into your own language",
	height = 370,
}

--------------------------------
-- Local function definitions --
--------------------------------

local function LoadLanguages ()
	g_LangNames = {}
	local node, i = xmlLoadFile ( "conf/iso_langs.xml" ), 0
	if ( node ) then
		while ( true ) do
			local subnode = xmlFindChild ( node, "lang", i )
			if ( not subnode ) then break end
			i = i + 1
			
			local code = xmlNodeGetAttribute ( subnode, "code" )
			local name = xmlNodeGetValue ( subnode )
			assert ( code and name )
			g_LangNames[code] = name
		end
		xmlUnloadFile ( node )
	end
end

local function timerProc ()
	guiSetEnabled ( g_TranslateBtn, true )
	guiSetEnabled ( g_SayBtn, true )
	g_Timer = false
end

local function onTranslateClick ()
	local text = guiGetText ( g_Input )
	if ( not text:match ( "^%s*$" ) ) then
		local from_i = guiComboBoxGetSelected ( g_FromLang )
		local from = from_i > 0 and g_Langs[from_i] -- auto is supported
		local to_i = guiComboBoxGetSelected ( g_ToLang )
		local to = to_i > -1 and g_Langs[to_i + 1]
		assert ( to )
		local say = ( source == g_SayBtn )
		
		guiSetEnabled ( g_TranslateBtn, false )
		guiSetEnabled ( g_SayBtn, false )
		guiSetText ( g_Output, MuiGetMsg ( "Please wait..." ) )
		g_Timer = setTimer ( timerProc, 1000, 1 )
		
		triggerServerEvent ( "onTranslateReq", g_Me, text, from, to, say )
	else
		guiSetText ( g_Output, text )
	end
end

local function onSwitchLangsClick ()
	local from_i = guiComboBoxGetSelected ( g_FromLang ) -- auto is supported
	local to_i = guiComboBoxGetSelected ( g_ToLang )
	if ( from_i > 0 and to_i >= 0 ) then
		guiComboBoxSetSelected ( g_FromLang, to_i + 1 )
		guiComboBoxSetSelected ( g_ToLang, from_i - 1 )
	end
end

local function loadChatMsg ()
	local sel = guiComboBoxGetSelected ( g_ChatMsgCb )
	if ( sel > -1 ) then
		local text = guiComboBoxGetItemText ( g_ChatMsgCb, sel )
		guiSetText ( g_Input, text )
	end
	guiComboBoxSetSelected ( g_ChatMsgCb, -1 )
end

local function updateLangComboBoxes ()
	-- From
	guiComboBoxClear ( g_FromLang )
	guiComboBoxAddItem ( g_FromLang, "Auto-detect" )
	for i, lang in ipairs ( g_Langs ) do
		guiComboBoxAddItem ( g_FromLang, g_LangNames[lang] or lang )
	end
	guiComboBoxSetSelected ( g_FromLang, 0 )
	
	-- To
	guiComboBoxClear ( g_ToLang )
	local default = 0
	for i, lang in ipairs ( g_Langs ) do
		local id = guiComboBoxAddItem ( g_ToLang, g_LangNames[lang] or lang )
		if ( lang == "en" ) then
			default = id
		end
	end
	guiComboBoxSetSelected ( g_ToLang, default )
end

local function createGui(panel)
	local w, h = guiGetSize(panel, false)
	
	LoadLanguages ()
	triggerServerEvent("onTranslateLangListReq", g_Root)
	
	guiCreateLabel(10, 10, 50, 15, "From:", false, panel)
	g_FromLang = guiCreateComboBox ( 50, 10, 130, 300, "", false, panel )
	
	local btn = guiCreateButton ( 200, 10, 40, 25, "<->", false, panel )
	addEventHandler ( "onClientGUIClick", btn, onSwitchLangsClick, false )
	
	guiCreateLabel ( 260, 10, 50, 15, "To:", false, panel )
	g_ToLang = guiCreateComboBox ( 310, 10, 130, 300, "", false, panel )
	
	updateLangComboBoxes ()
	
	g_TranslateBtn = guiCreateButton ( 10, 40, 80, 25, "Translate", false, panel )
	addEventHandler ( "onClientGUIClick", g_TranslateBtn, onTranslateClick, false )
	
	g_SayBtn = guiCreateButton ( 100, 40, 120, 25, "Say translated", false, panel )
	addEventHandler ( "onClientGUIClick", g_SayBtn, onTranslateClick, false )
	
	g_ChatMsgCb = guiCreateComboBox ( 230, 40, 210, 210, MuiGetMsg ( "Load chat message" ), false, panel )
	addEventHandler ( "onClientGUIComboBoxAccepted", g_ChatMsgCb, loadChatMsg, false )
	for i, msg in ipairs ( g_ChatMsg ) do
		guiComboBoxAddItem ( g_ChatMsgCb, msg )
	end
	g_ChatMsg = false
	
	guiCreateLabel ( 10, 70, 50, 15, "Input:", false, panel )
	g_Input = guiCreateMemo ( 10, 90, w - 20, 90, "", false, panel )
	
	guiCreateLabel(10, 190, 50, 15, "Output:", false, panel)
	g_Output = guiCreateMemo(10, 210, w - 20, 90, "", false, panel)
	guiMemoSetReadOnly(g_Output, true)
	
	local label = guiCreateLabel(10, 310, w - 20, 15, MuiGetMsg("Translation by %s"):format("Microsoft Bing (tm)"), false, panel)
	guiSetFont(label, "default-small")
	guiLabelSetHorizontalAlign(label, "right")
	
	if(UpNeedsBackBtn()) then
		local btn = guiCreateButton(w - 80, h - 35, 70, 25, "Back", false, panel)
		addEventHandler("onClientGUIClick", btn, UpBack, false)
	end
end

function TranslatorPanel.onShow ( panel )
	if(not g_Tab) then
		g_Tab = panel
		createGui(g_Tab)
	end
end

local function onTranslate ( text )
	guiSetText ( g_Output, text )
	if ( g_Timer ) then
		killTimer ( g_Timer )
		g_Timer = false
	end
	guiSetEnabled ( g_TranslateBtn, true )
	guiSetEnabled ( g_SayBtn, true )
end

local function onTranslateLangList ( langs )
	g_Langs = langs
	updateLangComboBoxes ()
end

local function onChatMessage ( text )
	local LIMIT = 12
	
	text = text:gsub ( "#%x%x%x%x%x%x", "" )
	
	if ( g_ChatMsgCb ) then
		if ( g_MsgCount >= LIMIT ) then
			guiComboBoxRemoveItem ( g_ChatMsgCb, 0 )
		end
		guiComboBoxAddItem ( g_ChatMsgCb, text )
	else
		if ( g_MsgCount >= LIMIT ) then
			table.remove ( g_ChatMsg, 1 )
		end
		table.insert ( g_ChatMsg, text )
	end
	
	if ( g_MsgCount < LIMIT ) then
		g_MsgCount = g_MsgCount + 1
	end
	
	assert ( not g_ChatMsg or g_MsgCount == #g_ChatMsg )
end

----------------------
-- Global variables --
----------------------

UpRegister ( TranslatorPanel )
addEventHandler ( "onClientTranslate", g_Root, onTranslate )
addEventHandler ( "onClientTranslateLangList", g_Root, onTranslateLangList )
addEventHandler ( "onClientChatMessage", g_Root, onChatMessage )
