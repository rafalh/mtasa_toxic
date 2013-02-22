---------------------
-- Local variables --
---------------------

local g_Gui = nil
local g_Stats = {
	-- field		col name		col w	desc	func
	{"name",		"Player name",	0.20,	false},
	{"points", 		"Points",		0.10,	true,	formatNumber},
	{"cash",		"Cash",			0.14,	true,	formatMoney},
	{"time_here",	"Playtime",		0.12,	true,	function(n) return formatTimePeriod(n, 0) end},
	{"toptimes_count", "Top times", 0.09,	true,	formatNumber},
	{"dmVictories",	"DM Vict",		0.08,	true,	formatNumber},
	{"ddVictories",	"DD Vict",		0.08,	true,	formatNumber},
	{"raceVictories", "Race Vict",	0.08,	true,	formatNumber},
	
}
	
local g_Col = {}
local g_SearchBox, g_Filter = false, ""
local g_IgnoreFilterChange = false
local g_RefreshTimer

local PlayersPanel = {
	name = "Players list",
	img = "img/userpanel/users.png",
	tooltip = "Read more about other players",
	width = 620,
}

--------------------------------
-- Local function definitions --
--------------------------------

local function refreshData()
	if(g_RefreshTimer) then
		g_RefreshTimer = false
	end
	
	local online = guiCheckBoxGetSelected(g_Gui.online)
	local orderByIdx = guiComboBoxGetSelected(g_Gui.sortBox)
	local desc = guiCheckBoxGetSelected(g_Gui.desc)
	local orderBy = orderByIdx > 0 and g_Stats[orderByIdx][1]
	triggerServerEvent("main_onPlayersListReq", g_ResRoot, g_Filter, orderBy, desc, 18, 0, online)
end

local function invalidateData()
	if(g_RefreshTimer) then
		resetTimer(g_RefreshTimer)
	else
		g_RefreshTimer = setTimer(refreshData, 500, 1)
	end
end

local function onDoubleClickPlayer ()
	local row, col = guiGridListGetSelectedItem(g_Gui.list)
	local id = row and guiGridListGetItemData(g_Gui.list, row, g_Col.idx)
	if(id) then
		local name = guiGridListGetItemText(g_Gui.list, row, g_Col.name)
		ProfileView.create(id, name)
	end
end

local function onFilterFocus()
	if(g_Filter == "") then
		guiSetText(g_SearchBox, "")
	end
	g_IgnoreFilterChange = false
end

local function onFilterBlur()
	g_IgnoreFilterChange = true
	if(g_Filter == "") then
		guiSetText(g_SearchBox, MuiGetMsg("Search..."))
	end
end

local function onFilterChange()
	if(g_IgnoreFilterChange) then return end
	g_Filter = guiGetText(source)
	invalidateData()
end

local function onOrderChange()
	invalidateData()
	local orderByIdx = guiComboBoxGetSelected(g_Gui.sortBox)
	local desc = orderByIdx > 0 and g_Stats[orderByIdx][4]
	guiCheckBoxSetSelected(g_Gui.desc, desc)
end

local function initGui(panel)
	g_Gui = {}
	
	local w, h = guiGetSize(panel, false)
	
	guiCreateStaticImage(10, 10, 32, 32, "img/userpanel/users.png", false, panel)
	
	g_SearchBox = guiCreateEdit(50, 10, 150, 25, MuiGetMsg("Search..."), false, panel)
	addEventHandler("onClientGUIFocus", g_SearchBox, onFilterFocus, false)
	addEventHandler("onClientGUIBlur", g_SearchBox, onFilterBlur, false)
	addEventHandler("onClientGUIChanged", g_SearchBox, onFilterChange, false)
	
	g_Gui.online = guiCreateCheckBox(50, 40, w - 20, 15, "Players online only", true, false, panel)
	addEventHandler("onClientGUIClick", g_Gui.online, invalidateData, false)
	
	guiCreateLabel(220, 12, 40, 20, "Sort:", false, panel)
	g_Gui.sortBox = guiCreateComboBox(260, 10, 120, 200, "", false, panel)
	guiComboBoxAddItem(g_Gui.sortBox, "-")
	for i, data in ipairs(g_Stats) do
		guiComboBoxAddItem(g_Gui.sortBox, data[2])
	end
	guiComboBoxSetSelected(g_Gui.sortBox, 0)
	addEventHandler("onClientGUIComboBoxAccepted", g_Gui.sortBox, onOrderChange, false)
	
	g_Gui.desc = guiCreateCheckBox(390, 10, 100, 15, "descending", false, false, panel)
	addEventHandler("onClientGUIClick", g_Gui.desc, invalidateData, false)
	
	local btn = guiCreateButton(w - 80, 10, 70, 25, "Back", false, panel)
	addEventHandler("onClientGUIClick", btn, UpBack, false)
	
	g_Gui.list = guiCreateGridList(10, 60, w - 20, h - 65, false, panel)
	-- disable sorting because it breaks adding rows (MTA 1.3)
	guiGridListSetSortingEnabled(g_Gui.list, false)
	
	g_Col.idx = guiGridListAddColumn(g_Gui.list, "#", 0.06)
	
	for i, data in ipairs(g_Stats) do
		g_Col[data[1]] = guiGridListAddColumn(g_Gui.list, data[2], data[3])
	end
	
	addEventHandler("onClientGUIDoubleClick", g_Gui.list, onDoubleClickPlayer, false)
end

function PlayersPanel.onShow(panel)
	if(not g_Gui) then
		initGui(panel)
	end
	
	refreshData()
end

local function onPlayersList(rows, cnt)
	guiGridListClear(g_Gui.list)
	
	for i, data in ipairs(rows) do
		local row = guiGridListAddRow(g_Gui.list)
		
		guiGridListSetItemText(g_Gui.list, row, g_Col.idx, i, false, true)
		guiGridListSetItemData(g_Gui.list, row, g_Col.idx, data.player)
		
		for i, sdata in ipairs(g_Stats) do
			local col = g_Col[sdata[1]]
			local str = data[sdata[1]]
			if(sdata[5]) then
				str = sdata[5](str)
			end
			guiGridListSetItemText(g_Gui.list, row, col, str, false, false)
		end
	end
end

----------------------
-- Global variables --
----------------------

UpRegister(PlayersPanel)

------------
-- Events --
------------

addEvent("main_onPlayersList", true)
addEventHandler("main_onPlayersList", g_ResRoot, onPlayersList)
