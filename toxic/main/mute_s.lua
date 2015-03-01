MutesTable = Database.Table{
	name = 'mutes',
	{'serial', 'VARCHAR(32)'},
	{'reason', 'VARCHAR(255)', null = true},
	{'timestamp', 'INT UNSIGNED'},
	{'duration', 'INT UNSIGNED', null = true},
	{'mutes_idx', unique = {'serial'}},
}

local g_VoiceRes = Resource('voice')

local function setPlayerVoiceMuted(player, muted)
	if(g_VoiceRes:isReady()) then
		return g_VoiceRes:call('setPlayerVoiceMuted', player, muted)
	end
	return false
end

local function unmuteTimerProc(playerEl)
	local pl = Player(playerEl)
	if(isPlayerMuted(pl.el)) then
		outputMsg(g_Root, Styles.green, "%s has been unmuted by Script!", pl:getName(true))
	end
	pl:unmute()
end

local function muteInternal(pl, sec)
	setPlayerMuted(pl.el, true)
	setPlayerVoiceMuted(pl.el, true)
	
	if(sec and sec > 0) then
		setPlayerTimer(unmuteTimerProc, sec * 1000, 1, pl.el)
	end
end

local function cleanMutesTbl()
	local now = getRealTime().timestamp
	DbQuery('DELETE FROM '..MutesTable..' WHERE duration IS NOT NULL AND timestamp+duration<=?', now)
end

function Player.__mt.__index:mute(sec, reason)
	sec = touint(sec)
	assert(sec)
	if(sec == 0) then sec = false end
	
	local serial = self:getSerial()
	local now = getRealTime().timestamp
	local data = DbQuerySingle('SELECT * FROM '..MutesTable..' WHERE serial=?', serial)
	if(data) then
		if(not data.duration or (sec and now + sec < data.timestamp + data.duration)) then
			return false
		else
			DbQuery('UPDATE '..MutesTable..' SET reason=?, timestamp=?, duration=? WHERE serial=?',
				reason, now, sec, serial)
		end
	else
		DbQuery('INSERT INTO '..MutesTable..' (serial, reason, timestamp, duration) VALUES(?, ?, ?, ?)',
			serial, reason, now, sec)
	end
	
	muteInternal(self, sec)
	return true
end

function Player.__mt.__index:unmute()
	local serial = self:getSerial()
	DbQuery('DELETE FROM '..MutesTable..' WHERE serial=?', serial)
	
	setPlayerMuted(self.el, false)
	setPlayerVoiceMuted(self.el, false)
end

local function onPlayerJoin()
	local pl = Player(source)
	local serial = pl:getSerial()
	local now = getRealTime().timestamp
	local data = DbQuerySingle('SELECT * FROM '..MutesTable..' WHERE serial=?', serial)
	if(not data) then return end
	
	if(data.duration and data.timestamp + data.duration <= now) then
		DbQuery('DELETE FROM '..MutesTable..' WHERE serial=?', serial)
	else
		if(not data.duration) then
			outputMsg(g_Root, Styles.red, "%s has got permanent mute!", pl:getName(true))
		else
			outputMsg(g_Root, Styles.red, "%s is muted!", pl:getName(true))
		end
		
		local sec = data.duration and (data.duration - (now - data.timestamp))
		muteInternal(pl, sec)
	end
end

addInitFunc(function()
	addEventHandler('onPlayerJoin', root, onPlayerJoin)
	cleanMutesTbl()
end)
