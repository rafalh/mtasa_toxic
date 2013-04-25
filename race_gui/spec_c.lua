local Spectate = {}

addEvent("race.onSpecStart")
addEventHandler("race.onSpecStart", root, function()
	local screenWidth, screenHeight = guiGetScreenSize()
	g_GUI.specprev = guiCreateStaticImage(screenWidth/2 - 100 - g_Images.specprev.w, screenHeight - 123, g_Images.specprev.w, g_Images.specprev.h, g_Images.specprev.path, false, nil)
	g_GUI.specprevhi = guiCreateStaticImage(screenWidth/2 - 100 - g_Images.specprev_hi.w, screenHeight - 123, g_Images.specprev_hi.w, g_Images.specprev_hi.h, g_Images.specprev_hi.path, false, nil)
	g_GUI.specnext = guiCreateStaticImage(screenWidth/2 + 100, screenHeight - 123, g_Images.specprev.w, g_Images.specprev.h, g_Images.specnext.path, false, nil)
	g_GUI.specnexthi = guiCreateStaticImage(screenWidth/2 + 100, screenHeight - 123, g_Images.specprev.w, g_Images.specprev.h, g_Images.specnext_hi.path, false, nil)
	g_GUI.speclabel = guiCreateLabel(screenWidth/2 - 100, screenHeight - 100, 200, 70, '', false)
	
	Spectate.updateGuiFadedOut()
	
	guiLabelSetHorizontalAlign(g_GUI.speclabel, 'center')
	hideGUIComponents('specprevhi', 'specnexthi')
end)

addEvent("race.onSpecStop")
addEventHandler("race.onSpecStop", root, function()
	for i,name in ipairs({'specprev', 'specprevhi', 'specnext', 'specnexthi', 'speclabel'}) do
		if g_GUI[name] then
			destroyElement(g_GUI[name])
			g_GUI[name] = nil
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

addEvent("race.onSpecPrev")
addEventHandler("race.onSpecPrev", root, function()
	setGUIComponentsVisible({ specprev = false, specprevhi = true })
	setTimer(setGUIComponentsVisible, 100, 1, { specprevhi = false, specprev = true })
end)

addEvent("race.onSpecNext")
addEventHandler("race.onSpecNext", root, function()
	setGUIComponentsVisible({ specnext = false, specnexthi = true })
	setTimer(setGUIComponentsVisible, 100, 1, { specnexthi = false, specnext = true })
end)

addEvent("race.onSpecTargetChange")
addEventHandler("race.onSpecTargetChange", root, function(player, joinBtn)
	if(not g_GUI.speclabel) then return end
	if(player) then
		guiSetText(g_GUI.speclabel, 'Currently spectating:\n' .. getPlayerName(Spectate.target))
	else
		guiSetText(g_GUI.speclabel, 'Currently spectating:\n No one to spectate')
	end
	if(joinBtn) then
		guiSetText(g_GUI.speclabel, guiGetText(g_GUI.speclabel).."\n\nPress '"..joinBtn.."' to join")
	end
end)

addEvent("onClientScreenFadedOut", true)
addEventHandler("onClientScreenFadedOut", root,
function()
	Spectate.fadedout = true
	Spectate.updateGuiFadedOut()
end)

addEvent("onClientScreenFadedIn", true)
addEventHandler("onClientScreenFadedIn", root, function()
	Spectate.fadedout = false
	Spectate.updateGuiFadedOut()
end)

addEvent("onClientSetSpectators", true)
addEventHandler("onClientSetSpectators", root, function(spectatorsList)
	g_dxGUI.spectators:text("Spectators: "..g_HudValueColor..(spectatorsList or "none"))
end)
