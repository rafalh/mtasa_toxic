local VIP_INFO_URL = 'http://mtatoxic.tk/vip/'

local function CmdVip(message, arg)
	outputMsg(source, Styles.info, "Information about VIP rank: %s", VIP_INFO_URL)
end
CmdRegister('vip', CmdVip, false)
