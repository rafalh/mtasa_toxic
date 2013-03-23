--------------
-- Includes --
--------------

#include "include/internal_events.lua"

----------------------
-- Global variables --
----------------------

local g_MsgCommands = {}
local MODIFY_MSG_CMD = false

--------------------------
-- Function definitions --
--------------------------

local function McHandleCommand (message, arg)
	local msg = g_MsgCommands[arg[1]:sub (2)]
	assert (msg)
	
	local i = 1
	
	msg = msg:gsub ("%%m", getPlayerName (source)):gsub ("%%%%", "%%")
	msg = msg:gsub ("%%%a",
		function (s)
			i = i + 1
			if (s == "%p") then
				if (not arg[i] or arg[i]:lower () == "all") then
					return ""
				end
				
				local player = findPlayer (arg[i])
				if (player) then
					return getPlayerName (player)
				else
					privMsg (source, "Cannot find player "..arg[i])
					return ""
				end
			end
			return false
		end
	)
	
	msg = msg:gsub ("#%x%x%x%x%x%x", "")
	local r, g, b
	if (getElementType (source) == "player") then
		r, g, b = getPlayerNametagColor (source)
	else
		-- console
		r, g, b = 255, 128, 255
	end
	outputChatBox (getPlayerName (source)..": #FFFF00"..msg, g_Root, r, g, b, true)
	outputServerLog ("MSGCMD: "..(getPlayerName (source)..": "..msg))
	
	if (AsProcessMsg (source)) then
		return -- if it is spam don't run commands
	end
end

local function CmdAddCom (message, arg)
	if(not MODIFY_MSG_CMD) then
		privMsg (source, "Command is disabled!")
		return
	end
	
	if (#arg >= 3) then
		arg[2] = arg[2]:lower ()
		if (not g_MsgCommands[arg[2]]) then
			local node = xmlLoadFile ("conf\\msg_cmd.xml")
			if (node) then
				local subnode = xmlCreateChild (node, "command")
				if (subnode) then
					xmlNodeSetAttribute (subnode, "handler", arg[2])
					xmlNodeSetAttribute (subnode, "msg", message:sub ((arg[1]..arg[2]):len () + 3))
					xmlSaveFile (node)
					local msg = message:sub ((arg[1]..arg[2]):len () + 3)
					g_MsgCommands[arg[2]] = msg
					CmdRegister (arg[2], McHandleCommand, false, "Says: "..msg)
					scriptMsg ("Added command: %s", arg[2])
				end
				xmlUnloadFile (node)
			end
		else privMsg (source, "Command already exists!") end
	else privMsg (source, "Usage: %s", arg[1].." <command> <message>") end
end

CmdRegister ("addcom", CmdAddCom, "resource.rafalh.addcom", "Adds a custom command")

local function CmdRemCom (message, arg)
	if(not MODIFY_MSG_CMD) then
		privMsg (source, "Command is disabled!")
		return
	end
	
	if (#arg >= 2) then
		arg[2] = arg[2]:lower ()
		local node = xmlLoadFile ("conf\\msg_cmd.xml")
		if (node) then
			local i = 0
			while (xmlFindChild (node, "command", i) ~= false) do
				local subnode = xmlFindChild (node, "command", i)
				local handler = xmlNodeGetAttribute (subnode, "handler")
				if (handler == arg[2]) then
					xmlDestroyNode (subnode)
				end
				i = i + 1
			end
			if (g_MsgCommands[arg[2]]) then
				xmlSaveFile (node)
				g_MsgCommands[arg[2]] = nil
				CmdUnregister (arg[2])
				scriptMsg ("Removed command: %s", arg[2])
			end
			xmlUnloadFile (node)
		end
	else privMsg (source, "Usage: %s", arg[1].." <command>") end
end

CmdRegister ("remcom", CmdRemCom, "resource.rafalh.remcom", "Removes a custom command")

local function CmdEditCom (message, arg)
	if(not MODIFY_MSG_CMD) then
		privMsg (source, "Command is disabled!")
		return
	end
	
	if (#arg >= 3) then
		arg[2] = arg[2]:lower ()
		local msg = message:sub ((arg[1]..arg[2]):len () + 3)
		if (g_MsgCommands[arg[2]]) then
			local node = xmlLoadFile ("conf\\msg_cmd.xml")
			if (node) then
				local i = 0
				while (xmlFindChild (node, "command", i) ~= false) do
					local subnode = xmlFindChild (node, "command", i)
					local handler = xmlNodeGetAttribute (subnode, "handler")
					if (handler == arg[2]) then
						xmlDestroyNode (subnode)
					end
					i = i + 1
				end
				local subnode = xmlCreateChild (node, "command")
				if (subnode) then
					xmlNodeSetAttribute (subnode, "handler", arg[2])
					xmlNodeSetAttribute (subnode, "msg", msg)
					xmlSaveFile (node)
					g_MsgCommands[arg[2]] = msg
					scriptMsg ("Changed command: %s", arg[2])
				end
				xmlUnloadFile (node)
			end
		else privMsg (source, "Command doesn't exists!") end
	else privMsg (source, "Usage: %s", arg[1].." <command> <message>") end
end

CmdRegister ("editcom", CmdEditCom, "resource.rafalh.addcom", "Changes custom command message")

local function McInit ()
	local node, i = xmlLoadFile ("conf/msg_cmd.xml"), 0
	if (node) then
		while (true) do
			local subnode = xmlFindChild (node, "command", i)
			if (not subnode) then break end
			i = i + 1
			
			local cmd = xmlNodeGetAttribute (subnode, "handler")
			local msg = xmlNodeGetAttribute (subnode, "msg")
			assert (cmd and msg)
			g_MsgCommands[cmd] = msg
			CmdRegister (cmd, McHandleCommand, false, "Says: "..msg)
		end
		xmlUnloadFile (node)
	end
end

addInitFunc(McInit)
