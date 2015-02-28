
#include 'include/internal_events.lua'

local VIP_INFO_URL = 'http://mtatoxic.tk/vip/'
local g_VipRes

addEvent('vip.onStatus')

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
