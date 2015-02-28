---------------------
-- Local variables --
---------------------

local g_Wnd, g_Anim, g_Visible
local g_PosX, g_PosY = g_ScreenSize[1] - 260, (g_ScreenSize[2] - 280)/2
local g_Width = 250
local g_StatsView

--------------------------------
-- Local function definitions --
--------------------------------

local function SpInitGui()
	local h = StatsView.getHeight() + 30
	
	g_Wnd = guiCreateWindow(g_ScreenSize[1] + g_Width, g_PosY, g_Width, h, "Statistics", false)
	guiSetAlpha(g_Wnd, 0.8)
	guiSetVisible(g_Wnd, false)
	
	g_StatsView = StatsView.create(g_MyId or g_Me, g_Wnd, 10, 25, g_Width - 20, h - 35)
end

local function onAccountChange()
	if(g_StatsView) then
		g_StatsView:changeTarget(g_MyId or g_Me)
	end
end

local function SpInit()
	addEventHandler('main.onAccountChange', g_ResRoot, onAccountChange)

	addCommandHandler('StatsPanel', SpToggle, false, false)
	local key = getKeyBoundToCommand('StatsPanel') or 'F1'
	bindKey(key, 'down', 'StatsPanel')
	
	-- Me: 270, RoadRunner: 225
	--Debug.info('Height def-normal '..GUI.getFontHeight('default-normal')..' def-small '..GUI.getFontHeight('default-small')..' def-bold-small '..GUI.getFontHeight('default-bold-small')..' clear-norm '..GUI.getFontHeight('clear-normal')..' sa-hdr '..GUI.getFontHeight('sa-header'))
end

----------------------
-- Global functions --
----------------------

function SpToggle()
	if(not g_Wnd) then
		SpInitGui()
	end
	
	if(g_Anim) then
		g_Anim:remove()
	end
	
	if(g_Visible) then -- hide panel
		g_Anim = Animation.createAndPlay(g_Wnd,
			Animation.presets.guiMoveEx(g_ScreenSize[1] + g_Width, g_PosY, 500, 'InQuad'),
			Animation.presets.guiSetVisible(false))
		g_StatsView:hide()
	else -- show panel
		guiSetVisible(g_Wnd, true)
		g_Anim = Animation.createAndPlay(g_Wnd, Animation.presets.guiMoveEx(g_PosX, g_PosY, 500, 'InOutQuad'))
		g_StatsView:show()
		AchvActivate('Open Statistics Panel')
	end
	g_Visible = not g_Visible
end

addInitFunc(SpInit)
