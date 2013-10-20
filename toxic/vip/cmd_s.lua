local VIP_INFO_URL = 'http://mtatoxic.tk/vip/'

CmdMgr.register{
	name = 'vip',
	desc = "Displays URL to VIP rank information",
	func = function(ctx)
		outputMsg(ctx.player, Styles.info, "Information about VIP rank: %s", VIP_INFO_URL)
	end
}
