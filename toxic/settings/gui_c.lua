--------------
-- Includes --
--------------

#include 'include/internal_events.lua'

-- Local variables

local g_Panel, g_ScrollPane
local g_SettingGui = {}
local g_Save = false

#SAVE_BTN = false

local SettingsPanel = {
	name = "Settings",
	img = 'settings/icon.png',
	tooltip = "Adjust settings to your needs",
	height = 420,
	prio = 90,
}

-- Code

function SettingsPanel.onSaveClick()
	for key, gui in pairs(g_SettingGui) do
		local item = Settings.localMap[key]
		if(item) then
			item.acceptGui(gui)
		end
	end
	
	g_Save = true
end

function SettingsPanel.createScrollPane(x, y, w, h, panel)
	g_ScrollPane = guiCreateScrollPane(x, y, w, h, false, panel)
	GUI.scrollPaneAddMouseWheelSupport(g_ScrollPane)
	
	local y = 0
	for key, item in ipairs(Settings.localSorted) do
		if(item.createGui) then
			local h, gui = item.createGui(g_ScrollPane, 0, y, w, not $(SAVE_BTN) and SettingsPanel.onSaveClick)
			if(h and gui) then
				g_SettingGui[item.name] = gui
				y = y + h
			end
		end
	end
end

function SettingsPanel.initGui(panel)
	local w, h = guiGetSize(panel, false)
	
	local paneH = h - 20
	
	local x = w - 90
	if(UpNeedsBackBtn()) then
		local btn = guiCreateButton(x, h - 35, 80, 25, "Back", false, panel)
		addEventHandler('onClientGUIClick', btn, UpBack, false)
		x = x - 90
		paneH = h - 50
	end
	
# if(SAVE_BTN) then
		local btn = guiCreateButton(x, h - 35, 80, 25, "Save", false, panel)
		addEventHandler('onClientGUIClick', btn, SettingsPanel.onSaveClick, false)
		paneH = h - 50
# end
	
	SettingsPanel.createScrollPane(10, 10, w - 20, paneH, panel)
end

function invalidateSettingsGui()
	--Debug.info('invalidateSettingsGui')
	if(not g_Panel) then return end
	
	destroyElement(g_ScrollPane)
	g_SettingGui = {}
	
	if(guiGetVisible(g_Panel)) then
		SettingsPanel.createScrollPane(g_Panel)
	else
		g_Panel = false
	end
end

function SettingsPanel.onShow(panel)
	if(not g_Panel) then
		g_Panel = panel
		SettingsPanel.initGui(g_Panel)
	end
end

function SettingsPanel.onHide(panel)
	if(g_Save) then
		Settings.save()
		g_Save = false
	end
end

addInitFunc(function()
	UpRegister(SettingsPanel)
end)
