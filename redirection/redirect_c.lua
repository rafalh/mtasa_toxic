local g_ScreenSize = { guiGetScreenSize () }
local g_Me = getLocalPlayer ()
local g_Root = getRootElement ()
local g_ResRoot = getResourceRootElement ( getThisResource () )

local g_ProgressBar, g_Button, g_Countdown
local g_Timeout = 60
local g_StartTime
local g_Timer

local g_Message = {}

g_Message.pl = {
	"Serwer ToxiC zostal przeniesiony na nowy adres IP.",
	"Za wszystkie utrudnienia bardzo przepraszamy.",
	{ "Jezeli wchodzisz na serwer z listy ulubionych, usun stary wpis i dodaj", "default-bold-small" },
	{ "ToxiC do Ulubionych ponownie.", "default-bold-small" },
	"Nowy adres IP serwera: 185.5.98.175:22003",
}
g_Message.en = {
	"ToxiC server has been moved to new IP address.",
	"Sorry for any inconvenience caused.",
	{ "If you join server through the favorites list, delete the old entry and", "default-bold-small" },
	{ "add ToxiC to your favorities again.", "default-bold-small" },
	"New IP address of the server: 185.5.98.175:22003",
}

g_RedirectMsg = {
	en = "You will be automatically redirected to the new server in:",
	pl = "Zostaniesz automatycznie przeniesiony na nowy serwer za:",
}

addEvent ( "onClientRedirectRequest", true )
addEvent ( "onRedirectRequest", true )
addEvent ( "onRedirectorStart", true )

local function redirect()
	triggerServerEvent("onRedirectRequest", g_Root)
end

local function onClientResourceStart()
	triggerServerEvent("onRedirectorStart", g_Root)
end

local function onClientRedirectRequest()
	local lang = getElementData(localPlayer, "lang") or "en"
	
	local msg = g_Message[lang] or g_Message.en
	
	local h = 130 + #msg * 15
	local wnd = guiCreateWindow ( ( g_ScreenSize[1] - 500 ) / 2, ( g_ScreenSize[2] - h ) / 2, 500, h, "Przeniesienie / Redirection", false )
	local label
	
	guiCreateStaticImage ( 10, 30, 50, 50, "info.png", false, wnd ) 
	
	local y = 20
	for i, line in ipairs ( msg ) do
		if ( type ( line ) == "table" ) then
			label = guiCreateLabel ( 70, y, 400, 15, line[1], false, wnd )
			guiSetFont ( label, line[2] )
		else
			guiCreateLabel ( 70, y, 400, 15, line, false, wnd )
		end
		y = y + 15
	end
	
	local redirectMsg = g_RedirectMsg[lang] or g_RedirectMsg.en
	label = guiCreateLabel ( 70, y + 15, 340, 15, redirectMsg, false, wnd )
	guiSetFont ( label, "default-bold-small" )
	
	g_Countdown = guiCreateLabel ( 420, y + 15, 50, 15, g_Timeout.." s.", false, wnd )
	
	g_ProgressBar = guiCreateProgressBar ( 20, y + 40, 460, 20, false, wnd )
	
	g_Button = guiCreateButton ( 150, y + 70, 200, 20, "Przenies teraz / Redirect now", false, wnd )
	addEventHandler ( "onClientGUIClick", g_Button, redirect, false )
	
	guiSetInputEnabled ( true )
	guiBringToFront ( wnd )
	
	g_StartTime = getTickCount ()
	
	g_Timer = setTimer ( function ()
		local t = g_Timeout - ( getTickCount () - g_StartTime ) / 1000
		if ( t <= 0 ) then
			redirect ()
			killTimer ( g_Timer )
		end
		guiProgressBarSetProgress ( g_ProgressBar, ( getTickCount () - g_StartTime ) / 1000 / g_Timeout * 100 )
		guiSetText ( g_Countdown, math.floor ( t ).." s." )
	end, 1000, 0 )
end

addEventHandler ( "onClientRedirectRequest", g_ResRoot, onClientRedirectRequest )
addEventHandler ( "onClientResourceStart", g_ResRoot, onClientResourceStart )