Player = {}
Player.__mt = {__index = Player}

addEvent("onPlayerChangeRoom")
addEvent("onPlayerChangeTeam")

function Player:fixName()
	local name = getPlayerName(self.el)
	
	-- Change default name to allow new players join
	if(name == "Player" or name:gsub("#%x%x%x%x%x%x", "") == "") then
		name = "ToxicPlayer"
		local i = 1
		while(getPlayerFromName(name)) do
			i = i + 1
			name = "ToxicPlayer"..i
		end
		setPlayerName(self.el, name)
	end
	
	return name
end

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

function Player:getName(teamColor)
	local name = getPlayerName(self.el)
	if(teamColor and not self.is_console) then
		local r, g, b = getPlayerNametagColor(self.el)
		if(r ~= 255 or g ~= 255 or b ~= 255) then
			return ("#%02X%02X%02X"):format(r, g, b)..name
		end
	end
	return name
end

function Player:getPlayTime()
	return getRealTime().timestamp - self.join_time + self.accountData:get("time_here")
end

function Player:onRoomChange(room)
	self.room = room
	
	BtSendMapInfo(self.room, self.new, self.el)
end

function Player:onTeamChange(team)
	local fullName = self:getName(true)
	self.accountData:set("name", fullName)
end

function Player:destroy()
	self.accountData:set("online", 0)
	
	g_Players[self.el] = nil
	g_IdToPlayer[self.id] = nil
	
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

function Player.create(el, account)
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
	if(not account) then
		account = getPlayerAccount(self.el)
	end
	local accountName = nil
	if(not isGuestAccount(account)) then
		accountName = getAccountName(account)
		self.guest = false
	else
		self.guest = true
	end
	
	local serial = self:getSerial()
	local ip = self:getIP()
	local name = self:fixName()
	
	-- Get player ID
	local data = false
	
	-- try account first
	if(accountName) then
		local rows = DbQuery("SELECT player, lang FROM rafalh_players WHERE account=? LIMIT 1", accountName)
		data = rows and rows[1]
	end
	
	-- try serial now
	if(not data) then
		local rows = DbQuery("SELECT player, lang FROM rafalh_players WHERE serial=? LIMIT 1", serial)
		data = rows and rows[1]
	end
	
	if(not data) then
		-- user has no account
		DbQuery("INSERT INTO rafalh_players (serial, account, ip, first_visit, online) VALUES (?, ?, ?, ?, 1)", serial, accountName, ip or "", now)
		rows = DbQuery("SELECT player, lang FROM rafalh_players WHERE serial=? AND account=? LIMIT 1", serial, accountName)
		data = rows and rows[1]
	else
		DbQuery("UPDATE rafalh_players SET serial=?, ip=?, online=1 WHERE player=?", serial, ip, data.player)
		if(accountName) then
			DbQuery("UPDATE rafalh_players SET account=? WHERE player=?", accountName, data.player)
		end
	end
	self.id = data.player
	self.accountData = PlayerAccountData.create(self.id)
	self.accountData:set("online", 1)
	
	g_Players[self.el] = self
	g_IdToPlayer[self.id] = self.el
	
	self.lang = (LocaleList.exists(data.lang) and data.lang) or "en"
	setElementData(self.el, "lang", self.lang)
	
	if(not self.is_console) then
		g_PlayersCount = g_PlayersCount + 1
	end
	
	if(NlCheckPlayer) then
		NlCheckPlayer(self.el, name, true)
	end
	
	local fullName = self:getName(true)
	self.accountData:set("name", fullName)
	
	if(accountName) then
		--self.accountData:set("account", accountName)
		--setAccountData(account, "toxic.id", self.id)
	end
	
	local adminRes = getResourceFromName("admin")
	local country = adminRes and getResourceState(adminRes) == "running" and call(adminRes, "getPlayerCountry", self.el)
	
	setElementData(self.el, "country", country)
	local imgPath = country and ":admin/client/images/flags/"..country:lower()..".png"
	if(imgPath and fileExists(imgPath)) then
		setElementData(self.el, "country_img", imgPath)
	end
	
	return self
end

addEventHandler("onPlayerChangeRoom", g_Root, function(room)
	local player = g_Players[source]
	if(player) then
		local room = Room.create(room)
		player:onRoomChange(room)
	end
end)

addEventHandler("onPlayerChangeTeam", g_Root, function(team)
	local player = g_Players[source]
	if(player) then
		player:onTeamChange(team)
	end
end)
