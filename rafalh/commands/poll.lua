local function CmdPoll (message, arg)
	local title = message:sub (arg[1]:len () + 2)
	
	local voteMgrRes = getResourceFromName ("votemanager")
	if (voteMgrRes and getResourceState (voteMgrRes) == "running") then
		local pollDidStart = call(voteMgrRes, "startPoll", {
			title = title,
			percentage = 50,
			timeout = 10,
			allowchange = true,
			visibleTo = g_Root,
			[1] = { "Yes" },
			[2] = { "No" },
		})
		if (pollDidStart) then
			customMsg (128, 255, 196, "%s started a poll: %s", getPlayerName (source), title)
		else
			privMsg (source, "Error! Poll did not start.")
		end
	end
end

CmdRegister ("poll", CmdPoll, "resource.rafalh.poll", "Starts a custom poll")
