---------------------
-- Local variables --
---------------------

local g_Panel, g_ChangePwBtn, g_ChangeEmailBtn
local g_EditFields = {}
local g_ChangedEdits = {}

local EditProfilePanel = {
	name = "Profile",
	img = 'profile/icon.png',
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
		guiSetEnabled(g_ChangeEmailBtn, accountName and true)
	end
	
	if(not accountName) then
		closeChangePwGui()
		closeChangeEmailGui()
	end
end

local function onEditChanged()
	g_ChangedEdits[source] = true
end

local function onProfileFields(fields)
	local w, h = guiGetSize(g_Panel, false)
	local y = 45
	
	for i, cat in pairs(fields) do
		local catLabel = guiCreateLabel(10, y, 100, 20, cat.name, false, g_Panel)
		guiSetFont(catLabel, 'default-bold-small')
		y = y + 20
		
		for i, data in ipairs(cat) do
			local title = data.longname:sub(1, 1):upper()..data.longname:sub (2)
			guiCreateLabel(10, y+2, 100, 20, title..':', false, g_Panel)
			local editW = w - 120
			if(data.w and data.w < editW) then
				editW = data.w
			end
			local edit = guiCreateEdit(110, y, editW, 22, '', false, g_Panel)
			if(data.type == 'int') then
				guiSetProperty(edit, 'ValidationString', '-?\\d*')
			elseif(data.type == 'num') then
				guiSetProperty(edit, 'ValidationString', '-?\\d*\\.?\\d*')
			end
			g_EditFields[edit] = data
			addEventHandler('onClientGUIChanged', edit, onEditChanged, false)
			y = y + 25
		end
		
		y = y + 10
	end
end

local function onProfileData(profile)
	for edit, fieldInfo in pairs(g_EditFields) do
		guiSetText(edit, profile[fieldInfo.longname] or '')
	end
end

local function onSaveClick()
	local data = {}
	local changed = false
	
	for edit, v in pairs(g_ChangedEdits) do
		data[g_EditFields[edit].name] = guiGetText(edit)
		changed = true
	end
	
	if(changed) then
		RPC('setProfileReq', data):exec()
		g_ChangedEdits = {}
	end
end

local function initGui()
	local w, h = guiGetSize(g_Panel, false)
	local y = 10
	
	g_ChangePwBtn = guiCreateButton(10, 10, 120, 25, "Change password", false, g_Panel)
	addEventHandler('onClientGUIClick', g_ChangePwBtn, openChangePasswordGui, false)
	guiSetEnabled(g_ChangePwBtn, g_UserName and true)
	
	g_ChangeEmailBtn = guiCreateButton(140, 10, 120, 25, "Change e-mail", false, g_Panel)
	addEventHandler('onClientGUIClick', g_ChangeEmailBtn, openChangeEmailGui, false)
	guiSetEnabled(g_ChangeEmailBtn, g_UserName and true)
	y = y + 35
	
	RPC('getProfileFields'):onResult(onProfileFields):exec()
	
	local x = w - 80
	if(UpNeedsBackBtn()) then
		local btn = guiCreateButton(x, h - 35, 70, 25, "Back", false, g_Panel)
		addEventHandler('onClientGUIClick', btn, UpBack, false)
		x = x - 80
	end
	
	local btn = guiCreateButton(x, h - 35, 70, 25, "Save", false, g_Panel)
	addEventHandler('onClientGUIClick', btn, onSaveClick, false)
end

function EditProfilePanel.onShow(panel)
	if(not g_Panel) then
		g_Panel = panel
		initGui()
	end
	
	if(g_MyId) then
		RPC('getPlayerProfile', g_MyId):onResult(onProfileData):exec()
	end
end

UpRegister(EditProfilePanel)

------------
-- Events --
------------

addEventHandler('main.onAccountChange', g_ResRoot, onAccountChange)
