local g_ServersList = {}

local g_Root = getRootElement()
local g_ResRoot = getResourceRootElement(getThisResource())
local g_ResName = getResourceName(getThisResource())
local g_StatusQueries = false
local g_ThisServ = false

local function CmdRedirect(source, cmd)
	for id, data in ipairs(g_ServersList) do
		if(data.cmd == cmd and data ~= g_ThisServ) then
			local ip, port = data.ip, data.port
			if(getPlayerIP(source) == data.ip) then
				ip = '127.0.0.1'
			end
			redirectPlayer(source, ip, port)
			break
		end
	end
end

local function MsStatusCallback(id, playerNames)
	if(id ~= 'ERROR' and g_ServersList[id]) then
		local data = g_ServersList[id]
		--outputDebugString('MsStatusCallback '..data.name, 2)
		
		local msg = data.name..' - '..#playerNames..' players'
		
		if(get('display_player_names') == 'true' and #playerNames > 0) then
			local namesStr = table.concat(playerNames, ', ')
			if(namesStr:len() > 128) then
				namesStr = namesStr:sub(1, 128)..'...'
			end
			msg = msg..' ('..namesStr..')'
		end
		
		for player, v in pairs(g_StatusQueries) do
			outputChatBox(msg, player, 255, 255, 0)
		end
	else
		outputDebugString('Cannot query server: '..tostring(id)..' '..tostring(playerNames), 1)
	end
	g_StatusQueries = false
end

local function MsRequestStatus(el)
	if(not g_StatusQueries) then
		--outputDebugString('new call', 2)
		
		for id, data in ipairs(g_ServersList) do
			if(data ~= g_ThisServ) then
				local host = data.ip..':'..data.http_port
				
				if(not callRemote(host, g_ResName, 'getServerStatus', MsStatusCallback, id)) then
					outputDebugString('callRemote failed: '..host..', '..g_ResName, 2)
				end
			end
		end
		g_StatusQueries = {}
	end
	
	g_StatusQueries[el] = true
end

local function CmdServStatus(source)
	outputDebugString('CmdServStatus', 3)
	
	if(g_StatusQueries and g_StatusQueries[source]) then
		outputChatBox('Please wait...', source, 255, 0, 0)
	end
	
	MsRequestStatus(source)
end

local function MsBroadcastMsg(msg)
	for id, data in ipairs(g_ServersList) do
		if(data ~= g_ThisServ) then
			local host = data.ip..':'..data.http_port
			callRemote(host, g_ResName, 'outputGlobalChat', function() end, id, msg)
		end
	end
end

--[[local function MsPlayerChat(msg, msg_type)
	if(wasEventCancelled()) then return end
	
	-- team or global messages beggining with ^
	if(msg:sub(1, 1) == '^' and (msg_type == 0 or msg_type == 2)) then
		local name = getPlayerName(source)
		
		if(msg_type == 0) then
			local r, g, b = getPlayerNametagColor(source)
			local color = ('#%02X%02X%02X'):format(r, g, b)
			msg = color..name..': '..msg:sub(2)
		else
			msg = '#FF00FF'..name..' '..msg:sub(2)
		end
		
		cancelEvent()
		--MsBroadcastMsg(msg)
	end
end]]

local function CmdGlobal(source, cmd, ...)
	--outputDebugString('CmdGlobal', 2)
	
	local name = getPlayerName(source)
	local r, g, b = 255, 128, 255
	if(getElementType(source) ~= 'console') then
		r, g, b = getPlayerNametagColor(source)
	end
	local color =('#%02X%02X%02X'):format(r, g, b)
	local msg = color..name..': #FFFF00'..table.concat({ ...}, ' ')
	MsBroadcastMsg(msg)
	outputChatBox('[GLOBAL] '..msg, g_Root, 255, 255, 0, true)
end

local function MsLoadServers()
	local node = xmlLoadFile('servers.xml')
	if(node) then
		for i, subnode in ipairs(xmlNodeGetChildren(node)) do
			local attr = xmlNodeGetAttributes(subnode)
			attr.port = tonumber(attr.port)
			attr.http_port = tonumber(attr.http_port)
			
			if(attr.name and attr.ip and attr.port and attr.http_port) then
				table.insert(g_ServersList, attr)
			else
				outputDebugString('Entry for server '..tostring(attr.name)..' is invalid!', 2)
			end
		end
		xmlUnloadFile(node)
	else
		outputDebugString('Failed to load servers.xml', 2)
	end
end

local function MsInit()
	MsLoadServers()
	
	local servStatusCmd = get('serv_status_cmd') or ''
	if(servStatusCmd ~= '') then
		addCommandHandler(servStatusCmd, CmdServStatus, false, false)
	end
	
	local globalChatCmd = get('global_cmd') or ''
	if(globalChatCmd ~= '') then
		addCommandHandler(globalChatCmd, CmdGlobal, false, false)
	end
	
	local statusInt = tonumber(get('serv_status_int')) or 0
	if(statusInt > 0) then
		setTimer(MsRequestStatus, statusInt*1000, 0, g_Root)
	end
	
	for id, data in ipairs(g_ServersList) do
		if(data.ip == get('ip') and data.port == getServerPort()) then
			g_ThisServ = data
			outputDebugString('This server: '..data.name, 3)
		elseif(data.cmd) then
			addCommandHandler(data.cmd, CmdRedirect, false, false)
		end
	end
end

-- EXPORTS

function getServerStatus(id)
	outputDebugString('getServerStatus '..tostring(id), 3)
	
	local names = {}
	for i, player in ipairs(getElementsByType('player')) do
		local name = getPlayerName(player)
		name = name:gsub('#%x%x%x%x%x%x', '')
		table.insert(names, name)
	end
	return id, names
end

function outputGlobalChat(id, msg)
	outputChatBox('[GLOBAL] '..msg, g_Root, 255, 255, 0, true)
	outputServerLog('[GLOBAL] '..msg:gsub('#%x%x%x%x%x%x', ''))
end

local function MsPlayerJoin()
	if(get('join_quit') == 'true') then
		MsBroadcastMsg('* ' .. getPlayerName(source) .. ' has joined '..g_ThisServ.name)
	end
end

local function MsPlayerQuit()
	if(get('join_quit') == 'true') then
		MsBroadcastMsg('* ' .. getPlayerName(source) .. ' has left '..g_ThisServ.name)
	end
end

addEventHandler('onResourceStart', g_ResRoot, MsInit)
--addEventHandler('onPlayerChat', g_Root, MsPlayerChat)
addEventHandler('onPlayerJoin', g_Root, MsPlayerJoin)
addEventHandler('onPlayerQuit', g_Root, MsPlayerQuit)
