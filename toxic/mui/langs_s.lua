addEvent("main.onSetLocaleReq", true)

function Player.__mt.__index:setLocale(localeId)
	if(self.lang == localeId) then return end
	
	self.lang = localeId
	setElementData(self.el, "lang", localeId)
	if(self.sync) then
		triggerClientEvent(self.el, "onClientLangChange", g_Root, localeId)
	end
	triggerEvent("onPlayerLangChange", self.el, localeId)
end

local function LngOnSetLocaleRequest(localeId)
	if(not localeId or not LocaleList.exists(localeId)) then return end
	
	local pdata = Player.fromEl(client)
	pdata:setLocale(localeId)
end

addInitFunc(function()
	addEventHandler("main.onSetLocaleReq", g_ResRoot, LngOnSetLocaleRequest)
end)
