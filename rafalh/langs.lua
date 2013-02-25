addEvent("main.onSetLocaleReq", true)

function Player:setLocale(localeId)
	self.lang = localeId
	setElementData(self.el, "lang", localeId)
	if(self.sync) then
		triggerClientEvent(self.el, "onClientLangChange", g_Root, localeId)
	end
	triggerEvent("onPlayerLangChange", self.el, localeId)
end

local function LngOnSetLocaleRequest(localeId)
	if(not localeId or not LocaleList.exists(localeId)) then return end
	
	local pdata = g_Players[client]
	pdata:setLocale(localeId)
end

addEventHandler("main.onSetLocaleReq", g_ResRoot, LngOnSetLocaleRequest)
