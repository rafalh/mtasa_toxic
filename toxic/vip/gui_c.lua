
local VIP_INFO_URL = 'https://mtatoxic.tk/vip/'
local VIP_INFO_EMBEDDED_URL = VIP_INFO_URL..'?embedded'
local g_VipRes, g_VipInfoGui

addEvent('vip.onStatus')

local function createVipInfoGui()
	g_VipInfoGui = GUI.create('vipInfo')
	addEventHandler('onClientGUIClick', g_VipInfoGui.closeBtn, function ()
		g_VipInfoGui:destroy()
	end, false)

	local browser = guiGetBrowser(g_VipInfoGui.browser)
	addEventHandler("onClientBrowserCreated", browser, function ()
		if isBrowserDomainBlocked(VIP_INFO_EMBEDDED_URL, true) then
			requestBrowserDomains({VIP_INFO_EMBEDDED_URL}, true, function ()
				loadBrowserURL(browser, VIP_INFO_EMBEDDED_URL)
			end)
		else
			loadBrowserURL(browser, VIP_INFO_EMBEDDED_URL)
		end
	end)
end

local VipPanel = {
	name = "VIP Panel",
	img = 'vip/disabled.png',
	tooltip = "You don't have VIP account. More info: "..VIP_INFO_URL,
	noWnd = true,
	onShow = function()
		if(not g_VipRes:isReady()) then
			outputMsg(Styles.red, "VIP Panel is not running")
			return false
		end
		
		if(not g_VipRes:call('openVipPanel')) then
			outputMsg(Styles.red, "You don't have VIP account. More info: %s", VIP_INFO_URL)
			createVipInfoGui()
			return false
		end
		
		return true
	end
}

local function onVipStatus(isVip)
	VipPanel.img = isVip and 'vip/enabled.png' or 'vip/disabled.png'
	VipPanel.tooltip = isVip and "Press G to open VIP Panel" or "You don't have VIP account. More info: "..VIP_INFO_URL
	UpUpdate(VipPanel)
end

local function init()
	UpRegister(VipPanel)
	
	g_VipRes = Resource('rafalh_vip')
	if(g_VipRes:isReady() and g_VipRes:call('isVip')) then
		onVipStatus(true)
	end
	
	addEventHandler('vip.onStatus', g_Root, onVipStatus)
end

addInitFunc(init)
