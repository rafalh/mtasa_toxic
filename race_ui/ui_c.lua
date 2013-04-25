local g_Root = root

-- Utils

function resAdjust(num)
	if not g_ScreenWidth then
		g_ScreenWidth, g_ScreenHeight = guiGetScreenSize()
	end
	if g_ScreenWidth < 1280 then
		return math.floor(num*g_ScreenWidth/1280)
	else
		return num
	end
end

function clamp( lo, value, hi )
    return math.max( lo, math.min( value, hi ) )
end

function math.clamp(low,value,high)
    return math.max(low,math.min(value,high))
end

function showHUD(show)
	for i,name in ipairs({ 'ammo', 'area_name', 'armour', 'breath', 'clock', 'health', 'money', 'vehicle_name', 'weapon' }) do
		showPlayerHudComponent(name, show)
	end
end

function showGUIComponents(...)
	for i,name in ipairs({...}) do
		if g_dxGUI[name] then
			g_dxGUI[name]:visible(true)
		elseif type(g_GUI[name]) == 'table' then
			g_GUI[name]:show()
		else
			guiSetVisible(g_GUI[name], true)
		end
	end
end

function hideGUIComponents(...)
	for i,name in ipairs({...}) do
		if g_dxGUI[name] then
			g_dxGUI[name]:visible(false)
		elseif type(g_GUI[name]) == 'table' then
			g_GUI[name]:hide()
		else
			guiSetVisible(g_GUI[name], false)
		end
	end
end

-- race_client

g_ScrW, g_ScrH = guiGetScreenSize()
g_Images = {
	title = { path = "img/title.jpg", w = 0.8*g_ScrH, h = 600/800*0.8*g_ScrH },
	specprev = { path = "img/specprev.png", w = 82, h = 82/167*180 },
	specprev_hi = { path = "img/specprev_hi.png", w = 82, h = 82/167*180 },
	specnext = { path = "img/specnext.png", w = 82, h = 82/167*180 },
	specnext_hi = { path = "img/specnext_hi.png", w = 82, h = 82/167*180 },
	timeleft = { path = "img/timeleft.png", w = 100, h = 100/100*24 },
	travelling = { path = "img/travelling.png", w = 640, h = 480 },
	hurry = { path = "img/hurry.png", w = resAdjust(370), h = resAdjust(112) },
	loading = { path = "img/loading.gif" }
}

local g_HudKeyColor = "#00AA00"
local g_HudValueColor = "#FFFFFF"

addEvent("race.onTravelingStart")
addEvent("onClientMapStarting")

-------------------------------------------------------
-- Title screen - Shown when player first joins the game
-------------------------------------------------------
TitleScreen = {}
TitleScreen.startTime = 0

function TitleScreen.init()
	local screenWidth, screenHeight = guiGetScreenSize()
	local adjustY = math.clamp( -30, -15 + (-30- -15) * (screenHeight - 480)/(900 - 480), -15 );
	g_GUI['titleImage'] = guiCreateStaticImage((screenWidth-g_Images.title.w)/2, (screenHeight-g_Images.title.h)/2+adjustY, g_Images.title.w, g_Images.title.h, g_Images.title.path, false)
	g_dxGUI['titleText1'] = dxText:create('', 30, screenHeight-100, false, 'bankgothic', 0.70, 'left' )
	g_dxGUI['titleText2'] = dxText:create('', 120, screenHeight-100, false, 'bankgothic', 0.70, 'left' )
	g_dxGUI['titleText1']:text(	'KEYS: \n' ..
								'F4 \n' ..
								'F5 \n' ..
								'K' )
	g_dxGUI['titleText2']:text(	'\n' ..
								'- TRAFFIC ARROWS \n' ..
								'- TOP TIMES \n' ..
								'- RETRY' )
	hideGUIComponents('titleImage','titleText1','titleText2')
end

function TitleScreen.show()
    showGUIComponents('titleImage','titleText1','titleText2')
	guiMoveToBack(g_GUI['titleImage'])
    TitleScreen.startTime = getTickCount()
    TitleScreen.bringForward = 0
    addEventHandler('onClientRender', g_Root, TitleScreen.update)
end

function TitleScreen.update()
    local secondsLeft = TitleScreen.getTicksRemaining() / 1000
    local alpha = math.min(1,math.max( secondsLeft ,0))
    guiSetAlpha(g_GUI['titleImage'], alpha)
    g_dxGUI['titleText1']:color(220,220,220,255*alpha)
    g_dxGUI['titleText2']:color(220,220,220,255*alpha)
    if alpha == 0 then
        hideGUIComponents('titleImage','titleText1','titleText2')
        removeEventHandler('onClientRender', g_Root, TitleScreen.update)
	end
end

function TitleScreen.getTicksRemaining()
    return math.max( 0, TitleScreen.startTime - TitleScreen.bringForward + 10000 - getTickCount() )
end

-- Start the fadeout as soon as possible
function TitleScreen.bringForwardFadeout(maxSkip)
    local ticksLeft = TitleScreen.getTicksRemaining()
    local bringForward = ticksLeft - 1000
    if bringForward > 0 then
        TitleScreen.bringForward = math.min(TitleScreen.bringForward + bringForward,maxSkip)
    end
end
-------------------------------------------------------


-------------------------------------------------------
-- Travel screen - Message for client feedback when loading maps
-------------------------------------------------------
TravelScreen = {}
TravelScreen.startTime = 0

function TravelScreen.init()
    local screenWidth, screenHeight = guiGetScreenSize()
    g_GUI['travelImage']   = guiCreateStaticImage((screenWidth-g_Images.travelling.w)/2, (screenHeight-g_Images.travelling.h)/2-70, g_Images.travelling.w, g_Images.travelling.h, g_Images.travelling.path, false, nil)
	g_dxGUI['travelText1'] = dxText:create('Travelling to', screenWidth/2, (screenHeight+g_Images.travelling.h)/2-40, false, 'bankgothic', 0.60, 'center' )
	g_dxGUI['travelText2'] = dxText:create('', screenWidth/2, (screenHeight+g_Images.travelling.h)/2-10, false, 'bankgothic', 0.70, 'center' )
	g_dxGUI['travelText3'] = dxText:create('', screenWidth/2, (screenHeight+g_Images.travelling.h)/2+20, false, 'bankgothic', 0.70, 'center' )
    g_dxGUI['travelText1']:color(240,240,240)
    hideGUIComponents('travelImage', 'travelText1', 'travelText2', 'travelText3')
end

function TravelScreen.show( mapName, authorName )
    TravelScreen.startTime = getTickCount()
    g_dxGUI['travelText2']:text(mapName) 
	g_dxGUI['travelText3']:text(authorName and "Author: " .. authorName or "")
    showGUIComponents('travelImage', 'travelText1', 'travelText2', 'travelText3')
	guiMoveToBack(g_GUI['travelImage'])
end

function TravelScreen.hide()
    hideGUIComponents('travelImage', 'travelText1', 'travelText2', 'travelText3')
end

function TravelScreen.getTicksRemaining()
    return math.max( 0, TravelScreen.startTime + 3000 - getTickCount() )
end
-------------------------------------------------------

addEventHandler("onClientResourceStart", resourceRoot, function()
	-- Create GUI
	g_dxGUI = {
			ranknum = dxText:create('1', g_ScrW - 60, g_ScrH - 95, false, 'bankgothic', 2, 'right'),
			ranksuffix = dxText:create('st', g_ScrW - 40, g_ScrH - 86, false, 'bankgothic', 1),
			checkpoint = dxText:create('0/0', g_ScrW - 15, g_ScrH - 54, false, 'bankgothic', 0.8, 'right'),
			timepassed = dxText:create('0:00:00', g_ScrW - 10, g_ScrH - 25, false, 'bankgothic', 0.7, 'right'),
			mapdisplay = dxText:create('Map: '..g_HudValueColor..'none', 2, g_ScrH - dxGetFontHeight(0.7, 'bankgothic')*2.00, false, 'bankgothic', 0.7, 'left'),
			nextdisplay = dxText:create('Next map: '..g_HudValueColor..'not set', 2, g_ScrH - dxGetFontHeight(0.7, 'bankgothic')*1.25, false, 'bankgothic', 0.7, 'left'),
			spectators = dxText:create('Spectators: '..g_HudValueColor..'none', 2, g_ScrH - dxGetFontHeight(0.7, 'bankgothic')*0.5, false, 'bankgothic', 0.7, 'left'),
		}
		g_dxGUI.ranknum:type('stroke', 2, 0, 0, 0, 255)
		g_dxGUI.ranksuffix:type('stroke', 2, 0, 0, 0, 255)
		g_dxGUI.checkpoint:type('stroke', 1, 0, 0, 0, 255)
		g_dxGUI.timepassed:type('stroke', 1, 0, 0, 0, 255)
		g_dxGUI.mapdisplay:wordWrap(false)
		g_dxGUI.mapdisplay:colorCoded(true)
		g_dxGUI.mapdisplay:color(getColorFromString(g_HudKeyColor))
		g_dxGUI.nextdisplay:wordWrap(false)
		g_dxGUI.nextdisplay:colorCoded(true)
		g_dxGUI.nextdisplay:color(getColorFromString(g_HudKeyColor))
		g_dxGUI.spectators:wordWrap(false)
		g_dxGUI.spectators:color(getColorFromString(g_HudKeyColor))
		g_dxGUI.spectators:colorCoded(true)
		g_GUI = {
			timeleftbg = guiCreateStaticImage(g_ScrW/2-g_Images.timeleft.w/2, 15, g_Images.timeleft.w, g_Images.timeleft.h, g_Images.timeleft.path, false, nil),
			timeleft = guiCreateLabel(g_ScrW/2-108/2, 19, 108, 30, '', false),
		}
		guiSetFont(g_GUI.timeleft, 'default-bold-small')
		guiLabelSetHorizontalAlign(g_GUI.timeleft, 'center')
		
		hideGUIComponents('timeleftbg', 'timeleft', 'ranknum', 'ranksuffix', 'checkpoint', 'timepassed')
		
		-- Init presentation screens
        TitleScreen.init()
        TravelScreen.init()
		
		-- Show title screen now
        TitleScreen.show()
end)

addEventHandler("onClientResourceStop", resourceRoot, function()
	showHUD(true)
end)

addEventHandler("race.onTravelingStart", root, function(mapName, authorName)
	TravelScreen.show(mapName, authorName)
end)

addEventHandler("onClientMapStarting", root, function(mapInfo)
	g_dxGUI.mapdisplay:text("Map: "..g_HudValueColor..mapInfo.name)
	showHUD(false)
	
	-- GUI
	g_dxGUI.timepassed:text('0:00:00')
	showGUIComponents('timepassed')
	hideGUIComponents('timeleftbg', 'timeleft')
	if ranked then
		showGUIComponents('ranknum', 'ranksuffix')
	else
		hideGUIComponents('ranknum', 'ranksuffix')
	end
	
	g_CheckpointsCount = mapInfo.cpCount
	if mapInfo.cpCount > 0 then
		showGUIComponents('checkpoint')
	else
		hideGUIComponents('checkpoint')
	end
	
	-- Min 3 seconds on travel message
    local delay = TravelScreen.getTicksRemaining()
    delay = math.max(50,delay)
    setTimer(TravelScreen.hide,delay,1)

    -- Delay readyness until after title
    TitleScreen.bringForwardFadeout(3000)
    delay = delay + math.max( 0, TitleScreen.getTicksRemaining() - 1500 )
end)

addEventHandler("onClientMapStopping", root, function()
	removeEventHandler('onClientRender', g_Root, updateTime)
	
	if g_GUI then
		hideGUIComponents('timeleftbg', 'timeleft', 'ranknum', 'ranksuffix', 'checkpoint', 'timepassed')
		if g_GUI.hurry then
			Animation.createAndPlay(g_GUI.hurry, Animation.presets.guiFadeOut(500), destroyElement)
			g_GUI.hurry = nil
		end
	end
end)

addEventHandler("race.onRaceLaunch", root, function(duration)
	if type(duration) == 'number' then
		showGUIComponents('timeleftbg', 'timeleft')
		guiLabelSetColor(g_GUI.timeleft, 255, 255, 255)
		g_Duration = duration
		addEventHandler('onClientRender', g_Root, updateTime)
	end
end)

function updateTime()
	local tick = getTickCount()
	local msPassed = tick - g_StartTick
	if not isPlayerFinished(g_Me) then
		g_dxGUI.timepassed:text(msToTimeStr(msPassed))
	end
	local timeLeft = g_Duration - msPassed
	guiSetText(g_GUI.timeleft, msToTimeStr(timeLeft > 0 and timeLeft or 0))
	if g_HurryDuration and g_GUI.hurry == nil and timeLeft <= g_HurryDuration then
		startHurry()
	end
end

addEventHandler("onClientPlayerOutOfTime", root, function()
	removeEventHandler('onClientRender', root, updateTime)
	guiSetText(g_GUI.timeleft, msToTimeStr(0))
	if g_GUI.hurry then
		Animation.createAndPlay(g_GUI.hurry, Animation.presets.guiFadeOut(500), destroyElement)
		g_GUI.hurry = nil
	end
end)

addEvent ( "onClientSetNextMap", true )
addEventHandler ( "onClientSetNextMap", root, function ( mapName )
	g_NextMap = mapName
	g_dxGUI.nextdisplay:text ( "Next map: "..g_HudValueColor..( mapName or "not set" ) )
end )

addEvent("onClientSetSpectators", true)
addEventHandler ( "onClientSetSpectators", root, function ( spectatorsList )
	g_dxGUI.spectators:text ( "Spectators: "..g_HudValueColor..(spectatorsList or "none") )
end )

addEventHandler("race.onStartHurry", root, function(finished)
	if not finished then
		local screenWidth, screenHeight = guiGetScreenSize()
		g_GUI.hurry = guiCreateStaticImage(screenWidth/2 - g_Images.hurry.w/2, screenHeight - g_Images.hurry.h - 40, g_Images.hurry.w, g_Images.hurry.h, g_Images.hurry.path, false, nil)
		guiSetAlpha(g_GUI.hurry, 0)
		Animation.createAndPlay(g_GUI.hurry, Animation.presets.guiFadeIn(800))
		Animation.createAndPlay(g_GUI.hurry, Animation.presets.guiPulse(1000))
	end
	guiLabelSetColor(g_GUI.timeleft, 255, 0, 0)
end)

local Spectate = {}

addEventHandler("onClientNotifySpectate", root, function(enabled)
	if(enabled) then
		local screenWidth, screenHeight = guiGetScreenSize()
		g_GUI.specprev = guiCreateStaticImage(screenWidth/2 - 100 - g_Images.specprev.w, screenHeight - 123, g_Images.specprev.w, g_Images.specprev.h, g_Images.specprev.path, false, nil)
		g_GUI.specprevhi = guiCreateStaticImage(screenWidth/2 - 100 - g_Images.specprev_hi.w, screenHeight - 123, g_Images.specprev_hi.w, g_Images.specprev_hi.h, g_Images.specprev_hi.path, false, nil)
		g_GUI.specnext = guiCreateStaticImage(screenWidth/2 + 100, screenHeight - 123, g_Images.specprev.w, g_Images.specprev.h, g_Images.specnext.path, false, nil)
		g_GUI.specnexthi = guiCreateStaticImage(screenWidth/2 + 100, screenHeight - 123, g_Images.specprev.w, g_Images.specprev.h, g_Images.specnext_hi.path, false, nil)
		g_GUI.speclabel = guiCreateLabel(screenWidth/2 - 100, screenHeight - 100, 200, 70, '', false)
		
		Spectate.updateGuiFadedOut()
		
		guiLabelSetHorizontalAlign(g_GUI.speclabel, 'center')
		hideGUIComponents('specprevhi', 'specnexthi')
	else
		for i,name in ipairs({'specprev', 'specprevhi', 'specnext', 'specnexthi', 'speclabel'}) do
			if g_GUI[name] then
				destroyElement(g_GUI[name])
				g_GUI[name] = nil
			end
		end
	end
end)

function Spectate.updateGuiFadedOut()
	if g_GUI and g_GUI.specprev then
		if Spectate.fadedout then
			setGUIComponentsVisible({ specprev = false, specnext = false, speclabel = false })
		else
			setGUIComponentsVisible({ specprev = true, specnext = true, speclabel = true })
		end
	end
end

addEventHandler("race.onSpecPrev", root, function()
	setGUIComponentsVisible({ specprev = false, specprevhi = true })
	setTimer(setGUIComponentsVisible, 100, 1, { specprevhi = false, specprev = true })
end)

addEventHandler("race.onSpecNext", root, function()
	setGUIComponentsVisible({ specnext = false, specnexthi = true })
	setTimer(setGUIComponentsVisible, 100, 1, { specnexthi = false, specnext = true })
end)

addEventHandler("race.onSpecTargetChange", root, function(player, joinBtn)
	if(player) then
		guiSetText(g_GUI.speclabel, 'Currently spectating:\n' .. getPlayerName(Spectate.target))
	else
		guiSetText(g_GUI.speclabel, 'Currently spectating:\n No one to spectate')
	end
	if(joinBtn) then
		guiSetText(g_GUI.speclabel, guiGetText(g_GUI.speclabel) .. "\n\nPress '"..joinBtn.."' to join")
	end
end)

addEvent ( "onClientScreenFadedOut", true )
addEventHandler ( "onClientScreenFadedOut", root,
	function()
		Spectate.fadedout = true
		Spectate.updateGuiFadedOut()
	end
)

addEvent ( "onClientScreenFadedIn", true )
addEventHandler ( "onClientScreenFadedIn", root,
	function()
		Spectate.fadedout = false
		Spectate.updateGuiFadedOut()
	end
)

addEventHandler("onClientPlayerFinish", root, function()
	g_dxGUI.checkpoint:text(g_CheckpointsCount .. ' / ' .. g_CheckpointsCount)
		if g_GUI.hurry then
			Animation.createAndPlay(g_GUI.hurry, Animation.presets.guiFadeOut(500), destroyElement)
			g_GUI.hurry = false
		end
end)

addEventHandler("race.onRankChange", root, function(rank)
	if not tonumber(rank) then
		g_dxGUI.ranknum:text('')
		g_dxGUI.ranksuffix:text('')
		return
	end
	g_dxGUI.ranknum:text(tostring(rank))
	g_dxGUI.ranksuffix:text( (rank < 10 or rank > 20) and ({ [1] = 'st', [2] = 'nd', [3] = 'rd' })[rank % 10] or 'th' )
end)

addEventHandler("onClientPlayerReachCheckpoint", root, function(cp)
	g_dxGUI.checkpoint:text(cp .. ' / ' .. g_CheckpointsCount)
end)
