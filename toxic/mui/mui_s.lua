local g_Langs = {}
local g_Strings = {}
local g_Patterns = {}
local g_TextItems = {}

addEvent('onPlayerLangChange')

function MuiLoadFile(path)
	local strings = {}
	local patterns = {}
	local node = xmlLoadFile ( path )
	if ( node ) then
		local i = 0
		while ( true ) do
			local subnode = xmlFindChild ( node, 'msg', i )
			if ( not subnode ) then break end
			i = i + 1
			
			local id = xmlNodeGetAttribute ( subnode, 'id' )
			local value = xmlNodeGetValue ( subnode )
			if ( id and value ) then
				strings[id] = value
			end
			
			local pattern = xmlNodeGetAttribute ( subnode, 'pattern' )
			if ( pattern and value ) then
				patterns[pattern] = value
			end
		end
		xmlUnloadFile ( node )
	elseif(fileExists(path)) then
		outputDebugString('Failed to load '..path, 2)
	end
	return { strings, patterns }
end

function MuiLoad(lang_id)
	if(g_Langs[lang_id]) then return end
	g_Langs[lang_id] = MuiLoadFile('lang/'..tostring(lang_id)..'.xml')
end

function MuiGetPlayerLocale(player)
	return getElementData(player, 'lang')
end

function MuiGetMsg ( text, player )
	assert ( player and text )
	local lang = getElementData ( player, 'lang' )
	if ( lang ) then
		MuiLoad ( lang )
		if ( g_Langs[lang][1][text] ) then
			return g_Langs[lang][1][text]
		end
		for pattern, repl in pairs ( g_Langs[lang][2] ) do
			text = string.gsub ( text, pattern, repl )
		end
	end
	return text
end

local _outputChatBox = outputChatBox
function outputChatBox ( text, visibleTo, ... )
	local players, ret
	if ( not visibleTo ) then
		players = getElementsByType ( 'player' ) -- nil is not allowed here
	else
		players = getElementsByType ( 'player', visibleTo ) -- works for player too
	end
	for i, player in ipairs ( players ) do
		ret = _outputChatBox ( MuiGetMsg ( text, player ), player, ... )
	end
	return ret
end

local _kickPlayer = kickPlayer
local function kickPlayer ( kickedPlayer, arg2, arg3 )
	if ( isElement ( arg2 ) ) then
		if ( arg3 ) then
			arg3 = MuiGetMsg ( arg3 )
		end
	elseif ( arg2 ) then
		arg2 = MuiGetMsg ( arg2 )
	end
	return _kickPlayer ( kickedPlayer, arg2, arg3 )
end

--[[local _textCreateTextItem = textCreateTextItem
function textCreateTextItem ( text, ... )
	local textitem = _textCreateTextItem ( MuiGetMsg ( text ), ... )
	g_TextItems[textitem] = text
	return textitem
end

local _textItemSetText = textItemSetText
function textItemSetText ( textitem, text )
	if ( g_TextItems[textitem] ) then
		g_TextItems[textitem] = text
		text = MuiGetMsg ( text )
	end
	return _textItemSetText ( textitem, text )
end

local _textDestroyTextItem = textDestroyTextItem
function textDestroyTextItem ( textitem )
	g_TextItems[textitem] = nil
	return _textDestroyTextItem ( textitem )
end

local function MuiUpdate ()
	for textitem, text in pairs ( g_TextItems ) do
		_textItemSetText ( textitem, MuiGetMsg ( text ) )
	end
end

function MuiOnPlayerLangChange ()
	assert ( getElementType ( source ) == 'player' )
	MuiLoad ( lang )
	MuiUpdate ()
end

addEventHandler ( 'onPlayerLangChange', getRootElement (), MuiOnPlayerLangChange )]]
