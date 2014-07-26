
#include 'include/config.lua'

namespace('Teams')

local g_TeamGUI
local g_TeamClrWnd

addEvent('toxic.onColorDlgClose')

local function closeOwnedTeamGUI()
	if(not g_TeamGUI) then return end
	g_TeamGUI:destroy()
	g_TeamGUI = false
	showCursor(false)
end

local function acceptOwnedTeamGUI()
	local ownedTeam = ShpGetInventory('team')
	if(ownedTeam) then
		local teamInfo = {}
		teamInfo.id = ownedTeam
		teamInfo.tag = guiGetText(g_TeamGUI.tag)
		teamInfo.name = guiGetText(g_TeamGUI.name)
		teamInfo.color = guiGetText(g_TeamGUI.color)
		if(teamInfo.color:len() == 0) then
			teamInfo.color = false
		end
		RPC('Teams.updateOwnedRPC', teamInfo):onResult(function(status, err)
			if(status) then
				closeOwnedTeamGUI()
			else
				guiSetText(g_TeamGUI.info, err)
				guiLabelSetColor(g_TeamGUI.info, 255, 0, 0)
			end
		end):exec()
	end
end

local function onOwnedTeamInfo(teamInfo, err)
	if(g_TeamGUI) then return end
	
	if(not teamInfo) then
		outputMsg(Styles.red, 'Failed to get team info')
		return
	end
	
	g_TeamGUI = GUI.create('shopTeamEdit')
	
	guiSetText(g_TeamGUI.tag, teamInfo.tag)
	guiSetText(g_TeamGUI.name, teamInfo.name)
	guiSetText(g_TeamGUI.color, teamInfo.color)
	
	addEventHandler('onClientGUIClick', g_TeamGUI.ok, acceptOwnedTeamGUI, false)
	addEventHandler('onClientGUIClick', g_TeamGUI.cancel, closeOwnedTeamGUI, false)
	
	addEventHandler('onClientGUIClick', g_TeamGUI.changeColor, function()
		if(g_TeamClrWnd) then
			guiBringToFront(g_TeamClrWnd)
		else
			local r, g, b = getColorFromString(guiGetText(g_TeamGUI.color))
			local sharedRes = Resource('rafalh_shared')
			g_TeamClrWnd = sharedRes:call('createColorDlg', 'toxic.onColorDlgClose', r, g, b)
			addEventHandler('toxic.onColorDlgClose', g_TeamClrWnd, function(r, g, b)
				if(r) then
					guiSetText(g_TeamGUI.color, ('#%02X%02X%02X'):format(r, g, b))
				end
				g_TeamClrWnd = nil
			end, false)
		end
	end, false)
	
	showCursor(true)
end

ShpRegisterItem{
	id = 'team',
	name = "Clan Team",
	descr = "Buy team for your clan. You can set tag, full name and color of your team.",
	img = 'teams/img/team.png',
	onUse = function(v)
		if(g_TeamGUI) then return end
		RPC('Teams.getOwnedInfoRPC'):onResult(onOwnedTeamInfo):exec()
	end,
	dataToCount = function(val) return val and 1 end,
	getAllowedAct = function(val) return not val, true, true end -- buy, sell, use
}
