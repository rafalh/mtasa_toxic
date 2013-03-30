--------------
-- Includes --
--------------

#include "include/internal_events.lua"

---------------------
-- Local variables --
---------------------

local g_Panel, g_ChangePwBtn
local g_EditFields = {}
local g_ChangedEdits = {}
local g_Profile = {}

local EditProfilePanel = {
	name = "Profile",
	img = "profile/icon.png",
	tooltip = "Edit your profile",
	width = 300,
	height = 360,
}

--------------------------------
-- Local function definitions --
--------------------------------

local function onAccountChange(accountName)
	if(g_ChangePwBtn) then
		guiSetEnabled(g_ChangePwBtn, accountName and true)
	end
	
	if(not accountName and g_ChangePwGui) then
		g_ChangePwGui:remove()
		g_ChangePwGui = false
	end
end

function EditProfilePanel.onShow(panel)
	g_Panel = panel
	
	for edit, v in pairs(g_ChangedEdits) do
		guiSetText(edit, g_Profile[g_EditFields[edit]] or "")
	end
	
	g_ChangedEdits = {}
	triggerServerInternalEvent($(EV_SYNC_ONCE_REQUEST), g_Me, {profile_fields = false, profile = g_MyId})
end

local function onSaveClick()
	local data = {}
	local changed = false
	
	for edit, v in pairs(g_ChangedEdits) do
		data[g_EditFields[edit]] = guiGetText(edit)
		changed = true
	end
	
	if(changed) then
		triggerServerInternalEvent($(EV_SET_PROFILE_REQUEST), g_Me, data)
	end
end

local function onEditChanged()
	g_ChangedEdits[source] = true
end

local function onSync(sync_tbl, name, arg, data)
	if(not g_Panel) then return end
	
	if(sync_tbl.profile_fields and sync_tbl.profile_fields[2]) then
		-- cleanup window
		for i, el in ipairs(getElementChildren(g_Panel)) do
			destroyElement(el)
		end
		
		local c = 0
		g_EditFields = {}
		g_ChangedEdits = {}
		
		local w, h = guiGetSize(g_Panel, false)
		local y = 10
		
		g_ChangePwBtn = guiCreateButton(10, 10, 120, 25, "Change password", false, g_Panel)
		addEventHandler("onClientGUIClick", g_ChangePwBtn, openChangePasswordGui, false)
		guiSetEnabled(g_ChangePwBtn, g_UserName and true)
		y = y + 35
		
		
		for i, cat in pairs(sync_tbl.profile_fields[2]) do
			local catLabel = guiCreateLabel(10, y, 100, 20, cat.name, false, g_Panel)
			guiSetFont(catLabel, "default-bold-small")
			y = y + 20
			
			for i, data in ipairs(cat) do
				local title = data.longname:sub(1, 1):upper()..data.longname:sub (2)
				guiCreateLabel(10, y+2, 100, 20, title..":", false, g_Panel)
				local editW = w - 120
				if(data.w and data.w < editW) then
					editW = data.w
				end
				local edit = guiCreateEdit(110, y, editW, 22, g_Profile[data.name] or "", false, g_Panel)
				if(data.type == "int") then
					guiSetProperty(edit, "ValidationString", "-?\\d*")
				elseif(data.type == "num") then
					guiSetProperty(edit, "ValidationString", "-?\\d*\\.?\\d*")
				end
				g_EditFields[edit] = data.name
				addEventHandler("onClientGUIChanged", edit, onEditChanged, false)
				c = c + 1
				y = y + 25
			end
			
			y = y + 10
		end
		
		local x = w - 80
		if(UpNeedsBackBtn()) then
			local btn = guiCreateButton(x, h - 35, 70, 25, "Back", false, g_Panel)
			addEventHandler("onClientGUIClick", btn, UpBack, false)
			x = x - 80
		end
		
		local btn = guiCreateButton(x, h - 35, 70, 25, "Save", false, g_Panel)
		addEventHandler("onClientGUIClick", btn, onSaveClick, false)
	end
	
	if(sync_tbl.profile and sync_tbl.profile[1] == g_MyId and sync_tbl.profile[2]) then
		g_Profile = sync_tbl.profile[2]
		for edit, field in pairs(g_EditFields) do
			guiSetText(edit, g_Profile[field] or "")
		end
	end
end

----------------------
-- Global variables --
----------------------

UpRegister(EditProfilePanel)

------------
-- Events --
------------

addInternalEventHandler($(EV_SYNC), onSync)
addEventHandler("main.onAccountChange", g_ResRoot, onAccountChange)
