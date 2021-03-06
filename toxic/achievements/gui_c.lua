
#include 'include/internal_events.lua'

local AchievementsPanel = {
	name = "Achievements",
	img = 'achievements/img/icon.png',
	tooltip = "Check your achievements list",
	prio = -90,
}

local g_LockedStyle = {}
g_LockedStyle.normal = {clr = {196, 196, 196}, a = 0.8, fnt = 'default-normal'}
g_LockedStyle.hover = {clr = {255, 255, 255}, a = 1, fnt = 'default-normal'}
g_LockedStyle.active = g_LockedStyle.normal

local g_UnlockedStyle = {}
g_UnlockedStyle.normal = {clr = {255, 196, 0}, a = 0.8, fnt = 'default-bold-small'}
g_UnlockedStyle.hover = {clr = {255, 255, 0}, a = 1, fnt = 'default-bold-small'}
g_UnlockedStyle.active = g_UnlockedStyle.normal

local g_Achievements = {}
local g_IdToAchievement = {}
local g_NameToAchv = {}
local g_List, g_AchvCountLabel
local g_ActiveCount = 0

addEvent('main.onAchvList', true)
addEvent('main.onAchvChange', true)

local function AchvInitGui(panel)
	local w, h = guiGetSize(panel, false)
	
	local achvCntStr = MuiGetMsg("Unlocked achievements: %u/%u"):format(g_ActiveCount, #g_Achievements)
	g_AchvCountLabel = guiCreateLabel(10, 10, 200, 15, achvCntStr, false, panel)
	guiLabelSetColor(g_AchvCountLabel, 255, 196, 0)
	guiSetFont(g_AchvCountLabel, 'default-bold-small')
	
	local listSize = {w - 10, h - 45}
	if(UpNeedsBackBtn()) then
		local btn = guiCreateButton(w - 80, h - 35, 70, 25, "Back", false, panel)
		addEventHandler('onClientGUIClick', btn, UpBack, false)
		listSize[2] = listSize[2] - 35
	end
	
	g_List = ListView.create({5, 30}, listSize, panel, {102, 90}, nil, nil, true)
	
	for i, achv in ipairs(g_Achievements) do
		local img = achv.active and 'achievements/img/unlocked.png' or 'achievements/img/locked.png'
		local style = achv.active and g_UnlockedStyle or g_LockedStyle
		g_List:addItem(MuiGetMsg(achv.name)..'\n('..formatMoney(achv.prize)..')', img, i, style)
	end
	
	if(UpNeedsBackBtn()) then
		local btn = guiCreateButton(w - 80, h - 35, 70, 25, "Back", false, panel)
		addEventHandler('onClientGUIClick', btn, UpBack, false)
	end
	
	--triggerServerEvent('main.onAchvListReq', g_ResRoot)
end

local function AchvUpdateGui()
	if(not g_List) then return end
	local prof = DbgPerf()
	
	local achvCntStr = MuiGetMsg("Unlocked achievements: %u/%u"):format(g_ActiveCount, #g_Achievements)
	guiSetText(g_AchvCountLabel, achvCntStr)
	
	for i, achv in ipairs(g_Achievements) do
		local img = achv.active and 'achievements/img/unlocked.png' or 'achievements/img/locked.png'
		local style = achv.active and g_UnlockedStyle or g_LockedStyle
		g_List:setItemImg(i, img)
		g_List:setItemStyle(i, style)
	end
	prof:cp('Achievements update')
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
	--Debug.info('AchvOnList')
	
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
	
	if(not g_SharedState.accountId) then return end
	
	if(achv.active) then
		--Debug.info('Failed to activate client achievement '..name)
		return -- nothing to do
	end
	triggerServerEvent('main.onAchvActivate', g_ResRoot, achv.name)
end

function AchievementsPanel.onShow(panel)
	if(not g_List) then
		AchvInitGui(panel)
	end
end

addInitFunc(function()
	addEventHandler('main.onAchvList', g_ResRoot, AchvOnList)
	addEventHandler('main.onAchvChange', g_ResRoot, AchvOnChange)
	
	UpRegister(AchievementsPanel)
end)
