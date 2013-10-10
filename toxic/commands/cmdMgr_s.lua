local g_Commands = {}
local g_CmdAliases = {}

CmdMgr = {}
CmdMgr.map = {}
CmdMgr.list = {}

addEvent('onCommandsListReq', true)
addEvent('onClientCommandsList', true)

-- checks if table doesn't contain disallowed keys and values
local function checkTbl(tbl, allowed)
	for k, v in pairs(tbl) do
		if(type(v) ~= allowed[k]) then
			return k
		end
	end
end

function CmdMgr.register(info)
	local invalidArg = checkTbl(info, {
		name = 'string',
		aliases = 'table', -- optional
		cat = 'string', -- optional
		desc = 'string', -- optional
		accessRight = 'table', -- optional
		args = 'table', -- optional
		varargs = 'boolean', -- optional
		func = 'function'})
	assert(not invalidArg, 'Invalid arg for CmdMgr.register - '..tostring(invalidArg))
	assert(info.name and info.func)
	
	assert(not CmdMgr.map[info.name], 'Command '..info.name..' already exists')
	CmdMgr.map[info.name] = info
	
	if(info.aliases) then
		for i, alias in ipairs(info.aliases) do
			assert(not CmdMgr.map[alias], info.name)
			CmdMgr.map[alias] = info
		end
	end
	
	table.insert(CmdMgr.list, info)
end

function CmdMgr.unregister(cmdName)
	local cmd = CmdMgr.map[cmdName]
	assert(cmd)
	
	CmdMgr.map[cmdName] = nil
	if(info.aliases) then
		for i, alias in ipairs(info.aliases) do
			CmdMgr.map[alias] = nil
		end
	end
	
	table.removeValue(CmdMgr.list, cmd)
end

function CmdMgr.exists(cmdName)
	return CmdMgr.map[cmdName] and true
end

function CmdMgr.prepareArgs(ctx, cmd, args)
	local argsDesc = cmd.args or {}
	
	if(not cmd.varargs and #args > #argsDesc) then
		privMsg(ctx.player, "Too many arguments given. Expected %u, got %u.", #argsDesc, #args)
	end
	
	local newArgs = {}
	for i, argDesc in ipairs(argsDesc) do
		local arg = args[i]
		local newArg
		
		if(arg ~= nil) then
			if(argDesc.type == 'player') then
				newArg = Player.find(arg)
				if(not newArg) then
					privMsg(ctx.player, "Player '%s' has not been found!", arg)
					return false
				end
			elseif(argDesc.type == 'number') then
				newArg = tonumber(arg)
				if(not newArg) then
					privMsg(ctx.player, "Expected number at argument #%u (%s).", i, argDesc[1])
					return false
				elseif(argDesc.min and newArg < argDesc.min) then
					privMsg(ctx.player, "Argument #%u (%s) must be greater than or equal to %d.", i, argDesc[1], argDesc.min)
					return false
				elseif(argDesc.max and newArg > argDesc.max) then
					privMsg(ctx.player, "Argument #%u (%s) must be less than or equal to %d.", i, argDesc[1], argDesc.max)
					return false
				end
			elseif(argDesc.type == 'integer') then
				newArg = toint(arg)
				if(not newArg) then
					privMsg(ctx.player, "Expected integer at argument #%u (%s).", i, argDesc[1])
					return false
				elseif(argDesc.min and newArg < argDesc.min) then
					privMsg(ctx.player, "Argument #%u (%s) must be greater than or equal to %d.", i, argDesc[1], argDesc.min)
					return false
				elseif(argDesc.max and newArg > argDesc.max) then
					privMsg(ctx.player, "Argument #%u (%s) must be less than or equal to %d.", i, argDesc[1], argDesc.max)
					return false
				end
			elseif(argDesc.type == 'string') then
				newArg = arg
			else
				assert(false)
			end
		elseif(argDesc.def ~= nil) then
			newArg = argDesc.def
		else
			privMsg(ctx.player, "Not enough arguments given. Expected argument #%u (%s).", i, argDesc[1])
			return false
		end
		
		table.insert(newArgs, newArg)
	end
	
	if(cmd.varargs) then
		for i = #argsDesc + 1, #args do
			table.insert(newArgs, args[i])
		end
	end
	
	return newArgs
end

function CmdMgr.getAllowedCommands(player)
	local ret = {}
	
	for i, cmd in ipairs(CmdMgr.list) do
		if(not cmd.accessRight or cmd.accessRight:check(player)) then
			table.insert(ret, {cmd.name, cmd.desc})
		end
	end
	
	return ret
end

function CmdMgr.getAccessRights()
	return {}
	--[[local ret = {}
	local added = {}
	
	for i, cmd in ipairs(CmdMgr.list) do
		if(cmd.accessRight and not added[cmd.accessRight]) then
			table.insert(ret, cmd.accessRight)
		end
	end
	
	return ret]]
end

function CmdMgr.invoke(ctx, cmd, ...)
	local cmd = CmdMgr.map[cmdName]
	if(not cmd) then return false end
	
	if(cmd.accessRight and not cmd.accessRight:check(ctx.player)) then
		privMsg(ctx.player, "Access denied! You cannot use command '%s'.", cmd.name)
		return false
	end
	
	local args = CmdMgr.prepareArgs(ctx, cmd, {...})
	if(not args) then return false end
	
	cmd.func(ctx, unpack(args))
	return true
end

function CmdMgr.parseLine(str)
	local args = {}
	local curArg = {}
	local escape, quote = false, false
	
	for i = 1, #str do
		local ch = str:sub(i, i)
		if(escape) then
			-- Character is escaped
			table.insert(curArg, ch)
			escape = false
		elseif(ch == '\\') then
			-- Escape next character
			escape = true
		elseif(ch == quote) then
			-- End quote
			quote = false
		elseif((ch == '"' or ch == '\'') and not quote) then
			-- Start quote
			quote = ch
		elseif(ch == ' ' and not quote) then
			-- Start next argument
			table.insert(args, table.concat(curArg))
			curArg = {}
		else
			-- Normal character
			table.insert(curArg, ch)
		end
	end
	
	table.insert(args, table.concat(curArg))
	return args
end

-------------------------------
--          OLD API          --
-------------------------------

-- Stubs

function CmdRegister(name, func, access, description, ignore_console, ignore_chat)
	if(not access) then access = nil end
	if(not description) then description = nil end
	
	if(access and type(access) ~= 'string') then
		outputDebugString('Boolean access is not supported ('..name..')', 2)
		access = nil
	end
	
	CmdMgr.register{
		name = name,
		accessRight = access and AccessRight(access, true),
		desc = description,
		--args = {{type = '...'}},
		varargs = true,
		func = function(ctx, ...)
			local args = {name, ...}
			local msg = table.concat(args, ' ')
			--outputDebugString('Running command - cmdline '..msg..', cmdargs '..#{...}, 3)
			func(msg, args)
		end,
	}
	
	if(ignore_console ~= nil) then outputDebugString('ignore_console not supported ('..name..')', 2) end
	if(ignore_chat ~= nil) then outputDebugString('ignore_chat not supported ('..name..')', 2) end
end

function CmdRegisterAlias(alias_name, cmd_name, ignore_console, ignore_chat)
	local cmd = CmdMgr.map[cmd_name]
	assert(cmd and not CmdMgr.map[alias_name])
	
	if(not cmd.aliases) then cmd.aliases = {} end
	table.insert(cmd.aliases, alias_name)
	CmdMgr.map[alias_name] = cmd
	
	if(ignore_console ~= nil) then outputDebugString('ignore_console not supported ('..alias_name..')', 2) end
	if(ignore_chat ~= nil) then outputDebugString('ignore_chat not supported ('..alias_name..')', 2) end
end

CmdUnregister = CmdMgr.unregister
CmdIsRegistered = CmdMgr.exists
CmdGetAclRights = CmdMgr.getAccessRights

-- Note: source can be console element
local function onConsole(message)
	-- Don't allow any commands from muted player
	if(getElementType(source) == 'player' and isPlayerMuted(source)) then return end
	
	-- Execute command
	parseCommand('/'..message, source, {source}, 'PM: ', '#ff6060')
end

function CmdDoesIgnoreChat(cmd)
	return false
end

-- exported
function parseCommand(msg, sender, recipients, chatPrefix, chatColor)
	-- Prepare context
	local ctx = {}
	ctx.player = Player.fromEl(sender)
	if(not ctx.player) then return end
	
	-- First check if this is a valid command
	local ch1 = msg:sub(1, 1)
	if(ch1 ~= '/' and ch1 ~= '!') then return end
	
	-- Prepare arguments
	local args = CmdMgr.parseLine(msg)
	
	-- Find command in map
	local cmdName = table.remove(args, 1):sub(2)
	local cmd = CmdMgr.map[cmdName]
	if(not cmd) then return end
	
	-- Check if player has access to this command
	if(cmd.accessRight and not cmd.accessRight:check(ctx.player)) then
		privMsg(ctx.player.el, "Access denied for \"%s\"!", cmdName)
		return
	end
	
	args = CmdMgr.prepareArgs(ctx, cmd, args)
	if(not args) then return end
	
	source = ctx.player.el
	local sourceName = ctx.player:getName()
	
	if(not recipients or recipients == g_Root) then
		recipients = getElementsByType('player')
	end
	
	g_ScriptMsgState.prefix = chatPrefix or ''
	g_ScriptMsgState.color = chatColor or false
	
	g_ScriptMsgState.recipients = {}
	for i, player in ipairs(recipients) do
		local ignored = getElementData(player, 'ignored_players')
		if(type(ignored) ~= 'table' or not ignored[sourceName]) then
			table.insert(g_ScriptMsgState.recipients, player)
		end
	end
	
	cmd.func(ctx, unpack(args))
	
	g_ScriptMsgState.recipients = {g_Root}
	g_ScriptMsgState.prefix = ''
	g_ScriptMsgState.color = false
end

local function onCommandsListReq()
	local player = Player.fromEl(client)
	local commmands = CmdMgr.getAllowedCommands(player)
	
	table.sort(commmands, function(cmd1, cmd2) return cmd1[1] < cmd2[1] end)
	
	triggerClientEvent(player.el, 'onClientCommandsList', g_Root, commmands)
end

addInitFunc(function()
	addEventHandler('onCommandsListReq', g_Root, onCommandsListReq)
	addEventHandler('onConsole', g_Root, onConsole)
end)

#local TEST = false
#if(TEST) then
	local args
	
	args = CmdMgr.parseLine('abc def ghi')
	assert(#args == 3 and args[1] == 'abc' and args[2] == 'def' and args[3] == 'ghi')
	
	args = CmdMgr.parseLine('abc "def ghi" jkl')
	assert(#args == 3 and args[1] == 'abc' and args[2] == 'def ghi' and args[3] == 'jkl')
	
	args = CmdMgr.parseLine('abc \'def ghi\' jkl')
	assert(#args == 3 and args[1] == 'abc' and args[2] == 'def ghi' and args[3] == 'jkl')
	
	args = CmdMgr.parseLine('abc "def\' \'ghi" jkl')
	assert(#args == 3 and args[1] == 'abc' and args[2] == 'def\' \'ghi' and args[3] == 'jkl')
	
	args = CmdMgr.parseLine('abc "def ghi\\" jkl"')
	assert(#args == 2 and args[1] == 'abc' and args[2] == 'def ghi" jkl')
#end -- TEST
