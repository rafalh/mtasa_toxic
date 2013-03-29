Player = {}
Player.__mt = {__index = Player}
Player.idMap = {}
Player.elMap = {}
g_Players = Player.elMap -- FIXME

addEvent("onPlayerChangeRoom")
addEvent("onPlayerChangeTeam")
addEvent("main.onAccountChange")

function Player:getSerial()
	if(self.is_console) then
		return "0"
	else
		return getPlayerSerial(self.el)
	end
end

function Player:getIP()
	if(self.is_console) then
		return ""
	else
		return getPlayerIP(self.el)
	end
end

function Player:getName(colorCodes)
	local name = getPlayerName(self.el)
	
	if(not colorCodes) then
		-- Remove color codes
		return name:gsub("#%x%x%x%x%x%x", "")
	elseif(not self.is_console) then
		-- Add team color
		local r, g, b = getPlayerNametagColor(self.el)
		if(r ~= 255 or g ~= 255 or b ~= 255) then
			return ("#%02X%02X%02X"):format(r, g, b)..name
		end
	end
	
	return name
end

function Player:getPlayTime()
	return getRealTime().timestamp - self.loginTimestamp + self.accountData:get("time_here")
end

function Player:disconnectFromAccount()
	self.accountData:set("online", 0)
	
	local now = getRealTime().timestamp
	local timeSpent = now - self.loginTimestamp
	self.accountData:add("time_here", timeSpent)
	self.accountData:set("last_visit", now)
	
	if(self.id) then
		Player.idMap[self.id] = nil
	end
end

function Player:setAccount(account)
	local now = getRealTime().timestamp
	
	if(type(account) == "userdata") then
		account = not isGuestAccount(account) and getAccountName(account)
	end
	
	local id = false
	if(account) then
		local rows = DbQuery("SELECT player, online FROM rafalh_players WHERE account=? LIMIT 1", account)
		local data = rows and rows[1]
		if(data.online == 1) then return false end
		id = data.player
	end
	
	if(self.accountData) then
		self:disconnectFromAccount()
	end
	
	self.id = id
	if(account) then
		if(not self.id) then
			DbQuery("INSERT INTO rafalh_players (account, serial, first_visit) VALUES (?, ?, ?)", account, self:getSerial(), now)
			rows = DbQuery("SELECT player FROM rafalh_players WHERE account=? LIMIT 1", account)
			self.id = rows and rows[1] and rows[1].player
		end
		
		assert(self.id)
		Player.idMap[self.id] = self
	end
	self.guest = not self.id
	self.loginTimestamp = now
	
	self.accountData = PlayerAccountData.create(self.id)
	self.accountData:set("online", 1, true)
	self.accountData:set("serial", self:getSerial(), true)
	self.accountData:set("ip", self:getIP(), true)
	self.accountData:set("last_visit", now, true)
	local fullName = self:getName(true)
	self.accountData:set("name", fullName, true)
	return true
end

function Player.onRoomChange(roomEl)
	local self = Player.fromEl(source)
	local room = Room.create(roomEl)
	self.room = room
	BtSendMapInfo(self.room, self.new, self.el)
end

function Player.onTeamChange(team)
	local self = Player.fromEl(source)
	local fullName = self:getName(true)
	self.accountData:set("name", fullName)
end

function Player:destroy()
	self:disconnectFromAccount()
	
	Player.elMap[self.el] = nil
	
	if(not self.is_console) then
		g_PlayersCount = g_PlayersCount - 1
		assert(g_PlayersCount >= 0 )
	end
	
	 -- destroy everything related to player
	if(self.display) then
		for i, textItem in ipairs(self.scrMsgs) do
			textDestroyTextItem(textItem)
		end
		textDestroyDisplay(self.display)
		self.display = false
	end
end

function Player.create(el)
	local now = getRealTime().timestamp
	
	local self = setmetatable({}, Player.__mt)
	self.el = el
	self.is_console = getElementType(el) == "console"
	self.join_time = now
	self.timers = {}
	self.cp_times = false
	
	-- get player room
	local roomEl = g_Root
	local roomMgrRes = getResourceFromName("roommgr")
	if(not self.is_console and roomMgrRes and getResourceState(roomMgrRes) == "running") then
		roomEl = call(roomMgrRes, "getPlayerRoom", self.el)
	end
	self.room = roomEl and Room.create(roomEl)
	
	-- get player account name
	local account = getPlayerAccount(self.el)
	self:setAccount(account)
	
	Player.elMap[self.el] = self
	
	self.lang = "en"
	setElementData(self.el, "lang", self.lang)
	
	if(not self.is_console) then
		g_PlayersCount = g_PlayersCount + 1
	end
	
	local fullName = self:getName(true)
	self.accountData:set("name", fullName, true)
	
	local adminRes = getResourceFromName("admin")
	self.country = adminRes and getResourceState(adminRes) == "running" and call(adminRes, "getPlayerCountry", self.el)
	
	setElementData(self.el, "country", self.country)
	local imgPath = self.country and ":admin/client/images/flags/"..self.country:lower()..".png"
	if(imgPath and fileExists(imgPath)) then
		setElementData(self.el, "country_img", imgPath)
	end
	
	return self
end

function Player.fromId(id)
	return Player.idMap[id]
end

function Player.fromEl(el)
	return Player.elMap[el]
end

addInitFunc(function()
	addEventHandler("onPlayerChangeRoom", g_Root, Player.onRoomChange)
	addEventHandler("onPlayerChangeTeam", g_Root, Player.onTeamChange)
end)
