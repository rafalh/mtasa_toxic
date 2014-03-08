-- Command Manager
CmdMgr = {}
CmdMgr.map = {}
CmdMgr.list = {}

function CmdMgr.register(info)
	assert(info.name and info.func and not info.accessRight)
	
	assert(not CmdMgr.map[info.name], 'Command '..info.name..' already exists')
	CmdMgr.map[info.name] = info
	addCommandHandler(info.name, CmdMgr.onCmd, false)
	
	if(info.aliases) then
		for i, alias in ipairs(info.aliases) do
			assert(not CmdMgr.map[alias], info.name)
			CmdMgr.map[alias] = info
			addCommandHandler(alias, CmdMgr.onCmd, false)
		end
	end
	
	table.insert(CmdMgr.list, info)
end

function CmdMgr.onCmd(cmd, ...)
	local info = CmdMgr.map[cmd]
	assert(info)
	
	local ctx = {}
	info.func(ctx, ...)
end

function CmdMgr.getCommandsForHelp()
	local result = {}
	for i, cmd in pairs(CmdMgr.list) do
		table.insert(result, {cmd.name, cmd.desc, cmd.cat or false, cmd.aliases or false})
	end
	
	return result
end
