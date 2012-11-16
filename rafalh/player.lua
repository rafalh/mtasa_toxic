Player = {}
Player.__mt = {__index = Player}

function Player:getStat(name)
	return StGet(self.id, name)
end

function Player:fixName()
	local name = getPlayerName ( self.el )
	
	-- Change default name to allow new players join
	if ( name == "Player" or name:gsub ( "#%x%x%x%x%x%x", "" ) == "" ) then
		name = "ToxicPlayer"
		local i = 1
		while(getPlayerFromName(name)) do
			i = i + 1
			name = "ToxicPlayer"..i
		end
		setPlayerName ( self.el, name )
	end
	
	return name
end

function Player:getSerial()
	if(self.is_console) then
		return "0"
	else
		return getPlayerSerial ( self.el )
	end
end

function Player:getIP()
	if(self.is_console) then
		return ""
	else
		return getPlayerIP ( self.el )
	end
end

function Player:onRoomChange(room)
	self.room = room
	
	BtSendMapInfo(self.room, self.new, self.el)
end

function Player:destroy()
	g_Players[self.el] = nil
	g_IdToPlayer[self.id] = nil
	
	if ( not self.is_console ) then
		g_PlayersCount = g_PlayersCount - 1
		assert ( g_PlayersCount >= 0 )
	end
	
	 -- destroy everything related to player
	if ( self.display ) then
		for i, textitem in ipairs ( self.scrMsgs ) do
			textDestroyTextItem ( textitem )
		end
		textDestroyDisplay ( self.display )
	end
end

function Player.create(el)
	local now = getRealTime ().timestamp
	
	local self = setmetatable({}, Player.__mt)
	self.el = el
	self.is_console = getElementType ( el ) == "console"
	self.join_time = now
	self.timers = {}
	self.cp_times = false
	
	local roomEl = g_Root
	local roomMgrRes = getResourceFromName("roommgr")
	if(not self.is_console and roomMgrRes and getResourceState(roomMgrRes) == "running") then
		roomEl = call(roomMgrRes, "getPlayerRoom", self.el)
	end
	self.room = roomEl and Room.create(roomEl)
	
	local serial = self:getSerial()
	local ip = self:getIP()
	local name = self:fixName()
	
	-- Get player ID
	local rows = DbQuery ( "SELECT player, lang FROM rafalh_players WHERE serial=? LIMIT 1", serial )
	if ( not rows or not rows[1] ) then
		DbQuery ( "INSERT INTO rafalh_players (serial, ip, first_visit, online) VALUES (?, ?, ?, 1)", serial, ip or "", now )
		rows = DbQuery ( "SELECT player, lang FROM rafalh_players WHERE serial=? LIMIT 1", serial )
	else
		DbQuery ( "UPDATE rafalh_players SET ip=?, online=1 WHERE player=?", ip, rows[1].player )
	end
	self.id = rows[1].player
	
	g_Players[self.el] = self
	g_IdToPlayer[self.id] = self.el
	
	self.lang = ( g_Locales[rows[1].lang] and rows[1].lang ) or "en"
	setElementData ( self.el, "lang", self.lang )
	
	if ( not self.is_console ) then
		g_PlayersCount = g_PlayersCount + 1
	end
	
	name = name:gsub ( "#%x%x%x%x%x%x", "" )
	if ( NlCheckPlayer ( self.el, name, true ) ) then
		name = getPlayerName ( self.el ):gsub ( "#%x%x%x%x%x%x", "" )
	end
	DbQuery ( "UPDATE rafalh_players SET name=? WHERE player=?", name, self.id )
	
	local admin_res = getResourceFromName ( "admin" )
	local country = admin_res and getResourceState ( admin_res ) == "running" and call ( admin_res, "getPlayerCountry", self.el )
	
	setElementData ( self.el, "country", country )
	local img_path = country and ":admin/client/images/flags/"..country:lower ()..".png"
	if ( img_path and fileExists ( img_path ) ) then
		setElementData ( self.el, "country_img", img_path )
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
