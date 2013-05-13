
#include "include/internal_events.lua"

local VIP_INFO_URL = "http://mtatoxic.tk/vip/"

addEvent("vip.onStatus")

local VipPanel = {
	name = "VIP Panel",
	img = "vip/disabled.png",
	tooltip = "You don't have VIP account. More info: "..VIP_INFO_URL,
	noWnd = true,
	onShow = function()
		local vipRes = getResourceFromName("rafalh_vip")
		if(not vipRes) then
			outputChatBox("VIP Panel is not running", 255, 0, 0)
			return false
		end
		
		if(not call(vipRes, "openVipPanel")) then
			outputMsg(Styles.red, "You don't have VIP account. More info: %s", VIP_INFO_URL)
			return false
		end
		
		return true
	end
}

UpRegister(VipPanel)

local function onVipStatus(isVip)
	VipPanel.img = isVip and "vip/enabled.png" or "vip/disabled.png"
	VipPanel.tooltip = isVip and "Press G to open VIP Panel" or "You don't have VIP account. More info: "..VIP_INFO_URL
	UpUpdate(VipPanel)
end

local function init()
	local isVip = false
	local vipRes = getResourceFromName("rafalh_vip")
	if(vipRes and call(vipRes, "isVip")) then
		isVip = true
	end
	
	if(isVip) then
		onVipStatus(isVip)
	end
end

addInternalEventHandler($(EV_CLIENT_INIT), init)
addEventHandler("vip.onStatus", g_Root, onVipStatus)
