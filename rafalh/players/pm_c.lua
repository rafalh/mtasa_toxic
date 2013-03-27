--------------
-- Includes --
--------------

#include "include/internal_events.lua"
#include "../include/serv_verification.lua"

---------------------
-- Local variables --
---------------------

local g_Chats = {}

--------------------------------
-- Local function definitions --
--------------------------------

local function guiMemoAddLine(memo, str)
	local buf = guiGetText(memo) --CEGUI always adds \n at the end
	if(buf == "\n") then buf = "" end
	guiSetText(memo, buf..str)
	guiMemoSetCaretIndex(memo, buf:len() + str:len())
end

local function PmSend(chatInfo)
	guiBringToFront(chatInfo.input)
	
	local msg = guiGetText(chatInfo.input, ""):sub(1, 128)
	if (msg == "") then return end
	
	guiSetText(chatInfo.input, "")
	guiMemoAddLine(chatInfo.chat, getPlayerName(g_Me):gsub("#%x%x%x%x%x%x", "")..": "..msg)
	
	triggerServerInternalEvent($(EV_PLAYER_PM_REQUEST), g_Me, msg, chatInfo.player)
end

local function PmSendBtnClick()
	for player, chatInfo in pairs(g_Chats) do
		if(chatInfo.sendBtn == source) then
			PmSend(chatInfo)
			return
		end
	end
end

local function PmToBackground(player)
	local chatInfo = g_Chats[player]
	guiSetAlpha(chatInfo.wnd, 0.3)
	guiSetInputEnabled(false)
	guiSetText(chatInfo.bgBtn, "Restore")
	chatInfo.enabled = false
end

local function PmRestore(player)
	local chatInfo = g_Chats[player]
	guiSetAlpha(chatInfo.wnd, 0.75)
	guiSetInputEnabled(true)
	guiSetText(chatInfo.bgBtn, "In background")
	guiBringToFront(chatInfo.input)
	chatInfo.enabled = true
end

local function PmBgBtnClick()
	for player, chatInfo in pairs(g_Chats) do
		if(chatInfo.bgBtn == source) then
			if(chatInfo.enabled) then
				PmToBackground(player)
			else
				PmRestore(player)
			end
			return
		end
	end
end

local function PmCloseBtnClick()
	for player, chatInfo in pairs(g_Chats) do
		if(chatInfo.closeBtn == source) then
			if(chatInfo.enabled) then
				guiSetInputEnabled(false)
			end
			chatInfo:destroy()
			g_Chats[player] = nil
			return
		end
	end
end

local function PmCreateGui(player)
	local chatInfo = {}
	local playerName = getPlayerName (player):gsub("#%x%x%x%x%x%x", "")
	
	chatInfo = GUI.create("pm")
	guiSetText(chatInfo.wnd, MuiGetMsg("Private Chat - %s"):format(playerName))
	chatInfo.player = player
	chatInfo.enabled = true
	g_Chats[player] = chatInfo
	
	addEventHandler("onClientGUIClick", chatInfo.sendBtn, PmSendBtnClick, false)
	addEventHandler("onClientGUIClick", chatInfo.bgBtn, PmBgBtnClick, false)
	addEventHandler("onClientGUIClick", chatInfo.closeBtn, PmCloseBtnClick, false)
end

local function PmCmdHandler(command, nick, ...)
	local player = findPlayer(nick)
	
	if(not player) then
		outputMsg(Styles.pm, "PM: Usage: %s", command.." <nick> [<message>]")
		return
	end
	
	local msg = table.concat({...}, " ")
	if(msg ~= "") then
		msg = msg:sub(1, 128)
		if(g_Chats[player]) then
			local myName = getPlayerName(g_Me):gsub("#%x%x%x%x%x%x", "")
			guiMemoAddLine(g_Chats[player].chat, myName..": "..msg)
		end
		
		triggerServerInternalEvent($(EV_PLAYER_PM_REQUEST), g_Me, msg, player)
		local playerName = getPlayerName(player):gsub("#%x%x%x%x%x%x", "")
		outputMsg(Styles.pm, "You have sent PM to %s: %s", playerName, msg)
	elseif(g_Chats[player]) then
		PmRestore(player)
	else
		PmCreateGui(player)
		guiSetInputEnabled(true)
	end
end

local function PmOnPlayerPrivMsg(msg)
	if(g_Chats[source]) then
		local playerName = getPlayerName(source):gsub("#%x%x%x%x%x%x", "")
		guiMemoAddLine(g_Chats[source].chat, playerName..": "..msg)
	end
end

local function PmOnPlayerQuit()
	if(g_Chats[source]) then
		local chatInfo = g_Chats[source]
		g_Chats[source] = nil
		g_Chats[#g_Chats + 1] = chatInfo
		guiSetEnabled(chatInfo.sendBtn, false)
		guiSetVisible(chatInfo.playerLeftLabel, true)
	end
end

--------------
-- Commands --
--------------

#VERIFY_SERVER_BEGIN("593C2070A55147B063D423AFAC7003D6")
	addCommandHandler("pm", PmCmdHandler, false)
	addInternalEventHandler($(EV_CLIENT_PLAYER_PM), PmOnPlayerPrivMsg)
	addEventHandler("onClientPlayerQuit", g_Root, PmOnPlayerQuit)
#VERIFY_SERVER_END ()
