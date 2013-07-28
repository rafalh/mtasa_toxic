PlayersTable:addColumns{
	{"warnings", "TINYINT UNSIGNED", default = 0},
}

function warnPlayer(player, source)
	local maxWarns = Settings.max_warns
	if(maxWarns > 0 and player.accountData.warnings == maxWarns) then
		player.accountData.warnings = 0
		addBan(nil, nil, player:getSerial(), source.el, "Warnings limit reached", Settings.warn_ban*24*3600)
		return true
	else
		player.accountData:add("warnings", 1)
		return false
	end
end

function unwarnPlayer(player)
	if(player.accountData.warnings > 0) then
		player.accountData:add("warnings", -1)
		return true
	end
	return false
end

local function CmdWarnings(message, arg)
	local player = (#arg >= 2 and Player.find(message:sub(arg[1]:len() + 2))) or Player.fromEl(source)
	local warns = player.accountData.warnings
	scriptMsg("%s has %u/%u warnings.", player:getName(), warns, Settings.max_warns)
end

CmdRegister("warnings", CmdWarnings, false, "Shows player warnings count")
CmdRegisterAlias("warns", "warnings")

local function CmdWarn(message, arg)
	local player = (#arg >= 2 and Player.find(message:sub(arg[1]:len() + 2)))
	local sourcePlayer = Player.fromEl(source)
	
	if(player) then
		if(not warnPlayer(player, sourcePlayer)) then
			outputMsg(root, Styles.red, "%s has been warned by %s and has now %u/%u warnings.",
				player:getName(true), sourcePlayer:getName(true),
				player.accountData.warnings, Settings.max_warns)
		else
			outputMsg(root, Styles.red, "%s has been banned by %s after %u warnings!",
				player:getName(true), sourcePlayer:getName(true), Settings.max_warns)
			kickPlayer(player.el, source, "Warnings limit reached ("..Settings.max_warns..")")
		end
	else privMsg(source, "Usage: %s", arg[1].." <player>") end
end

CmdRegister("warn", CmdWarn, "resource."..g_ResName..".warn", "Adds player warning and bans if he has too many")

local function CmdUnwarn (message, arg)
	local player = (#arg >= 2 and Player.find(message:sub(arg[1]:len() + 2)))
	local sourcePlayer = Player.fromEl(source)
	
	if(player) then
		if(unwarnPlayer(player)) then
			outputMsg(root, Styles.green, "%s's warning has been removed by %s!",
				player:getName(true), sourcePlayer:getName(true))
		else
			privMsg(source, "%s has no warnings!", player:getName())
		end
	else privMsg(source, "Usage: %s", arg[1].." <player>") end
end

CmdRegister("unwarn", CmdUnwarn, "resource."..g_ResName..".unwarn", "Removes player warning")
