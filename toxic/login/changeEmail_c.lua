local g_Gui = false

function closeChangeEmailGui()
	if(not g_Gui) then return end
	
	g_Gui:destroy()
	showCursor(false)
	g_Gui = false
end

local function onChgEmailResult(success)
	if(not g_Gui) then return end
	
	if(success) then
		closeChangeEmailGui()
	else
		guiSetText(g_Gui.info, "Password is incorrect!")
		guiLabelSetColor(g_Gui.info, 255, 0, 0)
	end
end

local function onOkClick()
	local pw = guiGetText(g_Gui.pw)
	local email = guiGetText(g_Gui.email)
	local err = false
	
	
	if(pw:len() < 3) then
		err = "Password is required!"
	elseif(not email:match('^[%w%._-]+@[%w_-]+%.[%w%._-]+$')) then
		err = "E-mail address is invalid!"
	end
	
	if(err) then
		guiSetText(g_Gui.info, err)
		guiLabelSetColor(g_Gui.info, 255, 0, 0)
	else
		RPC('changeAccountEmail', email, pw):onResult(onChgEmailResult):exec()
	end
end

local function onEmail(email)
	if(g_Gui) then
		guiSetText(g_Gui.email, email)
	end
end

function openChangeEmailGui()
	if(g_Gui) then return end
	
	g_Gui = GUI.create('changeEmail')
	showCursor(true)
	
	addEventHandler('onClientGUIClick', g_Gui.ok, onOkClick, false)
	addEventHandler('onClientGUIClick', g_Gui.cancel, closeChangeEmailGui, false)
	
	RPC('getAccountEmail'):onResult(onEmail):exec()
end
