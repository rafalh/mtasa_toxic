local g_Commands = {}
local g_CmdAliases = {}

addEvent ("onCommandsListReq", true)
addEvent ("onClientCommandsList", true)

function CmdRegister (name, func, access, description, ignore_console, ignore_chat)
	assert (name and not g_Commands[name] and func, tostring (name))
	assert (access ~= nil)
	
	g_Commands[name] = { f = func, access = access, descr = description, ignore_con = ignore_console, ignore_chat = ignore_chat }
end

function CmdRegisterAlias (alias_name, cmd_name, ignore_console, ignore_chat)
	assert (alias_name and cmd_name and not g_Commands[alias_name] and g_Commands[cmd_name])
	
	g_Commands[alias_name] = table.copy(g_Commands[cmd_name])
	local cmd_data = g_Commands[alias_name]
	cmd_data.alias = true
	cmd_data.ignore_con = ignore_console
	cmd_data.ignore_chat = ignore_chat
end

function CmdUnregister (name)
	assert (g_Commands[name])
	
	g_Commands[name] = nil
end

function CmdIsRegistered (name)
	return g_Commands[name] and true
end

function CmdGetAclRights ()
	local ret = {}
	local added = {}
	
	for cmd, data in pairs (g_Commands) do
		if (data.access and data.access ~= true and not added[data.access]) then
			table.insert (ret, data.access)
		end
	end
	
	return ret
end

local function onConsole(message)
	if (getElementType(source) ~= "player") then
		outputDebugString("Console support is experimental!", 3)
	elseif (isPlayerMuted (source)) then
		return
	end
	
	local arg = split (message, (" "):byte ())
	local cmd = (arg[1] and arg[1]:lower ()) or ""
	local cmd_data = g_Commands[cmd]
	
	if (cmd_data and not cmd_data.ignore_con) then
		parseCommand ("/"..message, source, { source }, "PM: ", "#ff6060")
	end
end

local function CmdHasPlayerAccess (cmd, player)
	local cmd_data = g_Commands[cmd]
	
	if (not cmd_data or not cmd_data.access) then
		return true
	elseif (cmd_data.access == true) then
		local admin_group = aclGetGroup ("Admin")
		local account = getPlayerAccount (player)
		local account_name = getAccountName (account)
		return admin_group and account and isObjectInACLGroup ("user."..account_name, admin_group)
	else
		return hasObjectPermissionTo (player, cmd_data.access, false)
	end
end

function CmdDoesIgnoreChat(cmd)
	local cmd_data = g_Commands[cmd]
	return cmd_data and cmd_data.ignore_chat
end

-- exported
function parseCommand(message, sender, recipients, chatPrefix, chatColor)
	source = sender
	local source_name = getPlayerName (source):gsub ("#%x%x%x%x%x%x", "")
	
	if (not recipients or recipients == g_Root) then
		recipients = getElementsByType ("player")
	end
	
	g_ScriptMsgState.prefix = chatPrefix or ""
	g_ScriptMsgState.color = chatColor or false
	
	g_ScriptMsgState.recipients = {}
	for i, player in ipairs (recipients) do
		local ignored = getElementData (player, "ignored_players")
		if (type (ignored) ~= "table" or not ignored[source_name]) then
			table.insert (g_ScriptMsgState.recipients, player)
		end
	end
	
	local arg = split (message, (" "):byte ())
	arg[1] = (arg[1] and arg[1]:lower ()) or ""
	local ch1 = arg[1]:sub (1, 1)
	local cmd = arg[1]:sub (2)
	
	if ((ch1 == "/" or ch1 == "!") and g_Commands[cmd]) then
		if (CmdHasPlayerAccess (cmd, source)) then
			g_Commands[cmd].f (message, arg)
		else
			privMsg (source, "Access denied for \"%s\"!", arg[1])
		end
	end
	
	g_ScriptMsgState.recipients = { g_Root }
	g_ScriptMsgState.prefix = ""
	g_ScriptMsgState.color = false
end

local function onCommandsListReq ()
	local commmands = {}
	
	for cmd, data in pairs (g_Commands) do
		if (not data.alias and CmdHasPlayerAccess (cmd, client)) then
			table.insert (commmands, { cmd, data.descr })
		end
	end
	
	table.sort (commmands, function (cmd1, cmd2) return cmd1[1] < cmd2[1] end)
	
	triggerClientEvent (client, "onClientCommandsList", g_Root, commmands)
end

addEventHandler ("onCommandsListReq", g_Root, onCommandsListReq)
addEventHandler ("onConsole", g_Root, onConsole)
