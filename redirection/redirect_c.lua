local TIMEOUT = 60

local g_ScrW, g_ScrH = guiGetScreenSize()
local g_Timer, g_ProgressBar, g_Countdown
local g_Counter = 0
local g_Address

local g_WndTitle = {
	en = "Redirection",
	pl = "Przeniesienie",
}
local g_Message = {}
g_Message.pl = {
	{"Serwer ToxiC został przeniesiony na nowy adres IP.", clr = "#00FF00", font = "default-bold-small"},
	{"Za wszystkie utrudnienia bardzo przepraszamy."},
	{"Jeżeli wchodzisz na serwer z listy ulubionych, usuń stary wpis i dodaj", font = "default-bold-small"},
	{"ToxiC do Ulubionych ponownie.", font = "default-bold-small"},
	{"Nowy adres IP serwera:"},
}
g_Message.en = {
	{"ToxiC server has been moved to new IP address.", clr = "#00FF00", font = "default-bold-small"},
	{"Sorry for any inconvenience caused."},
	{"If you join server through the favorites list, delete the old entry and", font = "default-bold-small"},
	{"add ToxiC to your favorities again.", font = "default-bold-small"},
	{"New IP address of the server:"},
}
local g_RedirectMsg = {
	en = "You will be automatically redirected to the new server in:",
	pl = "Zostaniesz automatycznie przeniesiony na nowy serwer za:",
}
local g_RedirectBtnTitle = {
	en = "Redirect now",
	pl = "Przenieś teraz",
}
local g_CopyBtnTitle = {
	en = "Copy to clipboard",
	pl = "Skopiuj do schowka",
}

addEvent("redirect.onDisplayWndReq", true)

local function redirect()
	triggerServerEvent("redirect.onReq", resourceRoot)
end

local function copyAddress()
	setClipboard(g_Address)
end

local function onTimerTick()
	g_Counter = g_Counter + 1
	if(g_Counter == TIMEOUT) then
		redirect()
		killTimer(g_Timer)
	end
	guiProgressBarSetProgress(g_ProgressBar, g_Counter / TIMEOUT * 100)
	guiSetText(g_Countdown, (TIMEOUT - g_Counter).." s.")
end

local function createGUI(address)
	local lang = getElementData(localPlayer, "lang") or "en"
	g_Address = address
	
	local msg = g_Message[lang] or g_Message.en
	local h = 140 + #msg * 15
	local wndTitle = g_WndTitle[lang] or g_WndTitle.en
	local wnd = guiCreateWindow((g_ScrW - 500) / 2, (g_ScrH - h) / 2, 500, h, wndTitle, false)
	local label
	
	guiCreateStaticImage(10, 30, 50, 50, "info.png", false, wnd) 
	
	local y = 20
	for i, line in ipairs(msg) do
		label = guiCreateLabel(70, y, 400, 15, line[1], false, wnd)
		if(line.font) then
			guiSetFont(label, line.font)
		end
		if(line.clr) then
			guiLabelSetColor(label, getColorFromString(line.clr))
		end
		y = y + 15
	end
	
	local copyBtnTitle = g_CopyBtnTitle[lang] or g_CopyBtnTitle.en
	local edit = guiCreateEdit(70, y + 5, 200, 20, address, false, wnd)
	guiEditSetReadOnly(edit, true)
	local copyBtn = guiCreateButton(280, y + 5, 200, 20, copyBtnTitle, false, wnd)
	addEventHandler("onClientGUIClick", copyBtn, copyAddress, false)
	
	local redirectMsg = g_RedirectMsg[lang] or g_RedirectMsg.en
	label = guiCreateLabel(70, y + 30, 340, 15, redirectMsg, false, wnd)
	guiSetFont(label, "default-bold-small")
	
	g_Countdown = guiCreateLabel(420, y + 30, 50, 15, TIMEOUT.." s.", false, wnd)
	
	g_ProgressBar = guiCreateProgressBar(20, y + 55, 460, 20, false, wnd)
	
	local btnTitle = g_RedirectBtnTitle[lang] or g_RedirectBtnTitle.en
	local redirBtn = guiCreateButton(150, y + 85, 200, 20, btnTitle, false, wnd)
	addEventHandler("onClientGUIClick", redirBtn, redirect, false)
	
	guiSetInputEnabled(true)
	guiBringToFront(wnd)
	
	g_StartTime = getTickCount()
	
	g_Timer = setTimer(onTimerTick, 1000, 0)
end

local function init()
	addEventHandler("redirect.onDisplayWndReq", resourceRoot, createGUI)
	
	triggerServerEvent("redirect.onReady", resourceRoot)
end

addEventHandler("onClientResourceStart", resourceRoot, init)
