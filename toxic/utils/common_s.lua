----------------------
-- Global variables --
----------------------

g_PlayersCount = 0

g_InternalEventHandlers = {}
g_OldVehicleWeapons = nil
g_Countries = {}
g_IsoLangs = {}
g_MapTypes = {}

-------------------
-- Custom events --
-------------------

addEvent('onEvent_'..g_ResName, true)

--------------------------------
-- Local function definitions --
--------------------------------

local function onEventHandler(event, ...)
	if(not event or not g_InternalEventHandlers[event]) then return end
	
	if(sourceResource) then -- HACKFIX: sourceResource is nil after r5937
		if(sourceResource ~= g_Res and getResourceName(sourceResource):sub(1, 6) ~= 'rafalh') then
			outputDebugString('Access denied', 2)
			return
		end
	else
		--outputDebugString('onEventHandler: sourceResource is nil (event '..tostring(event)..')', 2)
	end
	
	for _, handler in ipairs(g_InternalEventHandlers[event]) do
		-- Note: unpack must be last arg
		handler(unpack({...}))
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

if(base64Decode(base64Encode('\0')) ~= '\0') then
	-- character table string
	local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
	
	-- decoding
	function base64Decode(data)
		data = string.gsub(data, '[^'..b..'=]', '')
		return (data:gsub('.', function(x)
			if (x == '=') then return '' end
			local r,f='',(b:find(x)-1)
			for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
			return r;
		end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
			if (#x ~= 8) then return '' end
			local c=0
			for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
			return string.char(c)
		end))
	end
end
assert(base64Decode(base64Encode('\0')) == '\0')

function urlEncode(str)
	assert(str)
	return tostring(str):gsub('[^%w%.%-_ ]', function(ch)
		return ('%%%02X'):format(ch:byte())
	end):gsub(' ', '+')
end

function urlEncodeTbl(tbl)
	local tmp = {}
	for key, val in pairs(tbl) do
		table.insert(tmp, key..'='..urlEncode(val))
	end
	return table.concat(tmp, '&')
end

function urlDecode(str)
	assert(str)
	return tostring(str):gsub('%+', ' '):gsub('%%(%x%x)', function(num)
		return string.char(tonumber('0x'..num))
	end)
end

function htmlSpecialChars(str)
	return str:gsub('[&"\'<>]', {
		['&'] = '&amp;', ['"'] = '&quot;', ['\''] = '&#039;',
		['<'] = '&lt;', ['>'] = '&gt;'})
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

addInitFunc(function()
	addEventHandler('onEvent_'..g_ResName, g_Root, onEventHandler)
end)
