local ALPHA_DIST = 0
local MAX_DIST = 150
local SCALE = 6
local HEALTH_BAR_WIDTH = 160
local HEALTH_BAR_HEIGHT = 11
local HEALTH_BAR_BORDER = 1
local AVATAR_ALPHA = 128
local AVATAR_CLR = tocolor(255, 255, 255, AVATAR_ALPHA)

local g_Root = getRootElement()
local g_ResRoot = getResourceRootElement()
local g_Me = getLocalPlayer()
local g_NametagsVisible = true
local g_Settings = {font = 'bankgothic'}
local g_Players = {}
local g_HealthTex = false

-- Settings
local g_AvatarsHidden = getElementData(localPlayer, 'nametag.avatarsHidden')
local g_LocalNametagVisible = getElementData(localPlayer, 'my_nametag_visible')

addEvent('onClientScreenFadedIn', true)
addEvent('onClientScreenFadedOut', true)

local function NmtUpdateAvatar(player)
	local pdata = g_Players[player]
	
	if(isElement(pdata.avatar)) then
		destroyElement(pdata.avatar)
		pdata.avatar = false
	end
	
	if(g_AvatarsHidden) then return end
	
	local avatar = getElementData(player, 'avatar')
	if(type(avatar) == 'table' and avatar.src) then
		avatar = avatar.src
	end
	
	local sharedRes = getResourceFromName('rafalh_shared')
	if(avatar and avatar:sub(1, 3) == 'GIF') then
		pdata.avatar = sharedRes and call(sharedRes, 'GifLoad', avatar, true)
	elseif(avatar) then
		pdata.avatar = dxCreateTexture(avatar)
		if(not pdata.avatar) then
			local playerName = getPlayerName(player):gsub('#%x%x%x%x%x%x', '')
			local sigStr = avatar:match('^%w?%w?%w?%w?')
			outputDebugString('Failed to create avatar texture for '..playerName..' ('..avatar:len()..'): '..tostring(sigStr), 2)
		end
	else
		pdata.avatar = false
	end
	return pdata.avatar and true
end

--local dt = 0
--local cnt = 0

local function NmtRender()
--local start = getTickCount()
--for i = 1, 100 do
	if(not g_NametagsVisible) then return end
	
	local cx, cy, cz = getCameraMatrix()
	local myDim = getElementDimension(localPlayer)
	local nametags = {}
	
	for i, player in ipairs(getElementsByType('player')) do
		setPlayerNametagShowing(player, false)
		local veh = getPedOccupiedVehicle(player)
		local alpha = getElementAlpha(player)
		local dim = getElementDimension(player)
		if(veh) then
			alpha = math.max(alpha, getElementAlpha(veh))
		end
		local isDead = isPlayerDead(player)
		
		if ((g_LocalNametagVisible or player ~= localPlayer) and not isDead and alpha > 0 and myDim == dim) then
			local nametag = {player = player, veh = veh}
			local x, y, z = getElementPosition(nametag.veh or nametag.player)
			local dy = 0.95
			--local mat = getElementMatrix(nametag.veh or nametag.player)
			--x, y, z = x + dy * mat[3][1], y + dy * mat[3][2], z + dy * mat[3][3] -- add up vector
			z = z + dy
			nametag.dist = getDistanceBetweenPoints3D(x, y, z, cx, cy, cz)
			if(nametag.dist < MAX_DIST) then
				nametag.sx, nametag.sy = getScreenFromWorldPosition(x, y, z)
				if(nametag.sx and nametag.sy) then
					table.insert(nametags, nametag)
				end
			end
		end
	end
	
	table.sort(nametags, function(nametag1, nametag2)
		return nametag1.dist > nametag2.dist
	end)
	local sharedRes = getResourceFromName('rafalh_shared')
	
	for i, nametag in ipairs(nametags) do
		local scale = math.sqrt(SCALE / nametag.dist)
		scale = math.max(scale, 0.05)
		local pdata = g_Players[nametag.player]
		
		local a = 255
		if(nametag.dist > ALPHA_DIST) then
			a = 1 - (nametag.dist - ALPHA_DIST) / (MAX_DIST - ALPHA_DIST)
			a = a * 255
		end
		
		-- Draw the name
		local name = getPlayerName(nametag.player)
		local name2 = name:gsub('#%x%x%x%x%x%x', '')
		local name_w = dxGetTextWidth(name2, scale, g_Settings.font)
		local name_h = dxGetFontHeight(scale, g_Settings.font)
		local name_y = nametag.sy - name_h
		local name_x = nametag.sx - name_w / 2
		local r, g, b = getPlayerNametagColor(nametag.player)
		
		dxDrawText(name2, name_x + 2 * scale, name_y + 2 * scale, 0, 0, tocolor (0, 0, 0, a), scale, g_Settings.font)
		dxDrawText(name, name_x, name_y, 0, 0, tocolor(r, g, b, a), scale, g_Settings.font, 'left', 'top', false, false, false, true, true)
		
		-- Draw avatar if player has one
		if(pdata.avatar and not isElement(pdata.avatar)) then
			NmtUpdateAvatar(nametag.player)
		end
		
		if(pdata.avatar and not g_AvatarsHidden) then
			local is_gif = getElementType(pdata.avatar) == 'gif'
			
			-- get avatar size
			local w, h
			if(not is_gif) then
				w, h = dxGetMaterialSize(pdata.avatar)
			elseif(sharedRes) then
				w, h = call(sharedRes, 'GifGetSize', pdata.avatar)
			end
			
			-- calculate coordinates
			local size_ratio = w / h
			local avatar_w = 64 * scale * size_ratio
			local avatar_h = 64 * scale
			local avatar_x = nametag.sx - avatar_w / 2
			local avatar_y = name_y - avatar_h
			
			-- draw it
			if(not is_gif) then
				dxDrawImage(avatar_x, avatar_y, avatar_w, avatar_h, pdata.avatar, 0, 0, 0, AVATAR_CLR)
			elseif(sharedRes) then
				call(sharedRes, 'GifRender', avatar_x, avatar_y, avatar_w, avatar_h, pdata.avatar, 0, 0, 0, AVATAR_CLR)
			end
		end
		
		-- Draw health bar (alghoritm for color is taken from race)
		local hp = 0
		if(nametag.veh) then
			hp = getElementHealth(nametag.veh)
			hp = math.max(hp - 250, 0) / 750
		else
			hp = getElementHealth(nametag.player) / 100
		end
		local p = -510 * (hp ^ 2)
		local r = math.max(math.min(p + 255 * hp + 255, 255), 0)
		local g = math.max(math.min(p + 765 * hp, 255), 0)
		local b = 0
		local health_w = scale * HEALTH_BAR_WIDTH
		local health_h = scale * HEALTH_BAR_HEIGHT
		local border = scale * HEALTH_BAR_BORDER
		local health_y = nametag.sy + 2 * scale
		dxDrawRectangle(nametag.sx - health_w / 2, health_y, health_w, health_h, tocolor(0, 0, 0, a))
		dxDrawImage(nametag.sx - health_w / 2 + border, health_y + border, health_w - 2 * border, health_h - 2 * border, g_HealthTex, 0, 0, 0, tocolor(r, g, b, 0.4 * a))
		dxDrawImage(nametag.sx - health_w / 2 + border, health_y + border, hp * (health_w - 2 * border), health_h - 2 * border, g_HealthTex, 0, 0, 0, tocolor(r, g, b, a))
	end
--[[end
cnt = cnt + 1
dt = dt + (getTickCount() - start)
if(cnt >= 100) then
	outputDebugString('Fuck '..dt, 3)
	cnt = 0
	dt = 0
end]]

end

local function NmtShow()
	g_NametagsVisible = true
end

local function NmtHide()
	g_NametagsVisible = false
end

local function NmtInitPlayer(player)
	local pdata = {}
	g_Players[player] = pdata
	NmtUpdateAvatar(player)
end

local function NmtInit()
	g_HealthTex = dxCreateTexture('img/nametag_health.png')
	
	for i, player in ipairs(getElementsByType('player')) do
		NmtInitPlayer(player)
	end
end

local function NmtOnPlayerJoin()
	NmtInitPlayer(source)
end

local function NmtOnPlayerQuit()
	local pdata = g_Players[source]
	if(not pdata) then return end
	
	if(pdata.avatar) then
		destroyElement(pdata.avatar)
		pdata.avatar = false
	end
	
	g_Players[source] = nil
end

local function NmtOnElementDataChange(name)
	if(name ~= 'avatar') then return end
	
	local pdata = g_Players[source]
	if(not pdata) then return end
	
	NmtUpdateAvatar(source)
end

local function NmtOnLocalPlayerDataChange(name)
	if(name == 'nametag.avatarsHidden') then
		g_AvatarsHidden = getElementData(localPlayer, 'nametag.avatarsHidden')
	elseif(name == 'my_nametag_visible') then
		g_LocalNametagVisible = getElementData(localPlayer, 'my_nametag_visible')
	end
end

addEventHandler('onClientScreenFadedIn', g_Root, NmtShow)
addEventHandler('onClientScreenFadedOut', g_Root, NmtHide)
addEventHandler('onClientRender', g_Root, NmtRender)
addEventHandler('onClientResourceStart', g_ResRoot, NmtInit)
addEventHandler('onClientPlayerJoin', g_Root, NmtOnPlayerJoin)
addEventHandler('onClientPlayerQuit', g_Root, NmtOnPlayerQuit)
addEventHandler('onClientElementDataChange', g_Root, NmtOnElementDataChange)
addEventHandler('onClientElementDataChange', g_Me, NmtOnLocalPlayerDataChange)

addCommandHandler('toggleavatars', function()
	g_AvatarsHidden = not g_AvatarsHidden
end)
