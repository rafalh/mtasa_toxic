Player = {}
Player.__mt = {__index = {cls = Player}}
Player.idMap = {}
Player.elMap = {}
Player.serialMap = {}
g_Players = Player.elMap -- FIXME

local g_AdminRes = Resource('admin')
local g_RoomMgrRes = Resource('roommgr')

addEvent('onPlayerChangeRoom')
addEvent('onPlayerChangeTeam')
addEvent('main.onAccountChange')

function Player.__mt.__index:getSerial()
	if(not self.serial) then
		if(self.is_console) then
			self.serial = '0'
		else
			self.serial = getPlayerSerial(self.el)
		end
	end
	return self.serial
end

function Player.__mt.__index:getSerialID()
	if(not self.serialID) then
		local serial = self:getSerial()
		local rows = DbQuery('SELECT id FROM '..SerialsTable..' WHERE serial=?', serial)
		local row = rows and rows[1]
		if(row) then
			self.serialID = row.id
		else
			DbQuery('INSERT INTO '..SerialsTable..' (serial) VALUES(?)', serial)
			self.serialID = Database.getLastInsertID()
		end
	end
	return self.serialID
end

function Player.__mt.__index:getIP()
	if(self.is_console) then
		return ''
	else
		return getPlayerIP(self.el)
	end
end

function Player.__mt.__index:getName(colorCodes)
	local name = getPlayerName(self.el)
	
	if(not colorCodes) then
		-- Remove color codes
		return name:gsub('#%x%x%x%x%x%x', '')
	elseif(not self.is_console) then
		-- Add team color
		local r, g, b = getPlayerNametagColor(self.el)
		if(r ~= 255 or g ~= 255 or b ~= 255) then
			return ('#%02X%02X%02X'):format(r, g, b)..name
		end
	end
	
	return name
end

function Player.__mt.__index:getAccountName()
	return getAccountName(getPlayerAccount(self.el))
end

function Player.__mt.__index:getPlayTime()
	return getRealTime().timestamp - self.loginTimestamp + self.accountData:get('time_here')
end

function Player.__mt.__index:addNotify(info)
	if(not self.sync) then return end -- ignore
	for i, msg in ipairs(info) do
		msg[1] = MuiGetMsg(msg[1], self.el)
	end
	RPC('NfAdd', info):setClient(self.el):exec()
end

function Player.__mt.__index:isAlive()
	if(isPedDead(self.el)) then
		return false
	end
	
	local state = getElementData(self.el, 'state')
	return (state == 'alive')
end

function Player.__mt.__index:isPlayerIgnored(anotherPlayer)
	local ignored = getElementData(self.el, 'ignored_players')
	if(not ignored) then return false end
	
	return ignored[anotherPlayer:getName()] and true
end

function Player.__mt.__index:disconnectFromAccount()
	local now = getRealTime().timestamp
	local timeSpent = now - self.loginTimestamp
	
	self.accountData:set({
		online = 0,
		time_here = self.accountData.time_here + timeSpent,
		last_visit = now}, true)
	
	if(self.id) then
		Player.idMap[self.id] = nil
	end
end

function Player.__mt.__index:setAccount(account)
	local now = getRealTime().timestamp
	
	if(type(account) == 'userdata') then
		account = not isGuestAccount(account) and getAccountName(account)
	end
	
	local id = false
	if(account) then
		local data = DbQuerySingle('SELECT player, online FROM '..PlayersTable..' WHERE account=? LIMIT 1', account)
		if(data and data.online == 1) then return false end
		id = data and data.player
	end
	
	if(self.accountData) then
		self:disconnectFromAccount()
	end
	
	self.id = id
	if(account and not self.id) then
		DbQuery('INSERT INTO '..PlayersTable..' (account, serial, first_visit) VALUES (?, ?, ?)', account, self:getSerial(), now)
		self.id = Database.getLastInsertID()
		assert(self.id)
	end
	
	if(self.id) then
		Player.idMap[self.id] = self
	end
	self.guest = not self.id
	self.loginTimestamp = now
	
	self.acl:update(account)
	if(self.sync) then
		self.acl:send(self)
	end
	
	self.accountData = AccountData.create(self.id)
	self.accountData:set({
		online = 1,
		serial = self:getSerial(),
		ip = self:getIP(),
		last_visit = now,
		name = self:getName(true),
		namePlain = self:getName(false),
	}, true)
	return true
end

function Player.onRoomChange(roomEl)
	local self = Player.fromEl(source)
	local room = Room(roomEl)
	self.room = room
	MiSendMapInfo(self)
	if(self.new) then
		MiShow(self)
	end
end

function Player.onTeamChange(team)
	local self = Player.fromEl(source)
	local fullName = self:getName(true)
	local plainName = self:getName(false)
	self.accountData:set{
		name = fullName,
		namePlain = plainName,
	}
end

function Player.__mt.__index:destroy()
	local prof = DbgPerf(10)
	
	self:disconnectFromAccount()
	
	Player.elMap[self.el] = nil
	Player.serialMap[self:getSerial()] = nil
	
	if(not self.is_console) then
		g_PlayersCount = g_PlayersCount - 1
		assert(g_PlayersCount >= 0)
	end
	
	 -- destroy everything related to player
	if(self.display) then
		for i, textItem in ipairs(self.scrMsgs) do
			textDestroyTextItem(textItem)
		end
		textDestroyDisplay(self.display)
		self.display = false
	end
	
	prof:cp('Player destroy')
end

function Player.create(el)
	local now = getRealTime().timestamp
	
	local self = setmetatable({}, Player.__mt)
	self.el = el
	self.is_console = getElementType(el) == 'console'
	self.join_time = now
	self.timers = {}
	self.cp_times = false
	self.acl = AccessList()
	self.clientSettings = {}
	
	-- get player room
	local roomEl = g_Root
	if(not self.is_console and g_RoomMgrRes:isReady()) then
		roomEl = g_RoomMgrRes:call('getPlayerRoom', self.el)
	end
	self.room = roomEl and Room(roomEl)
	
	-- get player account name
	local account = getPlayerAccount(self.el)
	self:setAccount(account)
	
	Player.elMap[self.el] = self
	Player.serialMap[self:getSerial()] = self
	if(self.is_console) then
		Player.console = self
	end
	
	self.lang = 'en'
	setElementData(self.el, 'lang', self.lang)
	
	if(not self.is_console) then
		g_PlayersCount = g_PlayersCount + 1
	end
	
	self.country = g_AdminRes:isReady() and g_AdminRes:call('getPlayerCountry', self.el)
	
	setElementData(self.el, 'country', self.country)
	local imgPath = self.country and ':admin/client/images/flags/'..self.country:lower()..'.png'
	if(imgPath and fileExists(imgPath)) then
		setElementData(self.el, 'country_img', imgPath)
	end
	
	return self
end

function Player.fromId(id)
	local pl = Player.idMap[id]
	--if(not pl) then Debug.warn('Failed to find player by ID: '..tostring(id)) Debug.printStackTrace() end
	return pl
end

function Player.fromEl(el)
	local pl = Player.elMap[el]
	--if(not pl) then Debug.warn('Failed to find player by element: '..tostring(el)) Debug.printStackTrace() end
	return pl
end

function Player.fromSerial(serial)
	local pl = Player.serialMap[serial]
	--if(not pl) then Debug.warn('Failed to find player by element: '..tostring(el)) Debug.printStackTrace() end
	return pl
end

function Player.getConsole()
	return Player.console
end

function Player.find(name)
	local el = findPlayer(name)
	if(not el) then return false end
	return Player.fromEl(el)
end

setmetatable(Player, {
	__call = function(tbl, arg)
		if(type(arg) == 'userdata') then
			return Player.fromEl(arg)
		else
			return Player.fromId(arg)
		end
	end}
)

addInitFunc(function()
	addEventHandler('onPlayerChangeRoom', g_Root, Player.onRoomChange)
	addEventHandler('onPlayerChangeTeam', g_Root, Player.onTeamChange)
end)
