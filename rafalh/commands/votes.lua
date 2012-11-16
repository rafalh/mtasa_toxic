local function CmdNew (message, arg)
	executeCommandHandler ("new", source, message:sub (arg[1]:len () + 2))
end

CmdRegister ("new", CmdNew, false, false, true)

local function CmdVoteMap (message, arg)
	local mapName = message:sub (arg[1]:len () + 2)
	local map = findMap (mapName)
	if (map) then
		local forb_reason, arg = map:isForbidden()
		if (forb_reason) then
			privMsg (source, forb_reason, arg)
		else
			executeCommandHandler ("votemap", source, mapName)
		end
	else
		privMsg (source, "Cannot find map \"%s\"!", mapName)
	end
end

CmdRegister ("votemap", CmdVoteMap, false, false, true)

local function CmdVoteRedo (message, arg)
	executeCommandHandler ("voteredo", source, message:sub (arg[1]:len () + 2))
end

CmdRegister ("voteredo", CmdVoteRedo, false, false, true)

local function CmdCancel (message, arg)
	local voteMgrRes = getResourceFromName ("votemanager")
	if (voteMgrRes and getResourceState (voteMgrRes) == "running" and call (voteMgrRes, "stopPoll")) then
		customMsg (255, 0, 0, "Vote cancelled by %s!", getPlayerName (source))
	else
		privMsg (source, "No vote in progress!")
	end
end

CmdRegister ("cancel", CmdCancel, "resource.rafalh.cancel", "Cancels current vote")
