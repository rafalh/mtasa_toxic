PlayersTable:addColumns{
	{'warnings', 'TINYINT UNSIGNED', default = 0},
}

WarningsTable = Database.Table{
	name = 'warnings',
	{'id', 'INT UNSIGNED', pk = true},
	{'serial', 'VARCHAR(32)'},
	{'admin', 'INT UNSIGNED', fk = {'players', 'player'}},
	{'reason', 'TEXT'},
	{'timestamp', 'INT UNSIGNED'},
	{'duration', 'INT UNSIGNED'},
}

local ListWarningsRight = AccessRight('warnings')
local DelWarningRight = AccessRight('unwarn')

function warnPlayer(player, admin, reason, duration)
	assert(player and admin and reason)
	local now = getRealTime().timestamp
	
	-- Add warning to database
	DbQuery('INSERT INTO '..WarningsTable..' (serial, admin, reason, timestamp, duration) VALUES(?, ?, ?, ?, ?)', player:getSerial(), admin.id, reason, now, duration or 0)
	outputServerLog('WARNINGS: '..admin:getName()..' added warning for '..player:getSerial())
	
	-- Check how many warnings player has
	local warnsCount = DbCount(WarningsTable, 'serial=?', player:getSerial())
	local maxWarns = Settings.max_warns
	if(maxWarns == 0 or warnsCount < maxWarns) then
		return false
	end
	
	-- Warnings limit reached
	DbQuery('DELETE FROM '..WarningsTable..' WHERE serial=?', player:getSerial())
	
	-- Output message first
	local playerName = player:getName(true)
	local adminName = admin:getName(true)
	outputMsg(root, Styles.red, "%s has been banned by %s after %u warnings!",
		playerName, adminName, Settings.max_warns)
	
	-- Ban player
	addBan(nil, nil, player:getSerial(), admin.el,
		'Warnings limit reached - '..Settings.max_warns, Settings.warn_ban*24*3600)
	return true
end

function getPlayerWarningsCount(player)
	return DbCount(WarningsTable, 'serial=?', player:getSerial())
end

local function CmdWarnings(message, arg)
	local player = (#arg >= 2 and Player.find(message:sub(arg[1]:len() + 2))) or Player.fromEl(source)
	local sourcePlayer = Player.fromEl(source)
	
	if(player == sourcePlayer or ListWarningsRight:check(source)) then
		local warns = DbQuery('SELECT w.id, w.reason, w.timestamp, p.name AS admin FROM '..WarningsTable..' w, '..PlayersTable..' p WHERE w.serial=? AND p.player=w.admin', player:getSerial())
		RPC('openWarningsWnd', player.el, warns):setClient(source):exec()
	else
		local warnsCount = getPlayerWarningsCount(player)
		scriptMsg("%s has %u/%u warnings.", player:getName(), warnsCount, Settings.max_warns)
	end
end

CmdRegister('warnings', CmdWarnings, false, "Shows player warnings count")
CmdRegisterAlias('warns', 'warnings')

local function CmdWarn(message, arg)
	local player = (#arg >= 2 and Player.find(message:sub(arg[1]:len() + 2)))
	local admin = Player.fromEl(source)
	
	if(player) then
		RPC('openWarnPlayerWnd', player.el):setClient(source):exec()
	else privMsg(source, "Usage: %s", arg[1]..' <player>') end
end

CmdRegister('warn', CmdWarn, 'resource.'..g_ResName..'.warn', "Adds player warning and bans if he has too many")

function warnPlayerRPC(playerEl, reason)
	local player = Player.fromEl(playerEl)
	local admin = Player.fromEl(source)
	
	if(not player or not reason) then
		privMsg(admin, "Failed to warn player!")
		return false
	end
	
	if(not warnPlayer(player, admin, reason)) then
		local playerName = player:getName(true)
		local adminName = admin:getName(true)
		local warnsCount = getPlayerWarningsCount(player)
		--[[outputMsg(root, Styles.red, "%s has been warned by %s and has now %u/%u warnings.",
			playerName, adminName, warnsCount, Settings.max_warns)]]
		outputMsg(player, Styles.red, "You have been warned by %s and have now %u/%u warnings. Reason of new warning: %s",
			adminName, warnsCount, Settings.max_warns, reason)
	end
	return true
end
RPC.allow('warnPlayerRPC')

function deleteWarningRPC(id)
	local admin = Player.fromEl(source)
	if(not DelWarningRight:check(admin)) then return false end
	
	local rows = DbQuery('SELECT serial FROM '..WarningsTable..' WHERE id=?', id)
	local data = rows and rows[1]
	if(not data) then return false end
	
	outputServerLog('WARNINGS: '..admin:getName()..' deleted warning for '..data.serial)
	
	DbQuery('DELETE FROM '..WarningsTable..' WHERE id=?', id)
	
	local player = Player.fromSerial(data.serial)
	if(player) then
		outputMsg(player, Styles.green, "Your warning has been removed by %s!",
			admin:getName(true))
	end
	
	return true
end
RPC.allow('deleteWarningRPC')
