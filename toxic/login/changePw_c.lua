local g_Gui = false

addEvent('main.onChgPwResult', true)

local function onChgPwEditChange()
	local pw = guiGetText(g_Gui.pw)
	local strength = getPasswordStrength(pw)*100
	
	guiSetText(g_Gui.pwStr, ('%d%%'):format(strength))
	if(strength > 70) then
		guiLabelSetColor(g_Gui.pwStr, 0, 200, 0)
	elseif(strength > 40) then
		guiLabelSetColor(g_Gui.pwStr, 200, 200, 0)
	else
		guiLabelSetColor(g_Gui.pwStr, 200, 0, 0)
	end
end

function closeChangePwGui()
	if(not g_Gui) then return end
	
	g_Gui:destroy()
	showCursor(false)
	g_Gui = false
end

local function onChgPwResult(success)
	if(not g_Gui) then return end
	
	if(success) then
		closeChangePwGui()
	else
		guiSetText(g_Gui.info, "Old password is invalid!")
		guiLabelSetColor(g_Gui.info, 255, 0, 0)
	end
end

local function onChgPwOkClick()
	local oldPw = guiGetText(g_Gui.oldPw)
	local pw = guiGetText(g_Gui.pw)
	local pw2 = guiGetText(g_Gui.pw2)
	local err = false
	
	if(pw ~= pw2) then
		err = "Passwords do not match!"
	end
	if(pw:len() < 3) then
		err = "Password is too short!"
	end
	
	if(err) then
		guiSetText(g_Gui.info, err)
		guiLabelSetColor(g_Gui.info, 255, 0, 0)
	else
		RPC('changeAccountPassword', oldPw, pw):onResult(onChgPwResult):exec()
	end
end

function openChangePasswordGui()
	if(g_Gui) then return end
	
	g_Gui = GUI.create('changePw')
	showCursor(true)
	
	addEventHandler('onClientGUIChanged', g_Gui.pw, onChgPwEditChange, false)
	addEventHandler('onClientGUIClick', g_Gui.ok, onChgPwOkClick, false)
	addEventHandler('onClientGUIClick', g_Gui.cancel, closeChangePwGui, false)
end
