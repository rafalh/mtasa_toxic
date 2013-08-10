local AVATARS_DIR = 'avatars/img/'

local g_Avatars = false

addEvent('main.onSetAvatarReq', true)
addEvent('main.onPlayerReady', true)

PlayersTable:addColumns{
	{'avatar', 'VARCHAR(255)', default = ''},
}

local function AvtLoadList()
	if(g_Avatars) then return end
	g_Avatars = {}
	
	local node = xmlLoadFile('meta.xml')
	if(not node) then return end
	
	local defPrice = Settings.avatar_price
	
	for i, subnode in ipairs(xmlNodeGetChildren(node)) do
		local src = xmlNodeGetAttribute(subnode, 'src')
		if(xmlNodeGetName(subnode) == 'file' and src and src:sub(1, AVATARS_DIR:len()) == AVATARS_DIR) then
			local filename = src:sub(AVATARS_DIR:len() + 1)
			local cost = touint(xmlNodeGetAttribute(subnode, 'avatarCost'), defPrice)
			g_Avatars[filename] = cost
		end
	end
	xmlUnloadFile(node)
end

local function AvtUpdatePlayer(player, force)
	AvtLoadList()
	
	local filename = player.accountData.avatar
	if(g_Avatars[filename]) then
		local boardData = filename and {type = 'image', src = ':'..g_ResName..'/'..AVATARS_DIR..filename}
		setElementData(player.el, 'avatar', boardData)
		triggerClientEvent('main.onAvatarChange', player.el, filename)
	elseif(force) then
		setElementData(player.el, 'avatar', false)
		triggerClientEvent('main.onAvatarChange', player.el, false)
	end
end

local function AvtSetReq(filename)
	local player = g_Players[client]
	if(not player) then return end
	
	AvtLoadList()
	
	local cost = filename and g_Avatars[filename]
	if(not cost) then
		outputDebugString('onSetAvatarReq failed', 2)
		return
	end
	
	local minLevel = Settings.avatar_min_level
	if(player.accountData.cash < cost) then
		privMsg(player.el, "You don't have enough cash!")
	elseif(minLevel > 1 and LvlFromExp(player.accountData.points) < minLevel) then
		privMsg(player.el, "You need %u. level to set your avatar!", minLevel)
	else
		player.accountData.avatar = filename or ''
		player.accountData:add('cash', -cost)
		
		AvtUpdatePlayer(player)
	end
end

function AvtGetList()
	AvtLoadList()
	return g_Avatars
end
RPC.allow('AvtGetList')

function AvtGetAccountAvatar(id)
	local accountData = AccountData.create(id)
	local avatar = accountData.avatar
	return avatar ~= '' and avatar
end
RPC.allow('AvtGetAccountAvatar')

function AvtSetupScoreboard(res)
	if(Settings.scoreboard_avatar) then
		call(res, 'scoreboardAddColumn', 'avatar',  g_Root, 36, 'Avatar', 1)
	end
end

local function AvtPlayerReady()
	local player = Player.fromEl(client)
	AvtUpdatePlayer(player)
end

local function AvtPlayerLoginLogout()
	local player = Player.fromEl(source)
	AvtUpdatePlayer(player, true)
end

local function AvtInit()
	addEventHandler('main.onSetAvatarReq', resourceRoot, AvtSetReq)
	addEventHandler('main.onPlayerReady', resourceRoot, AvtPlayerReady)
	addEventHandler('onPlayerLogin', g_Root, AvtPlayerLoginLogout)
	addEventHandler('onPlayerLogout', g_Root, AvtPlayerLoginLogout)
end

addInitFunc(AvtInit)
