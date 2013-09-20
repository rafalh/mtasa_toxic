local g_VoteMgrRes = Resource('votemanager')

local function CmdNew (message, arg)
	executeCommandHandler ('new', source, message:sub (arg[1]:len () + 2))
end

CmdRegister('new', CmdNew, false, false, true)

local function CmdVoteMap(message, arg)
	local room = Player.fromEl(source).room
	local mapName = message:sub (arg[1]:len () + 2)
	local map = findMap (mapName)
	if (map) then
		local forb_reason, arg = map:isForbidden(room)
		if (forb_reason) then
			privMsg(source, forb_reason, arg)
		else
			executeCommandHandler ('votemap', source, mapName)
		end
	else
		privMsg (source, "Cannot find map \"%s\"!", mapName)
	end
end

CmdRegister ('votemap', CmdVoteMap, false, false, true)

local function CmdVoteRedo (message, arg)
	executeCommandHandler ('voteredo', source, message:sub (arg[1]:len () + 2))
end

CmdRegister('voteredo', CmdVoteRedo, false, false, true)

local function CmdCancel (message, arg)
	if (g_VoteMgrRes:isReady() and g_VoteMgrRes:call('stopPoll')) then
		outputMsg(g_Root, Styles.red, "Vote cancelled by %s!", getPlayerName (source))
	else
		privMsg (source, "No vote in progress!")
	end
end

CmdRegister('cancel', CmdCancel, 'resource.'..g_ResName..'.cancel', "Cancels current vote")

local function CmdVoteNext(message, arg)
	local pattern = message:sub(arg[1]:len() + 2)
	VtnStart(pattern, source)
end

CmdRegister('votenext', CmdVoteNext, false, "Starts a vote for next map")

local function CmdPoll(message, arg)
	local title = message:sub(arg[1]:len() + 2)
	
	if(g_VoteMgrRes:isReady()) then
		local pollDidStart = g_VoteMgrRes:call('startPoll', {
			title = title,
			percentage = 50,
			timeout = 10,
			allowchange = true,
			visibleTo = g_Root,
			[1] = {"Yes"},
			[2] = {"No"},
		})
		if(pollDidStart) then
			outputMsg(g_Root, Styles.poll, "%s started a poll: %s", getPlayerName(source), title)
		else
			privMsg (source, "Error! Poll did not start.")
		end
	end
end

CmdRegister('poll', CmdPoll, 'resource.'..g_ResName..'.poll', "Starts a custom poll")
