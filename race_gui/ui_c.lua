g_Root = root
g_Me = localPlayer
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
	loading = { path = "img/loading.gif" },
	countdown = { path = "img/countdown_%d.png", w = 380, h = 380/528*384 },
}

local g_HurryDuration = 30
local g_CheckpointsCount = 0

local g_HudKeyColor = "#00AA00"
local g_HudValueColor = "#FFFFFF"

-------------------------------------------------------
-- Title screen - Shown when player first joins the game
-------------------------------------------------------
TitleScreen = {}
TitleScreen.startTime = 0

function TitleScreen.init()
	local adjustY = math.clamp(-30, -15 + (-30- -15) * (g_ScrH - 480)/(900 - 480), -15)
	g_GUI['titleImage'] = guiCreateStaticImage((g_ScrW-g_Images.title.w)/2, (g_ScrH-g_Images.title.h)/2+adjustY, g_Images.title.w, g_Images.title.h, g_Images.title.path, false)
	g_dxGUI['titleText1'] = dxText:create('', 30, g_ScrH-100, false, 'bankgothic', 0.70, 'left')
	g_dxGUI['titleText2'] = dxText:create('', 120, g_ScrH-100, false, 'bankgothic', 0.70, 'left')
	g_dxGUI['titleText1']:text(	'KEYS: \n' ..
								'F4 \n' ..
								'F5 \n' ..
								'K' )
	g_dxGUI['titleText2']:text(	'\n' ..
								'- TRAFFIC ARROWS \n' ..
								'- TOP TIMES \n' ..
								'- RETRY' )
	hideGUIComponents('titleImage', 'titleText1', 'titleText2')
end

function TitleScreen.show()
	showGUIComponents('titleImage', 'titleText1', 'titleText2')
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
	g_GUI['travelImage']   = guiCreateStaticImage((g_ScrW-g_Images.travelling.w)/2, (g_ScrH-g_Images.travelling.h)/2-70, g_Images.travelling.w, g_Images.travelling.h, g_Images.travelling.path, false, nil)
	g_dxGUI['travelText1'] = dxText:create('Travelling to', g_ScrW/2, (g_ScrH+g_Images.travelling.h)/2-40, false, 'bankgothic', 0.60, 'center' )
	g_dxGUI['travelText2'] = dxText:create('', g_ScrW/2, (g_ScrH+g_Images.travelling.h)/2-10, false, 'bankgothic', 0.70, 'center' )
	g_dxGUI['travelText3'] = dxText:create('', g_ScrW/2, (g_ScrH+g_Images.travelling.h)/2+20, false, 'bankgothic', 0.70, 'center' )
	g_dxGUI['travelText1']:color(240, 240, 240)
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
	return math.max(0, TravelScreen.startTime + 3000 - getTickCount())
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
		countdown = dxText:create('', 0.5, 0.5, true, 'bankgothic', 1, 'center'),
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
	g_dxGUI.countdown:align('center', 'center')
	
	g_GUI = {
		timeleftbg = guiCreateStaticImage(g_ScrW/2-g_Images.timeleft.w/2, 15, g_Images.timeleft.w, g_Images.timeleft.h, g_Images.timeleft.path, false, nil),
		timeleft = guiCreateLabel(g_ScrW/2-108/2, 19, 108, 30, '', false),
	}
	guiSetFont(g_GUI.timeleft, 'default-bold-small')
	guiLabelSetHorizontalAlign(g_GUI.timeleft, 'center')
	
	hideGUIComponents('timeleftbg', 'timeleft', 'ranknum', 'ranksuffix', 'checkpoint', 'timepassed', 'countdown')
	
	-- Init presentation screens
	TitleScreen.init()
	TravelScreen.init()
	
	-- Show title screen now
	fadeCamera(false, 0)
	TitleScreen.show()
end)

addEventHandler("onClientResourceStop", resourceRoot, function()
	showHUD(true)
end)

addEvent("race.onTravelingStart")
addEventHandler("race.onTravelingStart", root, function(mapName, authorName)
	fadeCamera(false, 0) -- fadeout, instant, black
	TravelScreen.show(mapName, authorName)
end)

addEvent("onClientMapStarting")
addEventHandler("onClientMapStarting", root, function(mapInfo)
	fadeCamera(false, 0)
	
	g_dxGUI.mapdisplay:text("Map: "..g_HudValueColor..mapInfo.name)
	showHUD(false)
	g_Finished = false
	
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
		g_dxGUI.checkpoint:text('0 / '..g_CheckpointsCount)
	else
		hideGUIComponents('checkpoint')
	end
	
	-- Min 3 seconds on travel message
	local delay = TravelScreen.getTicksRemaining()
	delay = math.max(50, delay)
	setTimer(TravelScreen.hide, delay, 1)

	-- Delay readyness until after title
	TitleScreen.bringForwardFadeout(3000)
	delay = delay + math.max(0, TitleScreen.getTicksRemaining() - 1500)
	
	setTimer(fadeCamera, delay + 750, 1, true, 10.0)
	setTimer(fadeCamera, delay + 1500, 1, true, 2.0)
end)

addEvent("onClientMapStopping")
addEventHandler("onClientMapStopping", root, function()
	removeEventHandler('onClientRender', g_Root, updateTime)
	
	if g_GUI then
		hideGUIComponents('timeleftbg', 'timeleft', 'ranknum', 'ranksuffix', 'checkpoint', 'timepassed')
		if g_GUI.hurry then
			Animation.createAndPlay(g_GUI.hurry, Animation.presets.guiFadeOut(500), destroyElement)
			g_GUI.hurry = nil
		end
	end
	
	Countdown.stop()
end)

addEvent("race.onRaceLaunch")
addEventHandler("race.onRaceLaunch", root, function(duration)
	g_StartTick = getTickCount()
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
	if not g_Finished then
		g_dxGUI.timepassed:text(msToTimeStr(msPassed))
	end
	local timeLeft = g_Duration - msPassed
	guiSetText(g_GUI.timeleft, msToTimeStr(timeLeft > 0 and timeLeft or 0))
	if g_HurryDuration and g_GUI.hurry == nil and timeLeft <= g_HurryDuration then
		startHurry()
	end
end

addEvent("onClientPlayerOutOfTime")
addEventHandler("onClientPlayerOutOfTime", root, function()
	removeEventHandler('onClientRender', root, updateTime)
	guiSetText(g_GUI.timeleft, msToTimeStr(0))
	if g_GUI.hurry then
		Animation.createAndPlay(g_GUI.hurry, Animation.presets.guiFadeOut(500), destroyElement)
		g_GUI.hurry = nil
	end
end)

addEvent("onClientSetNextMap", true)
addEventHandler("onClientSetNextMap", root, function(mapName)
	g_NextMap = mapName
	g_dxGUI.nextdisplay:text("Next map: "..g_HudValueColor..(mapName or "not set"))
end)

addEvent("race.onStartHurry")
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

addEvent("race.onRankChange")
addEventHandler("race.onRankChange", root, function(rank)
	if not tonumber(rank) then
		g_dxGUI.ranknum:text('')
		g_dxGUI.ranksuffix:text('')
		return
	end
	g_dxGUI.ranknum:text(tostring(rank))
	g_dxGUI.ranksuffix:text( (rank < 10 or rank > 20) and ({ [1] = 'st', [2] = 'nd', [3] = 'rd' })[rank % 10] or 'th' )
end)

addEvent("onClientPlayerReachCheckpoint")
addEventHandler("onClientPlayerReachCheckpoint", root, function(cp)
	g_dxGUI.checkpoint:text(cp..' / '..g_CheckpointsCount)
end)

addEvent("onClientPlayerFinish")
addEventHandler("onClientPlayerFinish", root, function()
	g_Finished = true
	g_dxGUI.checkpoint:text(g_CheckpointsCount..' / '..g_CheckpointsCount)
	if g_GUI.hurry then
		Animation.createAndPlay(g_GUI.hurry, Animation.presets.guiFadeOut(500), destroyElement)
		g_GUI.hurry = false
	end
end)
