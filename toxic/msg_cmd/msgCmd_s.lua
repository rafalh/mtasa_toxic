----------------------
-- Global variables --
----------------------

local g_MsgCommands = {}

local MODIFY_MSG_CMD = false

--------------------------
-- Function definitions --
--------------------------

local function McHandleCommand(message, arg)
	local msg = g_MsgCommands[arg[1]:sub(2)]
	assert(msg)
	local text = msg.text
	local name = getPlayerName(source)
	local namePlain = name:gsub("#%x%x%x%x%x%x", "")
	local pdata = Player.fromEl(source)
	
	-- Handle '%m'
	local text = text:gsub("%%m", namePlain):gsub("%%%%", "%%")
	
	-- Handle '%p'
	local i = 1
	text = text:gsub("%%%a", function(s)
		i = i + 1
		if(s == "%p") then
			if(not arg[i] or arg[i]:lower() == "all") then
				return ""
			end
			
			local player = findPlayer(arg[i])
			if(player) then
				return getPlayerName(player):gsub("#%x%x%x%x%x%x", "")
			else
				privMsg(source, "Cannot find player "..arg[i])
				return ""
			end
		end
		return false
	end)
	
	-- Output message
	local r, g, b
	if(getElementType(source) == "player") then
		r, g, b = getPlayerNametagColor(source)
	else -- console
		r, g, b = 255, 128, 255
	end
	outputChatBox(name..": #FFFF00"..text, g_Root, r, g, b, true)
	outputServerLog("MSGCMD: "..namePlain..": "..text)
	
	if(msg.sound) then
		local vipRes = getResourceFromName("rafalh_vip")
		local isVip = vipRes and getResourceState(vipRes) == "running" and call(vipRes, "isVip", source)
		if(isVip) then
			local servAddr = get("mapmusic.server_address")
			local url =  "http://"..servAddr.."/"..getResourceName(resource).."/commands/sounds/"..msg.sound
			--outputChatBox(url)
			
			local now = getRealTime().timestamp
			local limit = Settings.soundCmdLimit
			if(not pdata.lastSoundCmd or now - pdata.lastSoundCmd >= limit) then
				pdata.lastSoundCmd = now
				RPC("McPlaySound", url, source):exec()
			else
				outputMsg(pdata, Styles.red, "You cannot use sound commands so often!")
			end
		end
	end
	
	-- Check for spam
	if(AsProcessMsg(source)) then
		-- If this is spam, don't run any commands
		return
	end
end

local function McInit()
	local node = xmlLoadFile("conf/msg_cmd.xml")
	if(node) then
		for i, subnode in ipairs(xmlNodeGetChildren(node)) do
			local attr = xmlNodeGetAttributes(subnode)
			
			assert(attr.cmd and attr.msg, tostring(attr.cmd))
			g_MsgCommands[attr.cmd] = {text = attr.msg, sound = attr.sound}
			CmdRegister(attr.cmd, McHandleCommand, false, "Says: "..attr.msg..(attr.sound and " If invoked by a VIP player, plays a short sound in background." or ""))
		end
		xmlUnloadFile(node)
	else
		outputDebugString("Failed to load msg_cmd.xml", 2)
	end
end

local function CmdAddCom(message, arg)
	if(not MODIFY_MSG_CMD) then
		privMsg (source, "Command is disabled!")
		return
	end
	
	if(#arg >= 3) then
		arg[2] = arg[2]:lower()
		if(not g_MsgCommands[arg[2]]) then
			local node = xmlLoadFile("conf\\msg_cmd.xml")
			if (node) then
				local subnode = xmlCreateChild (node, "command")
				if(subnode) then
					xmlNodeSetAttribute(subnode, "cmd", arg[2])
					xmlNodeSetAttribute(subnode, "msg", message:sub ((arg[1]..arg[2]):len () + 3))
					xmlSaveFile (node)
					local msg = message:sub ((arg[1]..arg[2]):len () + 3)
					g_MsgCommands[arg[2]] = msg
					CmdRegister (arg[2], McHandleCommand, false, "Says: "..msg)
					scriptMsg ("Added command: %s", arg[2])
				end
				xmlUnloadFile(node)
			end
		else privMsg(source, "Command already exists!") end
	else privMsg(source, "Usage: %s", arg[1].." <command> <message>") end
end

CmdRegister("addcom", CmdAddCom, "resource."..g_ResName..".addcom", "Adds a custom command")

local function CmdRemCom(message, arg)
	if(not MODIFY_MSG_CMD) then
		privMsg(source, "Command is disabled!")
		return
	end
	
	if(#arg >= 2) then
		arg[2] = arg[2]:lower()
		local node = xmlLoadFile("conf\\msg_cmd.xml")
		if(node) then
			local i = 0
			while(xmlFindChild (node, "command", i) ~= false) do
				local subnode = xmlFindChild (node, "command", i)
				local handler = xmlNodeGetAttribute (subnode, "handler")
				if (handler == arg[2]) then
					xmlDestroyNode (subnode)
				end
				i = i + 1
			end
			if(g_MsgCommands[arg[2]]) then
				xmlSaveFile(node)
				g_MsgCommands[arg[2]] = nil
				CmdUnregister(arg[2])
				scriptMsg("Removed command: %s", arg[2])
			end
			xmlUnloadFile(node)
		end
	else privMsg(source, "Usage: %s", arg[1].." <command>") end
end

CmdRegister("remcom", CmdRemCom, "resource."..g_ResName..".remcom", "Removes a custom command")

local function CmdEditCom(message, arg)
	if(not MODIFY_MSG_CMD) then
		privMsg(source, "Command is disabled!")
		return
	end
	
	if(#arg >= 3) then
		arg[2] = arg[2]:lower()
		local msg = message:sub((arg[1]..arg[2]):len () + 3)
		if(g_MsgCommands[arg[2]]) then
			local node = xmlLoadFile("conf\\msg_cmd.xml")
			if (node) then
				local i = 0
				while(xmlFindChild(node, "command", i) ~= false) do
					local subnode = xmlFindChild(node, "command", i)
					local handler = xmlNodeGetAttribute(subnode, "handler")
					if(handler == arg[2]) then
						xmlDestroyNode(subnode)
					end
					i = i + 1
				end
				local subnode = xmlCreateChild(node, "command")
				if (subnode) then
					xmlNodeSetAttribute(subnode, "handler", arg[2])
					xmlNodeSetAttribute(subnode, "msg", msg)
					xmlSaveFile(node)
					g_MsgCommands[arg[2]] = msg
					scriptMsg("Changed command: %s", arg[2])
				end
				xmlUnloadFile(node)
			end
		else privMsg(source, "Command doesn't exists!") end
	else privMsg(source, "Usage: %s", arg[1].." <command> <message>") end
end

CmdRegister("editcom", CmdEditCom, "resource."..g_ResName..".addcom", "Changes custom command message")

addInitFunc(McInit)
