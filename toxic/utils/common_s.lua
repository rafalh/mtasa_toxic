----------------------
-- Global variables --
----------------------

g_PlayersCount = 0

g_InternalEventHandlers = {}
g_OldVehicleWeapons = nil
g_Countries = {}
g_IsoLangs = {}
g_MapTypes = {}
g_CustomRights = {}

-------------------
-- Custom events --
-------------------

addEvent('onEvent_'..g_ResName, true)

--------------------------------
-- Local function definitions --
--------------------------------

local function onEventHandler(event, ...)
	--outputChatBox(getResourceName ( sourceResource )..' '..tostring(event))
	if(not event or not g_InternalEventHandlers[event]) then return end
	if(sourceResource == g_Res or getResourceName(sourceResource):sub(1, 6) == 'rafalh') then
		for _, handler in ipairs(g_InternalEventHandlers[event]) do
			-- Note: unpack must be last arg
			handler(unpack({...}))
		end
	else
		outputDebugString('Access denied', 2)
	end
end

---------------------------------
-- Global function definitions --
---------------------------------

function findPlayer(str)
	if(not str) then
		return false
	end
	
	local player = getPlayerFromName(str) -- returns player or false
	if(player) then
		return player
	end
	
	str = str:lower()
	for player, pdata in pairs(g_Players) do
		if(not pdata.is_console) then
			local name = getPlayerName(player):gsub('#%x%x%x%x%x%x', ''):lower()
			if(name:find(str, 1, true)) then
				return player
			end
		end
	end
	return false
end

function strGradient(str, r1, g1, b1, r2, g2, b2)
	local n = math.max(math.abs(r1 - r2)/25.5, math.abs(b1 - b2)/25.5, math.abs(b1 - b2)/25.5, 2) -- max 10 codes, min 2
	local part_len = math.ceil(str:len ()/n)
	local buf = ''
	for i = 0, math.ceil (n) - 1, 1 do
		local a = i/(n - 1)
		buf = buf..('#%02X%02X%02X'):format(r1*(1 - a) + r2*a, g1*(1 - a) + g2*a, b1*(1 - a) + b2*a)..str:sub(1 + i*part_len, (i + 1)*part_len)
	end
	return buf
end

function addScreenMsg(text, player, ms, r, g, b)
	assert(not ms or ms > 50)
	
	local players = getElementsByType('player', player)
	local textitem
	
	for i, player in ipairs(players) do
		local pdata = Player.fromEl(player)
		
		if(not pdata.display) then
			pdata.display = textCreateDisplay()
			textDisplayAddObserver(pdata.display, player)
			pdata.scrMsgs = {}
		end
		local msg = MuiGetMsg(text, player)
		textitem = textCreateTextItem(msg, 0.5, 0.4 + #pdata.scrMsgs * 0.05, 'medium', r or 255, g or 0, b or 0, 255, 3, 'center')
		table.insert(pdata.scrMsgs, textitem)
		textDisplayAddText(pdata.display, textitem)
		
		if(ms) then
			addPlayerTimer(removeScreenMsg, ms, 1, player, textitem)
		end
	end
	
	return textitem
end

function removeScreenMsg(msgItem, player)
	local index = false
	for i, textItem in ipairs(Player.fromEl(player).scrMsgs) do
		if(index) then -- msgs under textItem
			local x, y = textItemGetPosition(textItem)
			textItemSetPosition(textItem, x, y - 0.05)
		elseif(textItem == msgItem) then
			index = i
		end
	end
	assert(index)
	table.remove(Player.fromEl(player).scrMsgs, index)
	textDestroyTextItem(msgItem)
end

function isPlayerAdmin(player)
	local adminGroup = aclGetGroup('Admin')
	local account = getPlayerAccount(player)
	local accountName = getAccountName(account)
	return (adminGroup and account and isObjectInACLGroup('user.'..accountName, adminGroup))
end

function addInternalEventHandler(eventtype, handler)
	assert(eventtype and handler)
	if(not g_InternalEventHandlers[eventtype]) then
		g_InternalEventHandlers[eventtype] = {}
	end
	table.insert(g_InternalEventHandlers[eventtype], handler)
end

function triggerClientInternalEvent(player, eventtype, source, ...)
	assert(eventtype and isElement(source) and isElement(player))
	
	local players = getElementsByType('player', player)
	for i, player in ipairs(players) do
		local pdata = Player.fromEl(player)
		if(pdata and pdata.sync) then
			triggerClientEvent(player, 'onEvent_'..g_ResName, source, eventtype, ...)
		end
	end
end

------------
-- Events --
------------

addEventHandler('onEvent_'..g_ResName, g_Root, onEventHandler)
