----------------------
-- Global variables --
----------------------

local g_AdminCommands = {}

--------------------------------
-- Local function definitions --
--------------------------------

local function aCommandToArgs(admin, arg_str, args)
	local argv = split(arg_str, (' '):byte())
	local tmp
	for id, argt in ipairs(split(args, 44)) do
		if(argt == 'T') then
			tmp = getTeamFromName(argv[id])
			if(not tmp) then outputChatBox('Cannot find team: '..argv[id], g_Root, 255, 0, 0) end
			argv[id] = tmp
		elseif(argt == 'P') then
			tmp = findPlayer(argv[id])
			if(not tmp and tostring(argv[id]):lower() == 'me') then tmp = admin end
			if(not tmp) then outputChatBox('Cannot find player: '..tostring(argv[id]), g_Root, 255, 0, 0) end
			argv[id] = tmp
		elseif(argt == 't') then argv[id] = { argv[id] }
		elseif(argt == 's') then argv[id] = tostring(argv[id])
		elseif(argt == 'i') then argv[id] = tonumber(argv[id])
		elseif(argt == 't-') then
			local atable = {}
			for i = id, #argv do table.insert(atable, argv[id]) table.remove(argv, id) end
			argv[id] = atable
		elseif(argt == 's-') then
			local str = ''
			for i = id, #argv do str = str..' '..argv[i] table.remove(argv, i) end
			argv[id] = str
		end
	end
	return argv
end

local function onCommand(ctx, ...)
	local acmd = g_AdminCommands[ctx.cmdName]
	-- arg[1]:sub(1, 1) == '!'
	if(acmd) then
		arg = aCommandToArgs(ctx.player.el, table.concat({...}, ' '), acmd.args)
		if(acmd.type == 'player') then
			triggerEvent('aPlayer', ctx.player.el, arg[1], acmd.action, arg[2], arg[3])
		elseif(acmd.type == 'vehicle') then
			triggerEvent('aVehicle', ctx.player.el, arg[1], acmd.action, arg[2], arg[3])
		else
			triggerEvent('a'..acmd.type:sub(1, 1):upper()..acmd.type:sub(2), ctx.player.el, acmd.action, arg[1], arg[2], arg[3], arg[4])
		end
	end
end

local function init()
	local node = xmlLoadFile('conf/commands.xml')
	local types = { 'player', 'team', 'vehicle', 'resource', 'bans', 'server', 'admin' }
	
	if(node) then
		for id, type in ipairs(types) do
			local subnode = xmlFindChild(node, type, 0)
			if(subnode) then
				local i = 0
				while(true) do
					local command = xmlFindChild(subnode, 'command', i)
					if(not command) then break end
					i = i + 1
					
					local handler = xmlNodeGetAttribute(command, 'handler')
					local action = xmlNodeGetAttribute(command, 'call')
					local args = xmlNodeGetAttribute(command, 'args')
					
					if(handler and not CmdIsRegistered (handler)) then
						g_AdminCommands[handler] = {}
						g_AdminCommands[handler].type = type
						g_AdminCommands[handler].action = action
						if(args) then
							g_AdminCommands[handler].args = args
						end
						CmdMgr.register{
							name = handler,
							accessRight = AccessRight('command.'..action, true),
							varargs = true,
							func = onCommand
						}
					end
				end
			end
		end
		xmlUnloadFile(node)
	end
end

------------
-- Events --
------------

addInitFunc(init)
