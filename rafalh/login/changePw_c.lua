local g_ChangePwGui = false

addEvent("main.onChgPwResult", true)

local function onChgPwEditChange()
	local pw = guiGetText(g_ChangePwGui.pw)
	local strength = getPasswordStrength(pw)*100
	
	guiSetText(g_ChangePwGui.pwStr, ("%d%%"):format(strength))
	if(strength > 70) then
		guiLabelSetColor(g_ChangePwGui.pwStr, 0, 200, 0)
	elseif(strength > 40) then
		guiLabelSetColor(g_ChangePwGui.pwStr, 200, 200, 0)
	else
		guiLabelSetColor(g_ChangePwGui.pwStr, 200, 0, 0)
	end
end

local function onChgPwOkClick()
	local oldPw = guiGetText(g_ChangePwGui.oldPw)
	local pw = guiGetText(g_ChangePwGui.pw)
	local pw2 = guiGetText(g_ChangePwGui.pw2)
	local err = false
	
	if(pw ~= pw2) then
		err = "Passwords do not match!"
	end
	if(pw:len() < 3) then
		err = "Password is too short!"
	end
	
	if(err) then
		guiSetText(g_ChangePwGui.info, err)
		guiLabelSetColor(g_ChangePwGui.info, 255, 0, 0)
	else
		triggerServerEvent("main.onChgPwReq", g_ResRoot, oldPw, pw)
	end
end

local function closeChangePwGui()
	if(not g_ChangePwGui) then return end
	
	g_ChangePwGui:destroy()
	guiSetInputEnabled(false)
	g_ChangePwGui = false
end

local function onChgPwResult(success)
	if(not g_ChangePwGui) then return end
	
	if(success) then
		closeChangePwGui()
	else
		guiSetText(g_ChangePwGui.info, "Old password is invalid!")
		guiLabelSetColor(g_ChangePwGui.info, 255, 0, 0)
	end
end

function openChangePasswordGui()
	if(g_ChangePwGui) then return end
	
	g_ChangePwGui = GUI.create("changePw")
	guiSetInputEnabled(true)
	
	addEventHandler("onClientGUIChanged", g_ChangePwGui.pw, onChgPwEditChange, false)
	addEventHandler("onClientGUIClick", g_ChangePwGui.ok, onChgPwOkClick, false)
	addEventHandler("onClientGUIClick", g_ChangePwGui.cancel, closeChangePwGui, false)
end

addEventHandler("main.onChgPwResult", g_ResRoot, onChgPwResult)
