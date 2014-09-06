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
    for v in pairs(tab) do
		n = n + 1
	end
    return n
end

local function getTimeStr()
	local time = getRealTime()
	return string.format('%02d:%02d:%02d', time.hour, time.minute, time.second)
end

local function onPlayerChatHandler(msg, type)
	if(type == 0) then
		local r, g, b = getPlayerNametagColor(source)
		addChatStr(string.format('#%02x%02x%02x', r, g, b)..getPlayerName(source)..'#ffffff: '..msg)
	elseif(type == 1) then
		local namePlain = string.gsub(getPlayerName(source), '#%x%x%x%x%x%x', '')
		addChatStr('#ff00ff* '..namePlain..' '..msg)
	end
end

local function onPlayerJoinHandler()
	local namePlain = string.gsub(getPlayerName(source), '#%x%x%x%x%x%x', '')
	addChatStr('#ff6060* '..namePlain..' joined the game!')
end

local function onPlayerQuitHandler(quitType)
	local namePlain = string.gsub(getPlayerName(source), '#%x%x%x%x%x%x', '')
	addChatStr('#ff6060* '..namePlain..' has left the game ('..quitType..').')
end

local function onPlayerWastedHandler(Ammo, killer, killerWeapon, bodypart)
	if(killer and getElementType(killer) == 'player') then
		addChatStr(getPlayerName(killer)..' killed '..getPlayerName(source)..' using weapon '..getWeaponNameFromID(killerWeapon)..'.'	)
	else
		addChatStr('#ff6060* '..string.gsub(getPlayerName(source), '#%x%x%x%x%x%x', '')..' died.')
	end
end

local function onPlayerChangeNickHandler(oldNick, newNick)
	local oldNickPlain = string.gsub(oldNick, '#%x%x%x%x%x%x', '')
	local newNickPlain = string.gsub(newNick, '#%x%x%x%x%x%x', '')
	if(newNickPlain ~= oldNickPlain) then
		addChatStr('#ff6060* '..oldNickPlain..' is now known as '..newNickPlain)
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
	if(table.size(g_Msgs) >= g_MaxMsgs) then
		table.remove(g_Msgs, 1)
	end
	
	local msgInfo = { [0] = getTimeStr(), [1] = str, [2] = g_MsgId }
	table.insert(g_Msgs, msgInfo)
	g_MsgId = g_MsgId + 1
end

function sendChatMsg(user, name, msg)
	local str = '#ffff00'..tostring(name)..' (web)#ffffff: '..tostring(msg)
	outputChatBox(str, g_Root, 255, 255, 255, true)
	addChatStr(str)
	
	local toxicRes = getResourceFromName('toxic')
	if(toxicRes and getResourceState(toxicRes) == 'running') then
		local ret = call(toxicRes, 'parseCommand', msg, user)
		outputServerLog('calling toxic: '..tostring(ret))
	end
end

------------
-- Events --
------------

addEventHandler('onPlayerChat', g_Root, onPlayerChatHandler)
addEventHandler('onPlayerJoin', g_Root, onPlayerJoinHandler)
addEventHandler('onPlayerQuit', g_Root, onPlayerQuitHandler)
addEventHandler('onPlayerWasted', g_Root, onPlayerWastedHandler)
addEventHandler('onPlayerChangeNick', g_Root, onPlayerChangeNickHandler)
