
#include "include/internal_events.lua"

local AchievementsPanel = {
	name = "Achievements",
	img = "achievements/img/icon.png",
	tooltip = "Check your achievements list",
}

local g_LockedStyle = {}
g_LockedStyle.normal = {clr = {196, 196, 196}, a = 0.8, fnt = "default-normal"}
g_LockedStyle.hover = {clr = {255, 255, 255}, a = 1, fnt = "default-normal"}
g_LockedStyle.active = g_LockedStyle.normal

local g_UnlockedStyle = {}
g_UnlockedStyle.normal = {clr = {255, 196, 0}, a = 0.8, fnt = "default-bold-small"}
g_UnlockedStyle.hover = {clr = {255, 255, 0}, a = 1, fnt = "default-bold-small"}
g_UnlockedStyle.active = g_UnlockedStyle.normal

local g_Achievements = {}
local g_IdToAchievement = {}
local g_NameToAchv = {}
local g_List, g_AchvCountLabel
local g_ActiveCount = 0

addEvent("main.onAchvList", true)
addEvent("main.onAchvChange", true)

local function AchvInitGui(panel)
	local w, h = guiGetSize(panel, false)
	
	guiCreateStaticImage(10, 0, 40, 40, "img/beta.png", false, panel)
	
	local achvCntStr = MuiGetMsg("Unlocked achievements: %u/%u"):format(g_ActiveCount, #g_Achievements)
	g_AchvCountLabel = guiCreateLabel(60, 10, 200, 15, achvCntStr, false, panel)
	guiLabelSetColor(g_AchvCountLabel, 255, 196, 0)
	guiSetFont(g_AchvCountLabel, "default-bold-small")
	
	g_List = ListView.create({10, 30}, {w - 20, h - 70}, panel, {105, 90})
	
	for i, achv in ipairs(g_Achievements) do
		local img = achv.active and "achievements/img/icon.png" or "achievements/img/locked.png"
		local style = achv.active and g_UnlockedStyle or g_LockedStyle
		g_List:addItem(achv.name.."\n("..formatMoney(achv.prize)..")", img, i, style)
	end
	
	local btn = guiCreateButton(w - 80, h - 35, 70, 25, "Back", false, panel)
	addEventHandler("onClientGUIClick", btn, UpBack, false)
	
	--triggerServerEvent("main.onAchvListReq", g_ResRoot)
end

local function AchvUpdateGui()
	if(not g_List) then return end
	
	local achvCntStr = MuiGetMsg("Unlocked achievements: %u/%u"):format(g_ActiveCount, #g_Achievements)
	guiSetText(g_AchvCountLabel, achvCntStr)
	
	for i, achv in ipairs(g_Achievements) do
		local img = achv.active and "achievements/img/icon.png" or "achievements/img/locked.png"
		local style = achv.active and g_UnlockedStyle or g_LockedStyle
		g_List:setItemImg(i, img)
		g_List:setItemStyle(i, style)
	end
end

local function AchvSetActive(id)
	local achv = g_IdToAchievement[id]
	if(achv.active) then return end
	
	achv.active = true
	g_ActiveCount = g_ActiveCount + 1
	
	local achvUnlockedStr = MuiGetMsg("Achievement unlocked: %s! %s have been added to your cash."):format(achv.name, formatMoney(achv.prize))
	outputChatBox(achvUnlockedStr, 255, 255, 0)
end

local function AchvOnList(achvTbl)
	--outputDebugString("AchvOnList", 3)
	
	for i, achv in ipairs(g_Achievements) do
		achv.active = false
	end
	
	for i, achvId in ipairs(achvTbl) do
		local achv = g_IdToAchievement[achvId]
		achv.active = true
	end
	
	g_ActiveCount = #achvTbl
	AchvUpdateGui()
end

local function AchvOnChange(achvTbl)
	for i, achvId in ipairs(achvTbl) do
		AchvSetActive(achvId, true)
	end
	AchvUpdateGui()
end

function AchvRegister(achv)
	achv.active = false
	table.insert(g_Achievements, achv)
	assert(not g_IdToAchievement[achv.id])
	g_IdToAchievement[achv.id] = achv
	g_NameToAchv[achv.name] = achv
end

function AchvActivate(name)
	local achv = g_NameToAchv[name]
	assert(achv and achv.client)
	
	if(not g_MyId) then return end
	
	if(achv.active) then
		--outputDebugString("Failed to activate client achievement "..name, 3)
		return -- nothing to do
	end
	triggerServerEvent("main.onAchvActivate", g_ResRoot, achv.name)
end

function AchievementsPanel.onShow(panel)
	if(not g_List) then
		AchvInitGui(panel)
	end
end

UpRegister(AchievementsPanel)

addEventHandler("main.onAchvList", g_ResRoot, AchvOnList)
addEventHandler("main.onAchvChange", g_ResRoot, AchvOnChange)
