--------------
-- Includes --
--------------
#include 'include/config.lua'

local g_GUI
g_UserName = false

addEvent('main.onLoginReq', true)
addEvent('main.onLoginStatus', true)

local function rot13(pw)
	local buf = ''
	for i = 1, pw:len() do
		local code = pw:byte(i)
		if(code >= 65 and code <= 90) then -- A-Z
			code = 65 + (((code - 65) + 13) % 26)
		elseif(code >= 97 and code <= 122) then -- a-z
			code = 97 + (((code - 97) + 13) % 26)
		end
		buf = buf..string.char(code)
	end
	return buf
end

local function saveAutoLogin()
	assert(g_GUI)
	local name = guiGetText(g_GUI.name)
	local pw = guiGetText(g_GUI.pw)
	
	local file = fileCreate('@autologin.txt')
	if(not file) then return end
	
	fileWrite(file, name..'\n'..rot13(pw))
	fileClose(file)
end

local function loadAutoLogin()
	assert(g_GUI)
	
	if(not fileExists('@autologin.txt')) then return false end
	local file = fileOpen('@autologin.txt', true)
	if(not file) then return false end
	local size = fileGetSize(file)
	local buf = size > 0 and fileRead(file, size) or ''
	fileClose(file)
	local data = split(buf, '\n')
	if(not data or #data < 2) then return false end
	
	guiSetText(g_GUI.name, data[1])
	guiSetText(g_GUI.pw, rot13(data[2]))
	guiCheckBoxSetSelected(g_GUI.remember, true)
	return true
end

local function onLoginClick(btn, state)
	if btn ~= 'left' or state ~= 'up' then return end
	local name = guiGetText(g_GUI.name)
	local pw = guiGetText(g_GUI.pw)
	
	guiSetText(g_GUI.info, "Please wait...")
	guiLabelSetColor(g_GUI.info, 255, 255, 255)
	
	triggerServerEvent('main.onLogin', g_ResRoot, name, pw)
end

local function onRegisterClick(btn, state)
	if btn ~= 'left' or state ~= 'up' then return end
	closeLoginWnd()
	openRegisterWnd()
end

local function onLostPwClick(btn, state)
	if btn ~= 'left' or state ~= 'up' then return end
	closeLoginWnd()
	openLostPasswordWnd()
end

local function onPlayAsGuestClick(btn, state)
	if btn ~= 'left' or state ~= 'up' then return end
	triggerServerEvent('main.onLogin', g_ResRoot, false, false)
	closeLoginWnd()
end

local function onLoginStatus(success)
	if(not success) then
		if(not g_GUI) then
			openLoginWnd()
		end
		
		guiSetText(g_GUI.info, "Wrong username or password")
		guiLabelSetColor(g_GUI.info, 255, 0, 0)
	elseif(g_GUI) then
		local remember = guiCheckBoxGetSelected(g_GUI.remember)
		if(remember) then
			saveAutoLogin()
		else
			fileDelete('@autologin.txt')
		end
		
		closeLoginWnd()
	end
end

local function onFlagClick()
	local localeId = g_GUI.flagTbl[source]
	if(Settings.locale == localeId) then return end
	
	triggerServerEvent('main.onSetLocaleReq', g_ResRoot, localeId)
	Settings.locale = localeId
	Settings.save()
	
	for img, localeId in pairs(g_GUI.flagTbl) do
		local a = (img == source and 1 or 0.6)
		guiSetAlpha(img, a)
	end
end

function closeLoginWnd()
	if(not g_GUI) then return end
	
	showCursor(false)
	g_GUI:destroy()
	g_GUI = false
end

function openLoginWnd()
	closeLoginWnd()
	
	g_GUI = GUI.create('loginWnd')
	local langsCount = LocaleList.count()
	local curLocale = Settings.locale
	
	g_GUI.flagTbl = {}
	local flagsW, flagsH = guiGetSize(g_GUI.flags, false)
	local imgW, imgH = math.floor(flagsH*80/53), flagsH
	local spaceW = math.floor(0.2*imgW)
	local x = (flagsW - imgW*langsCount - spaceW*(langsCount-1))/2
	for i, locale in LocaleList.ipairs() do
		local img = guiCreateStaticImage(x, 0, imgW, imgH, locale.img, false, g_GUI.flags)
		if(locale.code ~= curLocale) then
			guiSetAlpha(img, 0.6)
		end
		addEventHandler('onClientGUIClick', img, onFlagClick, false)
		setElementData(img, 'tooltip', locale.name)
		g_GUI.flagTbl[img] = locale.code
		x = x + imgW + spaceW
	end
	
	showCursor(true)
	addEventHandler('onClientGUIClick', g_GUI.logBtn, onLoginClick, false)
	addEventHandler('onClientGUIClick', g_GUI.regBtn, onRegisterClick, false)
	addEventHandler('onClientGUIClick', g_GUI.guestBtn, onPlayAsGuestClick, false)
#if(PASSWORD_RECOVERY) then
	addEventHandler('onClientGUIClick', g_GUI.lostPw, onLostPwClick, false)
#else
	guiSetVisible(g_GUI.lostPw, false)
#end
	
	loadAutoLogin()
end

addInitFunc(function()
	addEventHandler('main.onLoginReq', g_ResRoot, openLoginWnd)
	addEventHandler('main.onLoginStatus', g_ResRoot, onLoginStatus)
end)
