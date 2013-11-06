local g_Strings = {}
local g_Patterns = {}
local g_Mui = {}
local g_Lang

addEvent ( "onClientLangChange", true )
addEvent ( "onClientLangChanged" )

local function MuiLoadInternal ( path )
	local strings = {}
	local patterns = {}
	local node = xmlLoadFile ( path )
	if ( node ) then
		local i = 0
		while ( true ) do
			local subnode = xmlFindChild ( node, "msg", i )
			if ( not subnode ) then break end
			i = i + 1
			
			local id = xmlNodeGetAttribute ( subnode, "id" )
			local value = xmlNodeGetValue ( subnode )
			if ( id and value ) then
				strings[id] = value
			end
			
			local pattern = xmlNodeGetAttribute ( subnode, "pattern" )
			if ( pattern and value ) then
				patterns[pattern] = value
			end
		end
		xmlUnloadFile ( node )
	end
	return { strings, patterns }
end

local function MuiLoad ( path )
	local lang = MuiLoadInternal ( path )
	g_Strings = lang[1]
	g_Patterns = lang[2]
end

function MuiGetMsg ( text )
	if ( g_Strings[text] ) then
		return g_Strings[text]
	end
	for pattern, repl in pairs ( g_Patterns ) do
		text = string.gsub ( text, pattern, repl )
	end
	return text
end

local _guiSetText = guiSetText
function guiSetText ( guiElement, text )
	if ( g_Mui[guiElement] ) then
		g_Mui[guiElement] = text
		text = MuiGetMsg ( text )
	end
	return _guiSetText ( guiElement, text )
end

local _guiCreateWindow = guiCreateWindow
function guiCreateWindow ( x, y, width, height, titleBarText, ... )
	local wnd = _guiCreateWindow ( x, y, width, height, MuiGetMsg ( titleBarText ), ... )
	g_Mui[wnd] = titleBarText
	return wnd
end

local _guiCreateTab = guiCreateTab
function guiCreateTab ( text, parent )
	local tab = _guiCreateTab ( MuiGetMsg ( text ), parent )
	g_Mui[tab] = text
	return tab
end

local _guiCreateButton = guiCreateButton
function guiCreateButton ( x, y, width, height, text, ... )
	local btn = _guiCreateButton ( x, y, width, height, MuiGetMsg ( text), ... )
	g_Mui[btn] = text
	return btn
end

local _guiCreateCheckBox = guiCreateCheckBox
function guiCreateCheckBox ( x, y, width, height, text, ... )
	local checkbox = _guiCreateCheckBox ( x, y, width, height, MuiGetMsg ( text ), ... )
	g_Mui[checkbox] = text
	return checkbox
end

local _guiCreateLabel = guiCreateLabel
function guiCreateLabel ( x, y, width, height, text, ... )
	local label = _guiCreateLabel ( x, y, width, height, MuiGetMsg ( text ), ... )
	g_Mui[label] = text
	return label
end

local _guiGridListAddColumn = guiGridListAddColumn
function guiGridListAddColumn ( gridList, title, ... )
	return _guiGridListAddColumn ( gridList, MuiGetMsg ( title ), ... )
end

local _guiGridListSetItemText = guiGridListSetItemText
function guiGridListSetItemText ( gridList, rowIndex, columnIndex, text, ... )
	return _guiGridListSetItemText ( gridList, rowIndex, columnIndex, MuiGetMsg ( text ), ... )
end

local _outputChatBox = outputChatBox
function outputChatBox ( text, ... )
	return _outputChatBox ( MuiGetMsg ( text ), ... )
end

local _dxDrawText = dxDrawText
function dxDrawText ( text, ... )
	return _dxDrawText ( MuiGetMsg ( text ), ... )
end

local function MuiUpdate ()
	for el, text in pairs ( g_Mui ) do
		_guiSetText ( el, MuiGetMsg ( text ) )
	end
end

function MuiSetLang ( lang )
	assert ( lang )
	
	if ( lang ~= g_Lang ) then
		MuiLoad ( "lang/"..tostring ( lang ).."_c.xml" )
		MuiUpdate ()
		triggerEvent("onClientLangChanged", getResourceRootElement())
		g_Lang = lang
	end
end

local function MuiOnElementDestroy()
	if(source) then -- wtf?
		g_Mui[source] = nil
	end
end

addEventHandler("onClientLangChange", getResourceRootElement(), MuiSetLang)
addEventHandler("onClientElementDestroy", getResourceRootElement(), MuiOnElementDestroy)
