----------------------
-- Global variables --
----------------------

local g_MsgCommands = {}
local g_VipRes = Resource('rafalh_vip')
local g_MediaRes = Resource('txmedia')

#local MODIFY_MSG_CMD = false

--------------------------
-- Function definitions --
--------------------------

local function McHandleCommand(ctx, ...)
	local msg = g_MsgCommands[ctx.cmdName]
	assert(msg)
	local text = msg.text
	local name = ctx.player:getName(true)
	local namePlain = ctx.player:getName()
	
	-- Handle '%m'
	local text = text:gsub('%%m', namePlain):gsub('%%%%', '%%')
	
	-- Handle '%p'
	local i = 0
	local args = {...}
	text = text:gsub('%%%a', function(s)
		i = i + 1
		if(s == '%p') then
			if(not args[i] or args[i]:lower() == 'all') then
				return ''
			end
			
			local player = findPlayer(args[i])
			if(player) then
				return getPlayerName(player):gsub('#%x%x%x%x%x%x', '')
			else
				privMsg(ctx.player, "Cannot find player %s", args[i])
				return ''
			end
		end
		return false
	end)
	
	-- Output message
	local r, g, b
	if(not ctx.player.is_console) then
		r, g, b = getPlayerNametagColor(ctx.player.el)
	else -- console
		r, g, b = 255, 128, 255
	end
	outputChatBox(name..': #FFFF00'..text, g_Root, r, g, b, true)
	outputServerLog('MSGCMD: '..namePlain..': '..text)
	
	if(msg.sound) then
		local isVip = g_VipRes:isReady() and g_VipRes:call('isVip', ctx.player.el)
		if(isVip) then
			local servAddr = get('mapmusic.server_address')
			local url =  'http://'..servAddr..'/'..g_MediaRes.name..'/sounds/'..msg.sound
			--outputChatBox(url)
			
			local now = getRealTime().timestamp
			local limit = Settings.soundCmdLimit
			if(not ctx.player.lastSoundCmd or now - ctx.player.lastSoundCmd >= limit) then
				ctx.player.lastSoundCmd = now
				RPC('McPlaySound', url, ctx.player.el):exec()
			else
				outputMsg(ctx.player, Styles.red, "You cannot use sound commands so often!")
			end
		end
	end
	
	-- Check for spam
	if(AsProcessMsg(ctx.player.el)) then
		-- If this is spam, don't run any commands
		return
	end
end

local function McCheckSoundsExist()
	for cmd, msg in pairs(g_MsgCommands) do
		if(msg.sound and not fileExists(':'..g_MediaRes.name..'/sounds/'..msg.sound)) then
			Debug.warn(msg.sound..' has not been found in txmedia resource!')
		end
	end
end

local function McInit()
	local node = xmlLoadFile('conf/msg_cmd.xml')
	if(not node) then
		Debug.warn('Failed to load msg_cmd.xml')
		return
	end
	
	local hasSound = false
	
	for i, subnode in ipairs(xmlNodeGetChildren(node)) do
		local attr = xmlNodeGetAttributes(subnode)
		
		assert(attr.cmd and attr.msg, tostring(attr.cmd))
		
		if(attr.sound) then
			hasSound = true
		end
		
		g_MsgCommands[attr.cmd] = {text = attr.msg, sound = attr.sound}
		
		CmdMgr.register{
			name = attr.cmd,
			desc = 'Says: '..attr.msg..(attr.sound and ' If invoked by a VIP player, plays a short sound in background.' or ''),
			varargs = true,
			func = McHandleCommand
		}
	end
	
	xmlUnloadFile(node)
	
	if(hasSound) then
		if(g_MediaRes:isReady()) then
			McCheckSoundsExist()
		elseif(g_MediaRes:exists()) then
			g_MediaRes:addReadyHandler(McCheckSoundsExist)
			--startResource(g_MediaRes.res)
		end
	end
end

#if(MODIFY_MSG_CMD) then

CmdMgr.register{
	name = 'addcom',
	desc = "Adds a custom command",
	accessRight = AccessRight('addcom'),
	args = {
		{'command', type = 'str'},
		{'message', type = 'str'},
	},
	func = function(ctx, cmdName, msg)
		cmdName = cmdName:lower()
		
		if(g_MsgCommands[cmdName]) then
			privMsg(ctx.player, "Command already exists!")
			return
		end
		
		local node = xmlLoadFile('conf/msg_cmd.xml')
		if(not node) then
			privMsg(ctx.player, "Failed to save new command!")
			return
		end
		
		local subnode = xmlCreateChild(node, 'command')
		if(subnode) then
			xmlNodeSetAttribute(subnode, 'cmd', cmdName)
			xmlNodeSetAttribute(subnode, 'msg', msg)
			xmlSaveFile(node)
			
			g_MsgCommands[cmdName] = {text = msg}
			CmdMgr.register{
				name = cmdName,
				desc = 'Says: '..msg,
				varargs = true,
				func = McHandleCommand
			}
			
			scriptMsg("Added command: %s", cmdName)
		else
			privMsg(ctx.player, "Failed to save new command!")
		end
		
		xmlUnloadFile(node)
	end
}

CmdMgr.register{
	name = 'remcom',
	desc = "Removes a custom command",
	accessRight = AccessRight('remcom'),
	args = {
		{'command', type = 'str'},
	},
	func = function(ctx, cmdName)
		if(not g_MsgCommands[cmdName]) then
			privMsg(ctx.player, "Command '%s' has not been found!", cmdName)
			return
		end
		
		local node = xmlLoadFile('conf/msg_cmd.xml')
		if(not node) then
			privMsg(ctx.player, "Failed to remove a command!")
			return
		end
		
		for i, subnode in ipairs(xmlNodeGetChildren(node)) do
			local curCmd = xmlNodeGetAttribute(subnode, 'cmd')
			if(curCmd == cmdName) then
				xmlDestroyNode(subnode)
				xmlSaveFile(node)
				
				g_MsgCommands[cmdName] = nil
				CmdMgr.unregister(cmdName)
				scriptMsg("Removed command: %s", cmdName)
			end
		end
		
		xmlUnloadFile(node)
	end
}

CmdMgr.register{
	name = 'editcom',
	desc = "Changes custom command message",
	accessRight = AccessRight('addcom'),
	args = {
		{'command', type = 'str'},
		{'message', type = 'str'},
	},
	func = function(ctx, cmdName, msg)
		cmdName = cmdName:lower()
		
		if(not g_MsgCommands[cmdName]) then
			privMsg(ctx.player, "Command '%s' has not been found!", cmdName)
			return
		end
		
		local node = xmlLoadFile('conf/msg_cmd.xml')
		if(not node) then
			privMsg(ctx.player, "Failed to change a command!")
			return
		end
		
		for i, subnode in ipairs(xmlNodeGetChildren(node)) do
			local curCmd = xmlNodeGetAttribute(subnode, 'cmd')
			if(curCmd == cmdName) then
				xmlNodeSetAttribute(subnode, 'msg', msg)
				xmlSaveFile(node)
				
				g_MsgCommands[cmdName].text = msg
				scriptMsg("Changed command: %s", cmdName)
			end
		end
		
		xmlUnloadFile(node)
	end
}

#end -- MODIFY_MSG_CMD

addInitFunc(McInit)
