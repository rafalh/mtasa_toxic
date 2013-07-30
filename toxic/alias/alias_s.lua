AliasesTable = Database.Table{
	name = 'aliases',
	{'serial', 'INT UNSIGNED', fk = {'serials', 'id'}},
	{'name', 'VARCHAR(32)'},
	{'alias_idx', unique = {'serial', 'name'}},
}

local function AlAddPlayerAlias(player, name)
	if(name) then
		name = name:gsub('#%x%x%x%x%x%x', '')
	else
		name = player:getName()
	end
	
	local rows = DbQuery('SELECT serial FROM '..AliasesTable..' WHERE serial=? AND name=? LIMIT 1', player:getSerialID(), name)
	if(not rows or not rows[1]) then
		DbQuery('INSERT INTO '..AliasesTable..' (serial, name) VALUES (?, ?)', player:getSerialID(), name)
	end
end

function AlGetPlayerAliases(player)
	local aliases = {}
	local rows = DbQuery('SELECT name FROM '..AliasesTable..' WHERE serial=?', player:getSerialID())
	for i, data in ipairs(rows) do
		table.insert(aliases, data.name)
	end
	return aliases
end

local function AlOnPlayerChangeNick(oldNick, newNick)
	if(wasEventCancelled()) then return end
	
	local player = Player.fromEl(source)
	if(player) then
		AlAddPlayerAlias(player, newNick)
	end
end

local function AlOnPlayerJoin()
	local player = Player.fromEl(source)
	AlAddPlayerAlias(player)
end

local function AlInit()
	for player, pdata in pairs(g_Players) do
		AlAddPlayerAlias(pdata)
	end
	
	addEventHandler('onPlayerJoin', g_Root, AlOnPlayerJoin)
	addEventHandler('onPlayerChangeNick', g_Root, AlOnPlayerChangeNick)
end

addInitFunc(AlInit)
