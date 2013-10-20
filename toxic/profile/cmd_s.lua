----------------------------------
-- Global functions definitions --
----------------------------------

local function CmdProfileGet(ctx, player)
	local field = ctx.cmdName
	if(not player) then player = ctx.player end
	
	assert(g_ProfileFields[field])
	
	local rows = player.id and DbQuery('SELECT value FROM '..ProfilesTable..' WHERE player=? AND field=? LIMIT 1', player.id, field)
	if(rows and rows[1]) then
		scriptMsg("%s's %s: %s", player:getName(), g_ProfileFields[field].longname, rows[1].value)
	else
		scriptMsg("%s's %s is not set.", player:getName(), g_ProfileFields[field].longname)
	end
end

local function CmdProfileSet(ctx, value)
	local field = ctx.cmdName:sub(4)
	if(ctx.player.id) then
		local data = setPlayerProfile(ctx.player.id, {[field] = value})
		if(data[field]) then
			scriptMsg("%s set his %s: %s.", ctx.player:getName(), g_ProfileFields[field].longname, data[field])
		end
	else
		privMsg(ctx.player, "Guests cannot set their profile fields")
	end
end

local function PfcInit()
	for field, data in pairs (g_ProfileFields) do
		CmdMgr.register{
			name = field,
			desc = 'Shows player '..data.longname,
			args = {
				{'player', type = 'player', defVal = false},
			},
			func = CmdProfileGet
		}
		CmdMgr.register{
			name = 'set'..field,
			desc = 'Changes your '..data.longname,
			args = {
				{'newValue', type = 'str'},
			},
			func = CmdProfileSet
		}
	end
end

addInitFunc(PfcInit)
