local TIMEOUT = 10000
local MSG_CLR = '#FFFF00'

local g_Root = getRootElement()
local g_ResRoot = getResourceRootElement(getThisResource())
local g_ResName = getResourceName(getThisResource())
local g_StatusQueries = false
local g_ServersPullingTicks
local g_StatusReportsLeft = 0
local g_ServersList = {}
local g_ThisServ = false
local g_MsgR, g_MsgG, g_MsgB = getColorFromString(MSG_CLR)

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

local function MsCompleteQueries()
	local displayNames = (get('display_player_names') == 'true')
	for id, data in ipairs(g_ServersList) do
		if(data ~= g_ThisServ) then
			local msg = data.name..' - '..#data.playerNames..' players'
			if(displayNames and #data.playerNames > 0) then
				local namesStr = table.concat(data.playerNames, ', ')
				if(namesStr:len() > 128) then
					namesStr = namesStr:sub(1, 128)..'...'
				end
				msg = msg..' ('..namesStr..')'
			end
			
			for player, v in pairs(g_StatusQueries) do
				if(getElementType(player) == 'console') then
					outputServerLog(msg)
				else
					outputChatBox(msg, player, g_MsgR, g_MsgG, g_MsgB)
				end
			end
		end
	end
	
	g_StatusQueries = false
end

local function MsStatusCallback(id, playerNames)
	-- Find server
	local data = g_ServersList[id or false]
	if(not data) then
		outputDebugString('Cannot query server: '..tostring(id)..' '..tostring(playerNames), 1)
		return
	end
	
	-- Remember data for later
	--outputDebugString('MsStatusCallback '..data.name, 3)
	data.playerNames = playerNames
	
	if(data.waiting) then
		-- Update waiting count
		g_StatusReportsLeft = g_StatusReportsLeft - 1
		assert(g_StatusReportsLeft >= 0)
		data.waiting = false
		
		-- Print status if all servers responded
		if(g_StatusReportsLeft == 0) then
			MsCompleteQueries()
		end
	end
end

local function MsPullServers()
	local cnt = 0
	for id, data in ipairs(g_ServersList) do
		if(data ~= g_ThisServ) then
			local addr = data.ip..':'..data.http_port
			
			if(not callRemote(addr, g_ResName, 'getServerStatus', MsStatusCallback, id)) then
				outputDebugString('callRemote failed: '..addr..', '..g_ResName, 2)
			else
				data.waiting = true -- waiting for reply
				cnt = cnt + 1
			end
		end
	end
	
	g_StatusReportsLeft = cnt
	g_ServersPullingTicks = getTickCount()
	g_StatusQueries = {}
end

local function MsRequestStatus(el)
	if(not g_StatusQueries or getTickCount() > g_ServersPullingTicks + TIMEOUT) then
		--outputDebugString('MsRequestStatus (new)', 3)
		MsPullServers()
	end
	
	g_StatusQueries[el] = true
end

local function CmdServStatus(source)
	--outputDebugString('CmdServStatus', 3)
	
	if(g_StatusQueries and g_StatusQueries[source]) then
		outputChatBox('Please wait...', source, 255, 0, 0)
	end
	
	MsRequestStatus(source)
end

local function MsBroadcastMsg(fmt, ...)
	for id, data in ipairs(g_ServersList) do
		if(data ~= g_ThisServ) then
			local addr = data.ip..':'..data.http_port
			if(not callRemote(addr, g_ResName, 'outputGlobalChat', function() end, id, fmt, ...)) then
				outputDebugString('callRemote failed', 2)
			end
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
		--MsBroadcastMsg('%s', msg)
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
	local msg = table.concat({...}, ' ')
	MsBroadcastMsg('%s: %s', color..name, msg)
	
	local text = color..name..': #FFFF00'..msg
	outputChatBox('[GLOBAL] '..text, g_Root, g_MsgR, g_MsgG, g_MsgB, true)
	outputServerLog('[GLOBAL] '..text:gsub('#%x%x%x%x%x%x', ''))
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

local function MsDetectCurrentServer()
	local currentIP = get('ip')
	local currentPort = getServerPort()
	for id, data in ipairs(g_ServersList) do
		if(data.ip == currentIP and data.port == currentPort) then
			g_ThisServ = data
			outputDebugString('This server has been detected: '..data.name, 3)
			break
		end
	end
	
	if(not g_ThisServ) then
		outputDebugString('This server has not been found in servers.xml!', 2)
	end
end

local function MsRegisterCommands()
	for id, data in ipairs(g_ServersList) do
		if(data.cmd and data ~= g_ThisServ) then
			addCommandHandler(data.cmd, CmdRedirect, false, false)
		end
	end
	
	local servStatusCmd = get('serv_status_cmd') or ''
	if(servStatusCmd ~= '') then
		addCommandHandler(servStatusCmd, CmdServStatus, false, false)
	end
	
	local globalChatCmd = get('global_cmd') or ''
	if(globalChatCmd ~= '') then
		addCommandHandler(globalChatCmd, CmdGlobal, false, false)
	end
end

local function MsPlayerJoin()
	if(get('join_quit') == 'true') then
		MsBroadcastMsg('* %s has joined %s', getPlayerName(source), g_ThisServ.name)
	end
end

local function MsPlayerQuit()
	if(get('join_quit') == 'true') then
		MsBroadcastMsg('* %s has left %s', getPlayerName(source), g_ThisServ.name)
	end
end

local function MsInit()
	MsLoadServers()
	MsDetectCurrentServer()
	MsRegisterCommands()
	
	local statusInt = tonumber(get('serv_status_int')) or 0
	if(statusInt > 0) then
		setTimer(MsRequestStatus, statusInt*1000, 0, g_Root)
	end
	
	--addEventHandler('onPlayerChat', g_Root, MsPlayerChat)
	addEventHandler('onPlayerJoin', g_Root, MsPlayerJoin)
	addEventHandler('onPlayerQuit', g_Root, MsPlayerQuit)
end

addEventHandler('onResourceStart', g_ResRoot, MsInit)

-- EXPORTS

function getServerStatus(id)
	--outputDebugString('getServerStatus '..tostring(id), 3)
	
	local names = {}
	for i, player in ipairs(getElementsByType('player')) do
		local name = getPlayerName(player)
		name = name:gsub('#%x%x%x%x%x%x', '')
		table.insert(names, name)
	end
	return id, names
end

function outputGlobalChat(id, fmt, ...)
	fmt = fmt:gsub('%%s', '%%s'..MSG_CLR)
	local text = fmt:format(...)
	
	outputChatBox('[GLOBAL] '..text, g_Root, g_MsgR, g_MsgG, g_MsgB, true)
	outputServerLog('[GLOBAL] '..text:gsub('#%x%x%x%x%x%x', ''))
end
