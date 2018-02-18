local g_VoteMgrRes = Resource('votemanager')

--[[
-- ONLY CHAT
CmdMgr.register{
	name = 'new',
	varargs = true,
	func = function(ctx, ...)
		executeCommandHandler('new', ctx.player.el, table.concat({...}, ' '))
	end
}

-- ONLY CHAT
CmdMgr.register{
	name = 'votemap',
	args = {
		{'mapName', type = 'str'},
	},
	func = function(ctx, mapName)
		local room = ctx.player.room
		local map = findMap(mapName)
		if(map) then
			local forb_reason, arg = map:isForbidden(room)
			if(forb_reason) then
				privMsg(ctx.player, forb_reason, arg)
			else
				executeCommandHandler('votemap', ctx.player.el, mapName)
			end
		else
			privMsg(ctx.player, "Cannot find map '%s'!", mapName)
		end
	end
}

-- ONLY CHAT
CmdMgr.register{
	name = 'voteredo',
	varargs = true,
	func = function(ctx, ...)
		executeCommandHandler('voteredo', ctx.player.el, table.concat({...}, ' '))
	end
}
]]
CmdMgr.register {
    name = 'cancel',
    desc = "Cancels current vote",
    accessRight = AccessRight('cancel'),
    func = function(ctx)
        if (g_VoteMgrRes:isReady() and g_VoteMgrRes:call('stopPoll')) then
            outputMsg(g_Root, Styles.red, "Vote cancelled by %s!", ctx.player:getName())
        else
            privMsg(ctx.player, "No vote is running now!")
        end
    end
}

CmdMgr.register {
    name = 'votenext',
    desc = "Starts a vote for next map",
    args = {
        {'mapName', type = 'str'}
    },
    func = function(ctx, mapName)
        VtnStart(mapName, ctx.player.el)
    end
}

CmdMgr.register {
    name = 'poll',
    desc = "Starts a custom poll",
    accessRight = AccessRight('poll'),
    args = {
        {'title', type = 'str'}
    },
    func = function(ctx, title)
        if (not g_VoteMgrRes:isReady()) then
            return
        end

        local pollDidStart =
            g_VoteMgrRes:call(
            'startPoll',
            {
                title = title,
                percentage = 50,
                timeout = 10,
                allowchange = true,
                visibleTo = g_Root,
                [1] = {'Yes'},
                [2] = {'No'}
            }
        )

        if (pollDidStart) then
            outputMsg(g_Root, Styles.poll, "%s started a poll: %s", ctx.player:getName(true), title)
        else
            privMsg(ctx.player, "Error! Poll failed to start.")
        end
    end
}
