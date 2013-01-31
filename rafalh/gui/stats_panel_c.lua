--------------
-- Includes --
--------------

#include "include/internal_events.lua"

---------------------
-- Local variables --
---------------------

local g_Wnd, g_Anim, g_Visible
local g_PosX, g_PosY = g_ScreenSize[1] - 230, (g_ScreenSize[2] - 280)/2
local g_Width, g_Height = 220, 250
local g_StatsView

--------------------------------
-- Local function definitions --
--------------------------------

local function SpInitGui()
	g_Wnd = guiCreateWindow(g_ScreenSize[1] + g_Width, g_PosY, g_Width, g_Height, "Statistics", false)
	guiSetAlpha(g_Wnd, 0.8)
	guiSetVisible(g_Wnd, false)
	
	g_StatsView = StatsView.create(g_MyId, g_Wnd, 10, 25, g_Width - 20, g_Height - 35)
end

local function SpInit()
	bindKey(g_ClientSettings.stats_panel_key, "up", openStatsPanel)
end

----------------------
-- Global functions --
----------------------

function openStatsPanel()
	if(not g_Wnd) then
		SpInitGui()
		AchvActivate("Open Statistics Panel")
	end
	
	if(g_Anim) then
		g_Anim:remove()
	end
	
	if(g_Visible) then -- hide panel
		g_Anim = Animation.createAndPlay(g_Wnd,
			Animation.presets.guiMoveEx(g_ScreenSize[1] + g_Width, g_PosY, 500, "InQuad"),
			Animation.presets.guiSetVisible(false))
		g_StatsView:hide()
	else -- show panel
		guiSetVisible(g_Wnd, true)
		g_Anim = Animation.createAndPlay(g_Wnd, Animation.presets.guiMoveEx(g_PosX, g_PosY, 500, "InOutQuad"))
		g_StatsView:show()
	end
	g_Visible = not g_Visible
end

------------
-- Events --
------------

addInternalEventHandler($(EV_CLIENT_INIT), SpInit)
