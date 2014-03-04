-- Defines
#local DEBUG = true

-- Command Manager
CmdMgr = {}
CmdMgr.map = {}
CmdMgr.list = {}

#if(DEBUG) then
	-- checks if table doesn't contain disallowed keys and values
	local function checkTbl(tbl, allowed)
		for k, v in pairs(tbl) do
			-- Note: allowed[k] == true allows any type
			if(type(v) ~= allowed[k] and allowed[k] ~= true) then
				return k
			end
		end
	end
#end

function CmdMgr.register(info)

#if(DEBUG) then
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
	
	if(info.args) then
		local ARG_DESC_KEYS = {
			'string',
			type = 'string',
			defVal = true, -- optional
			defValFromCtx = 'string', -- optional
			min = 'number', -- optional
			max = 'number', -- optional
		}
		local VALID_ARG_TYPES = {'str', 'int', 'num', 'bool', 'player'}
		
		for i, argDesc in ipairs(info.args) do
			local invalidArg = checkTbl(argDesc, ARG_DESC_KEYS)
			assert(not invalidArg, 'Invalid argument descriptor for CmdMgr.register - '..tostring(invalidArg))
			assert(table.find(VALID_ARG_TYPES, argDesc.type), 'Invalid argument type for CmdMgr.register - '..tostring(argDesc.type))
		end
	end
#end -- DEBUG

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

function CmdMgr.output(ctx, fmt, ...)
	privMsg(ctx.player, fmt, ...)
end

function CmdMgr.prepareArgs(ctx, cmd, args)
	local argsDesc = cmd.args or {}
	
	if(not cmd.varargs and #args > #argsDesc) then
		CmdMgr.output(ctx, "Too many arguments given. Expected %u, got %u.", #argsDesc, #args)
		return false
	end
	
	local newArgs = {}
	for i, argDesc in ipairs(argsDesc) do
		local arg = args[i]
		local newArg
		
		if(arg ~= nil) then
			if(argDesc.type == 'player') then
				newArg = Player.find(arg)
				if(not newArg) then
					CmdMgr.output(ctx, "Player '%s' has not been found!", arg)
					return false
				end
			elseif(argDesc.type == 'num') then
				newArg = tonumber(arg)
				if(not newArg) then
					CmdMgr.output(ctx, "Expected number at argument #%u (%s).", i, argDesc[1])
					return false
				elseif(argDesc.min and newArg < argDesc.min) then
					CmdMgr.output(ctx, "Argument #%u (%s) must be greater than or equal to %d.", i, argDesc[1], argDesc.min)
					return false
				elseif(argDesc.max and newArg > argDesc.max) then
					CmdMgr.output(ctx, "Argument #%u (%s) must be less than or equal to %d.", i, argDesc[1], argDesc.max)
					return false
				end
			elseif(argDesc.type == 'int') then
				newArg = toint(arg)
				if(not newArg) then
					CmdMgr.output(ctx, "Expected integer at argument #%u (%s).", i, argDesc[1])
					return false
				elseif(argDesc.min and newArg < argDesc.min) then
					CmdMgr.output(ctx, "Argument #%u (%s) must be greater than or equal to %d.", i, argDesc[1], argDesc.min)
					return false
				elseif(argDesc.max and newArg > argDesc.max) then
					CmdMgr.output(ctx, "Argument #%u (%s) must be less than or equal to %d.", i, argDesc[1], argDesc.max)
					return false
				end
			elseif(argDesc.type == 'str') then
				newArg = arg
			elseif(argDesc.type == 'bool') then
				newArg = tobool(arg)
				if(newArg == nil) then
					CmdMgr.output(ctx, "Expected boolean value at argument #%u (%s).", i, argDesc[1])
					return false
				end
			else
				assert(false)
			end
		elseif(argDesc.defVal ~= nil) then
			newArg = argDesc.defVal
		elseif(argDesc.defValFromCtx ~= nil and ctx[argDesc.defValFromCtx] ~= nil) then
			newArg = ctx[argDesc.defValFromCtx]
		else
			CmdMgr.output(ctx, "Not enough arguments given. Expected argument #%u (%s).", i, argDesc[1])
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
			table.insert(ret, cmd)
		end
	end
	
	return ret
end

function CmdMgr.getUsage(cmdName)
	local cmd = CmdMgr.map[cmdName]
	if(not cmd) then return false end
	
	local ret = {}
	for i, argDesc in ipairs(cmd.args) do
		local opt = (argDesc.defVal ~= nil) or argDesc.defValFromCtx
		if(opt) then
			table.insert(ret, '['..argDesc[1]..']')
		else
			table.insert(ret, argDesc[1])
		end
	end
	
	if(cmd.varargs) then
		table.insert(ret, '...')
	end
	
	return table.concat(ret, ' ')
end

function CmdMgr.invoke(ctx, cmd, ...)
	local cmd = CmdMgr.map[cmdName]
	if(not cmd) then return false end
	
	if(cmd.accessRight and not cmd.accessRight:check(ctx.player)) then
		CmdMgr.output(ctx, "Access denied! You cannot use command '%s'.", cmd.name)
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

-- Note: source can be console element
local function onConsole(message)
	-- Don't allow any commands from muted player
	if(getElementType(source) == 'player' and isPlayerMuted(source)) then return end
	
	-- Execute command
	parseCommand('/'..message, source, {source}, 'PM: ', '#ff6060')
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
	ctx.cmdName = table.remove(args, 1):sub(2)
	local cmd = CmdMgr.map[ctx.cmdName]
	if(not cmd) then return end
	
	-- Check if player has access to this command
	if(cmd.accessRight and not cmd.accessRight:check(ctx.player)) then
		CmdMgr.output(ctx, "Access denied for \"%s\"!", ctx.cmdName)
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
	
	local status, err = pcall(cmd.func, ctx, unpack(args))
	if(not status) then
		Debug.err('Command '..msg:sub(1, 100)..' failed: '..err)
	end
	
	g_ScriptMsgState.recipients = {g_Root}
	g_ScriptMsgState.prefix = ''
	g_ScriptMsgState.color = false
end

function CmdMgr.getCommandsForHelp()
	local player = Player.fromEl(client)
	local commmands = CmdMgr.getAllowedCommands(player)
	
	table.sort(commmands, function(cmd1, cmd2) return cmd1.name < cmd2.name end)
	
	for i, cmd in ipairs(commmands) do
		commmands[i] = {cmd.name, cmd.desc, cmd.cat or false, cmd.aliases or false}
	end
	
	return commmands
end
RPC.allow('CmdMgr.getCommandsForHelp')

addInitFunc(function()
	addEventHandler('onConsole', g_Root, onConsole)
end)

#if(TEST) then
	Test.register('CmdMgr', function()
		local args
		
		args = CmdMgr.parseLine('abc def ghi')
		Test.checkTblEq(args, {'abc', 'def', 'ghi'})
		
		args = CmdMgr.parseLine('abc "def ghi" jkl')
		Test.checkTblEq(args, {'abc', 'def ghi', 'jkl'})
		
		args = CmdMgr.parseLine('abc \'def ghi\' jkl')
		Test.checkTblEq(args, {'abc', 'def ghi', 'jkl'})
		
		args = CmdMgr.parseLine('abc "def\' \'ghi" jkl')
		Test.checkTblEq(args, {'abc', 'def\' \'ghi', 'jkl'})
		
		args = CmdMgr.parseLine('abc "def ghi\\" jkl"')
		Test.checkTblEq(args, {'abc', 'def ghi" jkl'})
	end)
#end -- TEST
