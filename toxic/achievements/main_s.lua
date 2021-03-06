local g_Achievements = {}
local g_NameToAchv = {}
local g_IdToAchv = {}

addEvent('main.onAchvActivate', true)
--addEvent('main.onAchvListReq', true)

PlayersTable:addColumns{
	{'achievements', 'BLOB', default = ''},
}

function AchvGetCount()
	return #g_Achievements
end

-- called from mergeaccounts command handler
function AchvInvalidateCache(player)
	local pdata = Player.fromEl(player)
	local achvList, achvSet = AchvGetActive(player)
	pdata.accountData:set('achvCount', #achvList)
	pdata.achvSet = achvSet
end

function AchvGetActive(player)
	local pdata = Player.fromEl(player)
	
	local achvStr = pdata.accountData:get('achievements')
	local activeList = {string.byte(achvStr, 1, achvStr:len())}
	local activeSet = {}
	for i, id in ipairs(activeList) do
		-- make sure invalid IDs are ignored
		if(not g_IdToAchv[id]) then
			table.remove(activeList, i)
		else
			activeSet[id] = true
		end
	end
	
	local stats = pdata.accountData:getTbl()
	for i, achv in ipairs(g_Achievements) do
		local active = false
		if(achv.checkStats and not activeSet[achv.id] and achv.checkStats(stats)) then
			table.insert(activeList, achv.id)
			activeSet[achv.id] = true
		end
	end
	
	return activeList, activeSet
end

function AchvCheckPlayer(player)
	local pdata = Player.fromEl(player)
	assert(pdata.achvSet)
	
	local activeList, activeSet = AchvGetActive(player)
	if(pdata.accountData.achvCount == #activeList) then return end
	
	local newAchv = {}
	for i, achv in ipairs(g_Achievements) do
		if(activeSet[achv.id] and not pdata.achvSet[achv.id]) then
			table.insert(newAchv, achv.name)
		end
	end
	
	if(#newAchv > 0) then
		if(#newAchv >= 3) then
			Debug.err('Tried to activate '..#newAchv..' achievements at once!')
		else
			AchvActivate(player, newAchv)
		end
	end
end

function AchvRegister(achv)
	assert(not g_NameToAchv[achv.name])
	assert(not g_IdToAchv[achv.id])
	table.insert(g_Achievements, achv)
	g_NameToAchv[achv.name] = achv
	g_IdToAchv[achv.id] = achv
end

function AchvActivate(player, names)
	local pdata = Player.fromEl(player)
	assert(pdata and names)
	if(type(names) ~= 'table') then
		names = {names}
	end
	
	if(not pdata.id) then return end -- dont support achievements for guests
	
	local achvStr = pdata.accountData:get('achievements')
	local newAchv = {}
	
	assert(pdata.achvSet)
	
	for i, name in ipairs(names) do
		local achv = g_NameToAchv[name]
		assert(pdata and achv, name)
		
		if(not pdata.achvSet[achv.id]) then
			if(achv.save or achv.client) then
				achvStr = achvStr..string.char(achv.id)
				--Debug.info('add '..achv.id..' to DB')
			end
			
			Debug.info('Achievement '..achv.name..' activated for '..tostring(getPlayerName(player)))
			pdata.achvSet[achv.id] = true
			pdata.accountData:add('achvCount', 1)
			table.insert(newAchv, achv.id)
			pdata.accountData:add('cash', achv.prize)
		else
			--Debug.info('Failed to activate achievement: '..achv.name)
		end
	end
	
	if(#newAchv > 0) then
		pdata.accountData:set('achievements', achvStr)
		
		if(pdata.sync) then
			triggerClientEvent(player, 'main.onAchvChange', g_ResRoot, newAchv)
		end
	end
end

local function AchvInitAccount(player)
	AchvInvalidateCache(player)
	
	local pdata = Player.fromEl(player)
	if(pdata.achvReq) then
		local achvList = AchvGetActive(player)
		triggerClientEvent(player, 'main.onAchvList', g_ResRoot, achvList)
	end
end

local function AchvPlayerLoginLogout()
	--Debug.info('AchvPlayerLoginLogout!')
	AchvInitAccount(source)
end

local function AchvPlayerJoin()
	AchvInitAccount(source)
end

local function AchvClientActivate(name)
	--Debug.info('AchvClientActivate')
	
	local achv = g_NameToAchv[name]
	if(not achv or not achv.client) then return end -- hacking attempt
	
	AchvActivate(client, name)
end

local function AchvListReq()
	local achvList = AchvGetActive(client)
	triggerClientEvent(client, 'main.onAchvList', g_ResRoot, achvList)
	local pdata = Player.fromEl(client)
	pdata.achvReq = true
end

local function AchvInit()
	for player, pdata in pairs(g_Players) do
		AchvInitAccount(player)
	end
	
	Event('onPlayerLogin'):addHandler(AchvPlayerLoginLogout)
	addEventHandler('onPlayerLogout', g_Root, AchvPlayerLoginLogout)
	addEventHandler('onPlayerJoin', g_Root, AchvPlayerJoin)
	addEventHandler('main.onAchvActivate', g_ResRoot, AchvClientActivate)
	--addEventHandler('main.onAchvListReq', g_ResRoot, AchvListReq)
	addEventHandler('main.onPlayerReady', g_ResRoot, AchvListReq) -- hmm
end

addInitFunc(AchvInit)
