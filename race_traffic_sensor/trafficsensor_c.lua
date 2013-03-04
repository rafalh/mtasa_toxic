local HOTKEY = "F4"
local TOGGLE_CMD = "togglets"
local TEXTURE_FILENAME = "img/arrow_ts.png"
local MAX_DIST = 60

local g_Root = getRootElement()
local g_ResRoot = getResourceRootElement(getThisResource())
local g_Me = getLocalPlayer()
local g_SmoothList = {}		-- {player = rrz}
local g_AllPlayers = {}
local g_FinishedPlayers = {}
local g_LastSmoothSeconds = 0
local g_BeginValidSeconds = nil
local g_Enabled = false		-- Manual override
local g_Allowed = true		-- Map override
local g_Hidden = false		-- Black screen override
local g_Tex, g_TexW, g_TexH

addEvent("onClientMapStarting", true)
addEvent("onClientMapStopping", true)
addEvent("onClientPlayerFinish", true)
addEvent("onClientScreenFadedOut", true)
addEvent("onClientScreenFadedIn", true)

local function TsRender()
	-- Ensure map allows it, and player not dead, and in a vehicle and not spectating
	local vehicle = getPedOccupiedVehicle(g_Me)
	if(not g_Allowed or isPlayerDead(g_Me) or g_FinishedPlayers[g_Me]
			or not vehicle or getCameraTarget() ~= vehicle) then
		g_BeginValidSeconds = nil
		return
	end
	
	-- Ensure at least 1 second since g_BeginValidSeconds was set
	local timeSeconds = getTickCount()/1000
	if(not g_BeginValidSeconds) then
		g_BeginValidSeconds = timeSeconds
	end
	if timeSeconds - g_BeginValidSeconds < 1 then return end
	
	-- No draw if faded out or not enabled
	if(g_Hidden or not g_Enabled) then return end
	
	-- Calc smoothing vars
	local delta = timeSeconds - g_LastSmoothSeconds
	g_LastSmoothSeconds = timeSeconds
	local timeslice = math.clamp(0,delta*14,1)
	
	-- Get screen dimensions
	local screenX,screenY = guiGetScreenSize()
	local halfScreenX = screenX * 0.5
	local halfScreenY = screenY * 0.5
	
	-- Get my pos and rot
	local mx, my, mz = getElementPosition(g_Me)
	local _, _, mrz	= getCameraRot()
	local myDim = getElementDimension(g_Me)
	
	-- To radians
	mrz = math.rad(-mrz)
	
	-- For each 'other player'
	for player, _ in pairs(g_AllPlayers) do
		local isDead = isPlayerDead(player)
		local dim = getElementDimension(player)
		if(player ~= g_Me and not isDead and not g_FinishedPlayers[player] and dim == myDim) then
			
			-- Get other pos
			local ox, oy, oz = getElementPosition(player)
			
			-- Only draw marker if other player it is close enough, and not on screen
			local alpha = 1 - getDistanceBetweenPoints3D(mx, my, mz, ox, oy, oz) / MAX_DIST
			local onScreen = getScreenFromWorldPosition(ox, oy, oz)
			
			if onScreen or alpha <= 0 then
				-- If no draw, reset smooth position
				g_SmoothList[player] = nil
			else
				-- Calc arrow color
				local r,g,b = 255,220,210
				local team = getPlayerTeam(player)
				if team then
					r,g,b = getTeamColor(team)
				end

				-- Calc draw scale
				local scalex = alpha * 0.5 + 0.5
				local scaley = alpha * 0.25 + 0.75

				-- Calc dir to
				local dx = ox - mx
				local dy = oy - my
				-- Calc rotz to
				local drz = math.atan2(dx,dy)
				-- Calc relative rotz to
				local rrz = drz - mrz

				-- Add smoothing to the relative rotz
				local smooth = g_SmoothList[player] or rrz
				smooth = math.wrapdifference(-math.pi, smooth, rrz, math.pi)
				if math.abs(smooth-rrz) > 1.57 then
					smooth = rrz	-- Instant jump if more than 1/4 of a circle to go
				end
				smooth = math.lerp( smooth, rrz, timeslice )
				g_SmoothList[player] = smooth
				rrz = smooth

				-- Calc on screen pos for relative rotz
				local sx = math.sin(rrz)
				local sy = math.cos(rrz)

				-- Draw at edge of screen
				local X1 = halfScreenX
				local Y1 = halfScreenY
				local X2 = sx * halfScreenX + halfScreenX
				local Y2 = -sy * halfScreenY + halfScreenY
				local X
				local Y
				if(math.abs(sx) > math.abs(sy)) then
					-- Left or right
					if X2 < X1 then
						-- Left
						X = 32
						Y = Y1+ (Y2-Y1)* (X-X1) / (X2-X1)
					else
						-- right
						X = screenX-32
						Y = Y1+ (Y2-Y1)* (X-X1) / (X2-X1)
					end
				else
					-- Top or bottom
					if Y2 < Y1 then
						-- Top
						Y = 32
						X = X1+ (X2-X1)* (Y-Y1) / (Y2 - Y1)
					else
						-- bottom
						Y = screenY-32
						X = X1+ (X2-X1)* (Y-Y1) / (Y2 - Y1)
					end
				end
				
				local clr = tocolor(r, g, b, 255*alpha)
				local w, h = g_TexW*scalex, g_TexH*scaley
				local x, y = X - w/2, Y - h/2
				dxDrawImage(x, y, w, h, g_Tex, 180 + rrz * 180 / math.pi, 0, 0, clr, false)
			end
		end
	end
end

local function TsMapStarting(mapinfo)
	if(mapinfo.modename == "Destruction derby" or mapinfo.modename == "Freeroam") then
		g_Allowed = false
	else
		g_Allowed = true
	end
	g_FinishedPlayers = {}
end

local function TsMapStopping()
	g_Allowed = false
end

local function TsPlayerFinish()
	g_FinishedPlayers[source] = true
end

local function TsScreenFadeOut()
	g_Hidden = true
end

local function TsScreenFadeIn()
	g_Hidden = false
end

local function TsPlayerJoin()
	g_AllPlayers[source] = true
end

local function TsPlayerQuit()
	g_FinishedPlayers[source] = nil
	g_AllPlayers[source] = nil
	g_SmoothList[source] = nil
end

function TsEnable()
	if(g_Enabled) then return end
	g_Enabled = true
	
	g_Tex = dxCreateTexture(TEXTURE_FILENAME)
	if(g_Tex) then
		g_TexW, g_TexH = dxGetMaterialSize(g_Tex)
	end
	
	addEventHandler("onClientRender", g_Root, TsRender)
end

function TsDisable()
	if(not g_Enabled) then return end
	g_Enabled = false
	
	if(g_Tex) then
		destroyElement(g_Tex)
	end
	
	removeEventHandler("onClientRender", g_Root, TsRender)
end

local function TsToggle()
	if(g_Enabled) then
		TsDisable()
	else
		TsEnable()
	end
	
	if(g_Enabled) then
		outputChatBox("Traffic Sensor is now enabled", 0, 255, 0)
	else
		outputChatBox("Traffic Sensor is now disabled", 255, 0, 0)
	end
end

local function TsInit()
	for i, player in ipairs(getElementsByType("player")) do
		g_AllPlayers[player] = true
	end
	
	addEventHandler("onClientMapStarting", g_Root, TsMapStarting)
	addEventHandler("onClientMapStopping", g_Root, TsMapStopping)
	addEventHandler("onClientPlayerFinish", g_Root, TsPlayerFinish)
	addEventHandler("onClientPlayerJoin", g_Root, TsPlayerJoin)
	addEventHandler("onClientPlayerQuit", g_Root, TsPlayerQuit)
	addEventHandler("onClientScreenFadedOut", g_Root, TsScreenFadeOut)
	addEventHandler("onClientScreenFadedIn", g_Root, TsScreenFadeIn)
	
	addCommandHandler(TOGGLE_CMD, TsToggle, false, false)
	
	bindKey(HOTKEY, "down", TOGGLE_CMD)
end

addEventHandler("onClientResourceStart", g_ResRoot, TsInit)
