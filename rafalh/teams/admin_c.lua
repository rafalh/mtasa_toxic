local g_GUI = false

local function closeTeamsAdmin()
	g_GUI:destroy()
	g_GUI = false
	guiSetInputEnabled(false)
end

function openTeamsAdmin()
	g_GUI = GUI.create("teamsAdmin")
	addEventHandler("onClientGUIClick", g_GUI.close, closeTeamsAdmin, false)
	guiSetInputEnabled(true)
end
