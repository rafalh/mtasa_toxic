
#include "include/internal_events.lua"

addEvent("vip.onStatus")

local VipPanel = {
	name = "VIP Panel",
	img = "img/userpanel/vip2.png",
	noWnd = true,
	onShow = function()
		local vipRes = getResourceFromName("rafalh_vip")
		if(not vipRes) then
			outputChatBox("VIP Panel is not running", 255, 0, 0)
			return false
		end
		
		if(not call(vipRes, "openVipPanel")) then
			outputChatBox("You don't have VIP account. More info: /vip", 255, 0, 0)
			return false
		end
		
		return true
	end
}

UpRegister(VipPanel)

local function onVipStatus(isVip)
	VipPanel.img = isVip and "img/userpanel/vip.png" or "img/userpanel/vip2.png"
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

addInternalEventHandler ( $(EV_CLIENT_INIT), init )
addEventHandler("vip.onStatus", g_Root, onVipStatus)
