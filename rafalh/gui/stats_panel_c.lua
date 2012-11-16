--------------
-- Includes --
--------------

#include "include/internal_events.lua"

---------------------
-- Local variables --
---------------------

local g_TabPanel = nil
local g_CurrentTab
local g_TabsInfo = {}

--------------------------------
-- Local function definitions --
--------------------------------

local function onClientGUITabSwitched ( tab )
	if ( g_TabsInfo[tab] ) then
		g_TabsInfo[g_CurrentTab][3] ( g_CurrentTab ) -- onhide
		g_CurrentTab = tab
		g_TabsInfo[g_CurrentTab][2] ( g_CurrentTab ) -- onshow
	end
end

local function onClientInit ()
	bindKey ( g_ClientSettings.stats_panel_key, "up", openStatsPanel )
	
	g_TabPanel = guiCreateTabPanel ( g_ScreenSize[1] - 230, ( g_ScreenSize[2] - 280 )/2, 220, 280, false )
	guiSetVisible ( g_TabPanel, false )
	addEventHandler ( "onClientGUITabSwitched", g_TabPanel, onClientGUITabSwitched, false )
	
	for i, data in ipairs ( g_StatsPanelTabs ) do
		local tab = guiCreateTab ( data[1], g_TabPanel )
		g_TabsInfo[tab] = data
		if ( i == 1 ) then
			g_CurrentTab = tab
		end
		
		assert(type(data) == "table" and #data >= 2)
	end
end

----------------------
-- Global functions --
----------------------

function openStatsPanel ()
	if ( guiGetVisible ( g_TabPanel ) ) then -- hide panel
		GaFadeOut ( g_TabPanel, 200 )
		
		g_TabsInfo[g_CurrentTab][3] ( g_CurrentTab ) -- onhide
	else -- show panel
		GaFadeIn ( g_TabPanel, 200, 0.9 )
		
		g_TabsInfo[g_CurrentTab][2] ( g_CurrentTab ) -- onshow
	end
end

----------------------
-- Global variables --
----------------------

g_StatsPanelTabs = {}

------------
-- Events --
------------

addInternalEventHandler ( $(EV_CLIENT_INIT), onClientInit )
