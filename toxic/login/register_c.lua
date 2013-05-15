local g_GUI

addEvent("main.onRegStatus", true)

local function onRegisterClick(btn,state)
	if btn ~= "left" or state ~= "up" then return end
	local name = guiGetText(g_GUI.name)
	local pw = guiGetText(g_GUI.pw)
	local pw2 = guiGetText(g_GUI.pw2)
	local email = guiGetText(g_GUI.email)
	
	local err = false
	if(pw ~= pw2) then
		err = "Passwords do not match!"
	elseif(name:len() < 3) then
		err = "Username is too short!"
	elseif(pw:len() < 3) then
		err = "Password is too short!"
	elseif(email ~= "" and not email:match("^[%w%._-]+@[%w_-]+%.[%w%._-]+$")) then
		err = "E-Mail is invalid!"
	end
	
	if(err) then
		guiSetText(g_GUI.info, err)
		guiLabelSetColor(g_GUI.info, 255, 0, 0)
	else
		triggerServerEvent("main.onRegisterReq", g_ResRoot, name, pw, email)
	end
end

function getPasswordStrength(str)
	local hasNum = str:find("[%d]")
	local hasLowerCase = str:find("[%l]")
	local hasUpperCase = str:find("[%u]")
	local hasSpecChar = str:find("[^%d%a]")
	local strength = str:len()
		+ (hasLowerCase and 1 or 0)
		+ (hasUpperCase and 3 or 0)
		+ (hasNum and 3 or 0)
		+ (hasSpecChar and 3 or 0)
	return math.min(1, strength/16)
end

local function onPwChange()
	local pw = guiGetText(g_GUI.pw)
	local strength = getPasswordStrength(pw)*100
	
	guiSetText(g_GUI.pwStr, ("%d%%"):format(strength))
	if(strength > 70) then
		guiLabelSetColor(g_GUI.pwStr, 0, 200, 0)
	elseif(strength > 40) then
		guiLabelSetColor(g_GUI.pwStr, 200, 200, 0)
	else
		guiLabelSetColor(g_GUI.pwStr, 200, 0, 0)
	end
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
		guiLabelSetColor(g_GUI.info, 255, 0, 0)
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
		showCursor(false)
		g_GUI:destroy()
		g_GUI = false
	end
end

function openRegisterWnd()
	closeRegisterWnd()
	
	g_GUI = GUI.create("registerWnd")
	showCursor(true)
	
	addEventHandler("onClientGUIClick", g_GUI.regBtn, onRegisterClick, false)
	addEventHandler("onClientGUIClick", g_GUI.backBtn, onBackClick, false)
	addEventHandler("onClientGUIChanged", g_GUI.pw, onPwChange, false)
end

addEventHandler("main.onLoginStatus", g_ResRoot, onLoginStatus)
addEventHandler("main.onRegStatus", g_ResRoot, onRegStatus)