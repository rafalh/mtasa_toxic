local g_GUI = false

function closeLostPasswordWnd()
	if(not g_GUI) then return end
	
	g_GUI:destroy()
	showCursor(false)
	g_GUI = false
end

local function onPwRecoveryResult(success)
	if(not g_GUI) then return end
	
	if(success) then
		closeLostPasswordWnd()
	else
		guiSetText(g_GUI.info, "This e-mail address has not been found!")
		guiLabelSetColor(g_GUI.info, 255, 0, 0)
		guiSetEnabled(g_GUI.ok, true)
	end
end

local function onOkClick()
	local email = guiGetText(g_GUI.email)
	local err = false
	
	if(email:len() < 3) then
		err = "E-mail address is too short!"
	end
	
	if(err) then
		guiSetText(g_GUI.info, err)
		guiLabelSetColor(g_GUI.info, 255, 0, 0)
	else
		guiSetEnabled(g_GUI.ok, false)
		RPC('passwordRecoveryReq', email):onResult(onPwRecoveryResult):exec()
	end
end

function openLostPasswordWnd()
	if(g_GUI) then return end
	
	g_GUI = GUI.create('passwordRecovery')
	showCursor(true)
	guiBringToFront(g_GUI.email)
	
	addEventHandler('onClientGUIClick', g_GUI.ok, onOkClick, false)
	addEventHandler('onClientGUIClick', g_GUI.cancel, closeLostPasswordWnd, false)
end
