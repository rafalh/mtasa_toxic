local g_GUI

addEvent("main_onRegStatus", true)

local function onLoginClick()
	local name = guiGetText(g_GUI.name)
	local pw = guiGetText(g_GUI.pw)
	triggerServerEvent("main_onLogin", g_ResRoot, name, pw)
	closeRegisterWnd()
end

local function onRegisterClick(btn,state)
	if btn ~= "left" or state ~= "up" then return end
	local name = guiGetText(g_GUI.name)
	local pw = guiGetText(g_GUI.pw)
	local pw2 = guiGetText(g_GUI.pw2)
	
	if(pw ~= pw2) then
		guiSetText(g_GUI.info, "Passwords are not equal")
		guiLabelSetColor(g_GUI.info, 255, 0, 0)
		return
	end
	
	triggerServerEvent("main_onRegisterReq", g_ResRoot, name, pw)
end

local function onBackClick(btn,state)
	if btn ~= "left" or state ~= "up" then return end
	closeRegisterWnd()
	openLoginWnd()
end

local function onRegStatus(success)
	if(not g_GUI) then return end
	
	if(not success) then
		guiSetText(g_GUI.info, "Registration failed")
		dxSetColor(g_GUI.info, 255, 0, 0)
	else
		outputChatBox("Registration succeeded!", 0, 255, 0)
		closeRegisterWnd()
		openLoginWnd()
	end
end

local function onLoginStatus(success)
	if(success) then
		closeRegisterWnd()
	end
end

function closeRegisterWnd()
	if(g_GUI) then
		guiSetInputEnabled(false)
		g_GUI:destroy()
		g_GUI = false
		--showCursor(false)
	end
end

function openRegisterWnd()
	closeRegisterWnd()
	
	g_GUI = GUI.create("registerWnd")
	guiSetInputEnabled(true)
	--showCursor(true)
	addEventHandler("onClientGUIClick", g_GUI.regBtn, onRegisterClick, false)
	addEventHandler("onClientGUIClick", g_GUI.backBtn, onBackClick, false)
end

addEventHandler("main_onLoginStatus", g_ResRoot, onLoginStatus)
addEventHandler("main_onRegStatus", g_ResRoot, onRegStatus)