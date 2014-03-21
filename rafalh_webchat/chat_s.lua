---------------------
-- Local variables --
---------------------

local g_Msgs = {}
local g_MaxMsgs = 20
local g_Root = getRootElement()
local g_MsgId = 0

---------------------
-- Local functions --
---------------------

function table.size(tab)
    local n = 0
    for v in pairs( tab) do n = n + 1 end
    return n
end

local function getTime()
	local time = getRealTime()
	return string.format('%02d:%02d:%02d', time.hour, time.minute, time.second)
end

local function onPlayerChatHandler(msg, type)
	if(type == 0) then
		local r, g, b = getPlayerNametagColor(source)
		addChatStr(string.format('#%02x%02x%02x', r, g, b)..getPlayerName(source)..'#ffffff: '..msg)
	elseif(type == 1) then
		addChatStr('#ff00ff* '..string.gsub(getPlayerName(source), '#%x%x%x%x%x%x', '')..' '..msg)
	end
end

local function onPlayerJoinHandler()
	addChatStr('#ff6060* '..getPlayerName(source)..' joined the game!')
end

local function onPlayerQuitHandler(quitType)
	addChatStr('#ff6060* '..string.gsub(getPlayerName(source), '#%x%x%x%x%x%x', '')..' has left the game ('..quitType..').')
end

local function onPlayerWastedHandler(Ammo, killer, killerWeapon, bodypart)
	if(killer and getElementType(killer) == 'player') then
		addChatStr(getPlayerName(killer)..' killed '..getPlayerName(source)..' using weapon '..getWeaponNameFromID(killerWeapon)..'.'	)
	else
		addChatStr('#ff6060* '..string.gsub(getPlayerName(source), '#%x%x%x%x%x%x', '')..' died.')
	end
end

local function onPlayerChangeNickHandler(oldNick, newNick)
	oldNick = string.gsub(oldNick, '#%x%x%x%x%x%x', '')
	newNick = string.gsub(newNick, '#%x%x%x%x%x%x', '')
	if newNick ~= oldNick then
		addChatStr('#ff6060* '..oldNick..' is now known as '..newNick)
	end
end

---------------------------------
-- Global function definitions --
---------------------------------

function getChatMessages(id) -- pobiera wszystkie wiadomości które maja id wieksze od id
	local tmp = {}
	for _, msg in ipairs(g_Msgs) do
		if msg[2] > tonumber(id) then
			table.insert(tmp, msg)
		end
	end
	return tmp
end

function addChatStr(str)
	if table.size(g_Msgs) >= g_MaxMsgs then
		table.remove(g_Msgs, 1)
	end
	str = string.gsub(str, 'Ą', '&#260;')
	str = string.gsub(str, 'ą', '&#261;')
	str = string.gsub(str, 'Ć', '&#262;')
	str = string.gsub(str, 'ć', '&#263;')
	str = string.gsub(str, 'Ę', '&#280;')
	str = string.gsub(str, 'ę', '&#281;')
	str = string.gsub(str, 'Ł', '&#321;')
	str = string.gsub(str, 'ł', '&#322;')
	str = string.gsub(str, 'Ń', '&#323;')
	str = string.gsub(str, 'ń', '&#324;')
	str = string.gsub(str, 'Ó', '&#211;')
	str = string.gsub(str, 'ó', '&#243;')
	str = string.gsub(str, 'Ś', '&#346;')
	str = string.gsub(str, 'ś', '&#347;')
	str = string.gsub(str, 'Ź', '&#377;')
	str = string.gsub(str, 'ź', '&#378;')
	str = string.gsub(str, 'Ż', '&#379;')
	str = string.gsub(str, 'ż', '&#380;')
	table.insert(g_Msgs, { [0]=getTime(), [1]=str, [2]=g_MsgId })
	g_MsgId = g_MsgId + 1
end

function sendChatMsg(user, name, msg)
	msg = string.gsub(msg, '\196\132', 'Ą')
	msg = string.gsub(msg, '\196\133', 'ą')
	msg = string.gsub(msg, '\196\134', 'Ć')
	msg = string.gsub(msg, '\196\135', 'ć')
	msg = string.gsub(msg, '\196\152', 'Ę')
	msg = string.gsub(msg, '\196\153', 'ę')
	msg = string.gsub(msg, '\197\129', 'Ł')
	msg = string.gsub(msg, '\197\130', 'ł')
	msg = string.gsub(msg, '\197\131', 'Ń')
	msg = string.gsub(msg, '\197\132', 'ń')
	msg = string.gsub(msg, '\195\147', 'Ó')
	msg = string.gsub(msg, '\195\179', 'ó')
	msg = string.gsub(msg, '\197\154', 'Ś')
	msg = string.gsub(msg, '\197\155', 'ś')
	msg = string.gsub(msg, '\197\185', 'Ź')
	msg = string.gsub(msg, '\197\186', 'ź')
	msg = string.gsub(msg, '\197\187', 'Ż')
	msg = string.gsub(msg, '\197\188', 'ż')
	local str = '#ffff00'..tostring(name)..' (web)#ffffff: '..tostring(msg)
	outputChatBox(str, g_Root, 255, 255, 255, true)
	addChatStr(str)
	--outputChatBox(tostring(getAccountName(user)))
	--exports.toxic:chatHandler(user, msg, 0)
end

------------
-- Events --
------------

addEventHandler('onPlayerChat', g_Root, onPlayerChatHandler)
addEventHandler('onPlayerJoin', g_Root, onPlayerJoinHandler)
addEventHandler('onPlayerQuit', g_Root, onPlayerQuitHandler)
addEventHandler('onPlayerWasted', g_Root, onPlayerWastedHandler)
addEventHandler('onPlayerChangeNick', g_Root, onPlayerChangeNickHandler)
