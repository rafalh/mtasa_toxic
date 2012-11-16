--------------
-- Includes --
--------------

#include "include/internal_events.lua"

---------------------
-- Local variables --
---------------------

local g_Tab = nil
local g_EditFields = {}
local g_ChangedEdits = {}
local g_Profile = {}
local g_Gui = {}

local EditProfilePanel = {
	name = "Profile",
	img = "img/userpanel/profile.png",
	width = 300,
	height = 300,
}

--------------------------------
-- Local function definitions --
--------------------------------

function EditProfilePanel.onShow ( panel )
	g_Tab = panel
	
	for edit, v in pairs ( g_ChangedEdits ) do
		guiSetText ( edit, g_Profile[g_EditFields[edit]] or "" )
	end
	
	g_ChangedEdits = {}
	triggerServerInternalEvent ( $(EV_SYNC_ONCE_REQUEST), g_Me, { profile_fields = false, profile = g_MyId } )
end

local function onSaveClick ()
	local data = {}
	local changed = false
	
	for edit, v in pairs ( g_ChangedEdits ) do
		data[g_EditFields[edit]] = guiGetText ( edit )
		changed = true
	end
	
	if ( changed ) then
		triggerServerInternalEvent ( $(EV_SET_PROFILE_REQUEST), g_Me, data )
	end
end

local function onEditChanged ()
	g_ChangedEdits[source] = true
end

local function onSync ( sync_tbl, name, arg, data )
	if ( not g_Tab ) then return end
	
	if ( sync_tbl.profile_fields and sync_tbl.profile_fields[2] ) then
		-- cleanup window
		for i, el in ipairs ( getElementChildren ( g_Tab ) ) do
			destroyElement ( el )
		end
		
		local c = 0
		g_EditFields = {}
		g_ChangedEdits = {}
		
		local w, h = guiGetSize ( g_Tab, false )
		
		for field, data in pairs ( sync_tbl.profile_fields[2] ) do
			local title = data.longname:sub ( 1, 1 ):upper ()..data.longname:sub ( 2 )
			local y = 10 + ( data.i - 1 ) * 20
			guiCreateLabel ( 10, y, 90, 20, title..":", false, g_Tab )
			local edit = guiCreateEdit ( 90, y, w - 100, 20, g_Profile[field] or "", false, g_Tab )
			g_EditFields[edit] = field
			addEventHandler ( "onClientGUIChanged", edit, onEditChanged, false )
			c = c + 1
		end
		
		local btn = guiCreateButton ( ( w - 50 ) / 2, 35 + c * 20, 50, 20, "Save", false, g_Tab )
		addEventHandler ( "onClientGUIClick", btn, onSaveClick, false )
	end
	
	if ( sync_tbl.profile and sync_tbl.profile[1] == g_MyId and sync_tbl.profile[2] ) then
		g_Profile = sync_tbl.profile[2]
		for edit, field in pairs ( g_EditFields ) do
			guiSetText ( edit, g_Profile[field] or "" )
		end
	end
end

----------------------
-- Global variables --
----------------------

UpRegister ( EditProfilePanel )

------------
-- Events --
------------

addInternalEventHandler ( $(EV_SYNC), onSync )
