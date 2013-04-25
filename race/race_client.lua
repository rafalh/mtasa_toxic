g_Root = getRootElement()
g_ResRoot = getResourceRootElement(getThisResource())
g_Me = getLocalPlayer()
g_ArmedVehicleIDs = table.create({ 425, 447, 520, 430, 464, 432, 476 }, true)
g_WaterCraftIDs = table.create({ 539, 460, 417, 447, 472, 473, 493, 595, 484, 430, 453, 452, 446, 454 }, true)
g_ModelForPickupType = { nitro = 2221, repair = 2222, vehiclechange = 2223 }
g_HunterID = 425
g_NextMap = false

g_Checkpoints = {}
g_Pickups = {}
g_VisiblePickups = {}
g_Objects = {}

g_ScreenWidth, g_ScreenHeight = guiGetScreenSize()

local g_HudKeyColor = "#00AA00"
local g_HudValueColor = "#FFFFFF"

addEvent("onClientPlayerReachCheckpoint")
addEvent("onClientRaceCountdown")
addEvent("race.onRankChange")
addEvent("race.onSpecPrev")
addEvent("race.onSpecNext")
addEvent("race.onSpecTargetChange")
addEvent("race.onStartHurry")

addEventHandler('onClientResourceStart', g_ResRoot,
	function()
		g_Players = getElementsByType('player')
		
        fadeCamera(false,0.0)
		
		-- set update handlers
		g_PickupStartTick = getTickCount()
		g_WaterCheckTimer = setTimer(checkWater, 1000, 0)
		
		-- load pickup models and textures
		for name,id in pairs(g_ModelForPickupType) do
			engineImportTXD(engineLoadTXD('model/' .. name .. '.txd'), id)
			engineReplaceModel(engineLoadDFF('model/' .. name .. '.dff', id), id)
			-- Double draw distance for pickups
			engineSetModelLODDistance( id, 60 )
		end

		-- Dont clip vehicles (1.0.1 function)
		setCameraClip ( true, false )
		
		setPedCanBeKnockedOffBike(g_Me, false)
	end
)

-- Called from server
function notifyLoadingMap( mapName, authorName )
    fadeCamera( false, 0.0, 0,0,0 ) -- fadeout, instant, black
	triggerEvent("race.onTravelingStart", resourceRoot, mapName, authorName)
end


-- Called from server
function initRace(vehicle, checkpoints, objects, pickups, mapoptions, ranked, duration, gameoptions, mapinfo, playerInfo)
    outputDebug( 'MISC', 'initRace start' )
	unloadAll()
	
	mapinfo.cpCount = #checkpoints
	
	g_Players = getElementsByType('player')
	g_MapOptions = mapoptions
	g_GameOptions = gameoptions
	g_MapInfo = mapinfo
    g_PlayerInfo = playerInfo
    triggerEvent('onClientMapStarting', g_Me, mapinfo )
	
	fadeCamera(true)
	
	g_Vehicle = vehicle
	setVehicleDamageProof(g_Vehicle, true)
	OverrideClient.updateVars(g_Vehicle)
	
	if ( g_MapOptions.compmode ) then
		outputDebugString ( "Compatibility mode!", 2 )
	end
	
	--local x, y, z = getElementPosition(g_Vehicle)
	setCameraBehindVehicle(vehicle)
	--alignVehicleToGround(vehicle)
	updateVehicleWeapons()
	setCloudsEnabled(g_GameOptions.cloudsenable)
	setBlurLevel(g_GameOptions.blurlevel)
	if engineSetAsynchronousLoading then
		engineSetAsynchronousLoading( g_GameOptions.asyncloading )
	end

	-- checkpoints
	g_Checkpoints = checkpoints
	
	-- pickups
	local object
	local pos
	local colshape
	
	local vx, vy, vz = getElementPosition ( g_Vehicle )
	
	for i,pickup in pairs(pickups) do
		pos = pickup.position
		object = createObject(g_ModelForPickupType[pickup.type], pos[1], pos[2], pos[3])
		setElementCollisionsEnabled(object, false)
		if g_MapOptions.compmode then
			colshape = createColSphere(pos[1], pos[2], pos[3]+0.05, 4)
		else
			colshape = createColSphere(pos[1], pos[2], pos[3], 3.5)
		end
		g_Pickups[colshape] = { object = object }
		for k,v in pairs(pickup) do
			g_Pickups[colshape][k] = v
		end
        g_Pickups[colshape].load = true
		if g_Pickups[colshape].type == 'vehiclechange' then
			g_Pickups[colshape].label = dxText:create(getVehicleNameFromModel(g_Pickups[colshape].vehicle), 0.5, 0.5)
			g_Pickups[colshape].label:color(255, 255, 255, 0)
			g_Pickups[colshape].label:type("shadow",2)
			
			if g_MapOptions.compmode and getDistanceBetweenPoints3D(pos[1], pos[2], pos[3]+0.05, vx, vy, vz)<4 then
				setElementModel(g_Vehicle, g_Pickups[colshape].vehicle)
				triggerServerEvent('onPlayerPickUpRacePickupInternal', g_Me, pickup.id, pickup.respawn)
			end
        end
	end
	
	-- objects
	g_Objects = {}
	local pos, rot
	for i,object in ipairs(objects) do
		pos = object.position
		rot = object.rotation
		g_Objects[i] = createObject(object.model, pos[1], pos[2], pos[3], rot[1], rot[2], rot[3])
	end

	if #g_Checkpoints > 0 then
		g_CurrentCheckpoint = 0
		showNextCheckpoint()
	end
	
	g_HurryDuration = g_GameOptions.hurrytime
	if duration then
		launchRace(duration)
	end

    fadeCamera( false, 0.0 )

	-- Editor start
	if isEditor() then
		editorInitRace()
		return
	end
	
	delay = 2 -- FIXME
	-- Do fadeup and then tell server client is ready
    setTimer(fadeCamera, delay + 750, 1, true, 10.0)
    setTimer(fadeCamera, delay + 1500, 1, true, 2.0)

    setTimer( function() triggerServerEvent('onNotifyPlayerReady', g_Me) end, delay + 3500, 1 )
    outputDebug( 'MISC', 'initRace end' )
    setTimer( function() setCameraBehindVehicle( g_Vehicle ) end, delay + 300, 1 )
end

-- Called from the server when settings are changed
function updateOptions ( gameoptions, mapoptions )
	-- Update
	g_GameOptions = gameoptions
	g_MapOptions = mapoptions

	-- Apply
	updateVehicleWeapons()
	setCloudsEnabled(g_GameOptions.cloudsenable)
	setBlurLevel(g_GameOptions.blurlevel)
	if engineSetAsynchronousLoading then
		engineSetAsynchronousLoading( g_GameOptions.asyncloading )
	end
end

function launchRace(duration)
	g_Players = getElementsByType('player')
	
	triggerEvent("race.onRaceLaunch", resourceRoot, duration)
	
	setVehicleDamageProof(g_Vehicle, false)
	
	g_StartTick = getTickCount()
end


addEventHandler('onClientElementStreamIn', g_Root,
	function()
		local colshape = table.find(g_Pickups, 'object', source)
		if colshape then
			local pickup = g_Pickups[colshape]
			if pickup.label then
				pickup.label:color(255, 255, 255, 0)
				pickup.label:visible(false)
				pickup.labelInRange = false
			end
			g_VisiblePickups[colshape] = source
		end
	end
)

addEventHandler('onClientElementStreamOut', g_Root,
	function()
		local colshape = table.find(g_VisiblePickups, source)
		if colshape then
			local pickup = g_Pickups[colshape]
			if pickup.label then
				pickup.label:color(255, 255, 255, 0)
				pickup.label:visible(false)
				pickup.labelInRange = nil
			end
			g_VisiblePickups[colshape] = nil
		end
	end
)

function updatePickups()
	local angle = math.fmod((getTickCount() - g_PickupStartTick) * 360 / 2000, 360)
	local g_Pickups = g_Pickups
	local pickup, x, y, cX, cY, cZ, pickX, pickY, pickZ
	for colshape,elem in pairs(g_VisiblePickups) do
		pickup = g_Pickups[colshape]
		if pickup.load then
			setElementRotation(elem, 0, 0, angle)
			if pickup.label then
				cX, cY, cZ = getCameraMatrix()
				pickX, pickY, pickZ = unpack(pickup.position)
				if g_MapOptions.compmode then
					x, y = getScreenFromWorldPosition(pickX, pickY, pickZ + 2.75, 0.08 )
				else
					x, y = getScreenFromWorldPosition(pickX, pickY, pickZ + 2.85, 0.08 )
				end
				local distanceToPickup = getDistanceBetweenPoints3D(cX, cY, cZ, pickX, pickY, pickZ)
				if distanceToPickup > 80 then
					pickup.labelInRange = false
					pickup.label:visible(false)
				elseif x then
					if distanceToPickup < 60 then
						if isLineOfSightClear(cX, cY, cZ, pickX, pickY, pickZ+(g_MapOptions.compmode and 2.75 or 0), true, false, false, true, false) then
							if not pickup.labelInRange then
								if pickup.anim then
									pickup.anim:remove()
								end
								pickup.anim = Animation.createAndPlay(
									pickup.label,
									Animation.presets.dxTextFadeIn(500)
								)
								pickup.labelInRange = true
								pickup.labelVisible = true
							end
							if not pickup.labelVisible then
								pickup.label:color(255, 255, 255, 255)
							end
							pickup.label:visible(true)
						else
							pickup.label:color(255, 255, 255, 0)
							pickup.labelVisible = false
							pickup.label:visible(false)
						end
					else
						if pickup.labelInRange then
							if pickup.anim then
								pickup.anim:remove()
							end
							pickup.anim = Animation.createAndPlay(
								pickup.label,
								Animation.presets.dxTextFadeOut(1000)
							)
							pickup.labelInRange = false
							pickup.labelVisible = false
							pickup.label:visible(true)
						end
					end
					local scale = (60/distanceToPickup)*0.7
					pickup.label:scale(scale)
					pickup.label:position(x, y, false)
				else
					pickup.label:color(255, 255, 255, 0)
					pickup.labelVisible = false
					pickup.label:visible(false)
				end
				if Spectate.fadedout then
					pickup.label:visible(false)	-- Hide pickup labels when screen is black
				end
			end
		else
			if pickup.label then
				pickup.label:visible(false)
				if pickup.labelInRange then
					pickup.label:color(255, 255, 255, 0)
					pickup.labelInRange = false
				end
			end
		end
	end
end
addEventHandler('onClientRender', g_Root, updatePickups)

addEventHandler('onClientColShapeHit', g_Root,
	function(elem)
		local pickup = g_Pickups[source]
		outputDebug( 'CHECKPOINT', 'onClientColShapeHit'
						.. ' elem:' .. tostring(elem)
						.. ' g_Vehicle:' .. tostring(g_Vehicle)
						.. ' isVehicleBlown(g_Vehicle):' .. tostring(g_Vehicle and isVehicleBlown(g_Vehicle))
						.. ' g_Me:' .. tostring(g_Me)
						.. ' getElementHealth(g_Me):' .. tostring(getElementHealth(g_Me))
						.. ' source:' .. tostring(source)
						.. ' pickup:' .. tostring(pickup)
						)
		if elem ~= g_Vehicle or not pickup or isVehicleBlown(g_Vehicle) or getElementHealth(g_Me) == 0 then
			return
		end
		if pickup.load then
			handleHitPickup(pickup)
		end
	end
)

addEvent("onClientPlayerHitPickup")
function handleHitPickup(pickup)
	if pickup.type == 'vehiclechange' then
		local vehModel = tonumber(pickup.vehicle)
		if not vehModel or vehModel == getElementModel(g_Vehicle) then
			return
		end
		g_PrevVehicleHeight = getElementDistanceFromCentreOfMassToBaseOfModel(g_Vehicle)
		-- Delay vehicle change a bit (some maps doesn't like instant vehicle change)
		TimerManager.createTimerFor(g_Vehicle):setTimer(function()
			alignVehicleWithUp()
			setElementModel(g_Vehicle, vehModel)
			vehicleChanging(g_MapOptions.classicchangez, vehModel)
			if g_MapOptions.compmode then
				setVehicleAdjustableProperty ( g_Vehicle, 0 )
				setVehicleLandingGearDown ( g_Vehicle, true )
				-- helicopter rator speed is set leter
				for colshape, pickup in pairs ( g_Pickups ) do
					if pickup.type == 'nitro' and isElementWithinColShape ( g_Vehicle, colshape ) then
						-- trigger all nitro pickups because changing vehicle could have canceled their work
						addVehicleUpgrade(g_Vehicle, 1010)
						triggerServerEvent('onPlayerPickUpRacePickupInternal', g_Me, pickup.id, pickup.respawn)
					end
				end
			end
		end, 50, 1)
	elseif pickup.type == 'nitro' then
		addVehicleUpgrade(g_Vehicle, 1010)
	elseif pickup.type == 'repair' then
		fixVehicle(g_Vehicle)
	end
	triggerServerEvent('onPlayerPickUpRacePickupInternal', g_Me, pickup.id, pickup.respawn)
	triggerEvent("onClientPlayerHitPickup", g_Me, pickup.id, pickup.respawn)
end

function removeVehicleNitro()
	removeVehicleUpgrade(g_Vehicle, 1010)
end

function unloadPickup(pickupID)
	for colshape,pickup in pairs(g_Pickups) do
		if pickup.id == pickupID then
			pickup.load = false
			setElementAlpha(pickup.object, 0)
			return
		end
	end
end

function loadPickup(pickupID)
	for colshape,pickup in pairs(g_Pickups) do
		if pickup.id == pickupID then
			setElementAlpha(pickup.object, 255)
			pickup.load = true
			if isElementWithinColShape(g_Vehicle, colshape) then
				handleHitPickup(pickup)
			end
			return
		end
	end
end

function vehicleChanging( changez, newModel )
	if getElementModel(g_Vehicle) ~= newModel then
		outputConsole( "Vehicle change model mismatch (" .. tostring(getElementModel(g_Vehicle)) .. "/" .. tostring(newModel) .. ")" )
	end
	local newVehicleHeight = getElementDistanceFromCentreOfMassToBaseOfModel(g_Vehicle)
	local x, y, z = getElementPosition(g_Vehicle)
	if g_PrevVehicleHeight and (newVehicleHeight > g_PrevVehicleHeight or g_MapOptions.compmode) then
		z = z - g_PrevVehicleHeight + newVehicleHeight
	end
	if changez then
		if g_MapOptions.compmode then
			z = z + newVehicleHeight*2
		else
			z = z + 1
		end
	end
	setElementPosition(g_Vehicle, x, y, z)
	g_PrevVehicleHeight = nil
	updateVehicleWeapons()
	checkVehicleIsHelicopter()
end

function updateVehicleWeapons()
	if g_Vehicle then
		local weapons = not g_ArmedVehicleIDs[getElementModel(g_Vehicle)] or g_MapOptions.vehicleweapons
		toggleControl('vehicle_fire', weapons)
		if getElementModel(g_Vehicle) == g_HunterID and not g_MapOptions.hunterminigun then
			weapons = false
		end
		toggleControl('vehicle_secondary_fire', weapons)
	end
end

function vehicleUnloading()
	g_Vehicle = nil
end

addEventHandler('onClientElementDataChange', g_Me,
	function(dataName)
		if dataName == 'race rank' and not Spectate.active then
			setRankDisplay( getElementData(g_Me, 'race rank') )
		end
	end,
	false
)

function setRankDisplay( rank )
	triggerEvent("race.onRankChange", resourceRoot, rank)
end

addEventHandler('onClientElementDataChange', g_Root,
	function(dataName)
		if dataName == 'race.finished' then
			if isPlayerFinished(source) then
				Spectate.dropCamera( source, 2000 )
			end
		end
		if dataName == 'race.spectating' then
			if isPlayerSpectating(source) then
				Spectate.validateTarget( source )	-- No spectate at this player
			end
		end
	end
)

g_LastZ = false

function checkWater()
	if g_Vehicle then
		if g_MapOptions.compmode or not g_WaterCraftIDs[getElementModel(g_Vehicle)] then
			local x, y, z = getElementPosition(g_Me)
			if g_LastZ then
				local waterZ = getWaterLevel ( x, y, g_MapOptions.compmode and g_LastZ or z )
				if waterZ and z < waterZ - 0.5 and not isPlayerRaceDead(g_Me) and not isPlayerFinished(g_Me) and g_MapOptions then
					if g_MapOptions.firewater then
						blowVehicle ( g_Vehicle, true )
					else
						--setElementHealth(g_Me,0)
						triggerServerEvent('onRequestKillPlayer', g_Me, true)
					end
				end
			end
			g_LastZ = z
		end
		-- Check stalled vehicle
		if not getVehicleEngineState( g_Vehicle ) then
			setVehicleEngineState( g_Vehicle, true )
		end
		-- Check dead vehicle
		if getElementHealth( g_Vehicle ) == 0 and not isPlayerRaceDead(g_Me) and not isPlayerFinished(g_Me)then
			setElementHealth(g_Me,0)
			triggerServerEvent('onRequestKillPlayer',g_Me)
		end
	end
end

function showNextCheckpoint(bOtherPlayer)
	g_CurrentCheckpoint = g_CurrentCheckpoint + 1
	local i = g_CurrentCheckpoint
	if i > 1 then
		destroyCheckpoint(i-1)
	else
		createCheckpoint(1)
	end
	makeCheckpointCurrent(i,bOtherPlayer)
	if i < #g_Checkpoints then
		local curCheckpoint = g_Checkpoints[i]
		local nextCheckpoint = g_Checkpoints[i+1]
		local nextMarker = createCheckpoint(i+1)
		setMarkerTarget(curCheckpoint.marker, unpack(nextCheckpoint.position))
	end
	if not Spectate.active then
		setElementData(g_Me, 'race.checkpoint', i)
	end
end

-------------------------------------------------------------------------------
-- Show checkpoints and rank info that is relevant to the player being spectated
local prevWhich = nil
local cpValuePrev = nil
local rankValuePrev = nil

function updateSpectatingCheckpointsAndRank()
	local which = getWhichDataSourceToUse()

	-- Do nothing if we are keeping the last thing displayed
	if which == "keeplast" then
		return
	end

	local dataSourceChangedToLocal = which ~= prevWhich and which=="local"
	local dataSourceChangedFromLocal = which ~= prevWhich and prevWhich=="local"
	prevWhich = which

	if dataSourceChangedFromLocal or dataSourceChangedToLocal then
		cpValuePrev = nil
		rankValuePrev = nil
	end

	if Spectate.active or dataSourceChangedToLocal then
		local watchedPlayer = getWatchedPlayer()

		if g_CurrentCheckpoint and g_Checkpoints and #g_Checkpoints > 0 then
			local cpValue = getElementData(watchedPlayer, 'race.checkpoint') or 0
			if cpValue > 0 and cpValue <= #g_Checkpoints then
				if cpValue ~= cpValuePrev then
					cpValuePrev = cpValue
					setCurrentCheckpoint( cpValue, Spectate.active and watchedPlayer ~= g_Me )
				end
			end
		end

		local rankValue = getElementData(watchedPlayer, 'race rank') or 0
		if rankValue ~= rankValuePrev then
			rankValuePrev = rankValue
			setRankDisplay( rankValue )	
		end
	end
end

-- "local"			If not spectating
-- "spectarget"		If spectating valid target
-- "keeplast"		If spectating nil target and dropcam
-- "local"			If spectating nil target and no dropcam
function getWhichDataSourceToUse()
	if not Spectate.active			then	return "local"			end
	if Spectate.target				then	return "spectarget"		end
	if Spectate.hasDroppedCamera()	then	return "keeplast"		end
	return "local"
end

function getWatchedPlayer()
	if not Spectate.active			then	return g_Me				end
	if Spectate.target				then	return Spectate.target	end
	if Spectate.hasDroppedCamera()	then	return nil				end
	return g_Me
end
-------------------------------------------------------------------------------

addEvent("onClientPlayerReachCheckpoint")
function checkpointReached(elem)
	outputDebug( 'CP', 'checkpointReached'
					.. ' ' .. tostring(g_CurrentCheckpoint)
					.. ' elem:' .. tostring(elem)
					.. ' g_Vehicle:' .. tostring(g_Vehicle)
					.. ' isVehicleBlown(g_Vehicle):' .. tostring(isVehicleBlown(g_Vehicle))
					.. ' g_Me:' .. tostring(g_Me)
					.. ' getElementHealth(g_Me):' .. tostring(getElementHealth(g_Me))
					)
	if elem ~= g_Vehicle or isVehicleBlown(g_Vehicle) or getElementHealth(g_Me) == 0 or Spectate.active then
		return
	end
	
	local vehModel = tonumber(g_Checkpoints[g_CurrentCheckpoint].vehicle)
	if vehModel and vehModel ~= getElementModel(g_Vehicle) then
		g_PrevVehicleHeight = getElementDistanceFromCentreOfMassToBaseOfModel(g_Vehicle)
		alignVehicleWithUp()
		setElementModel(g_Vehicle, vehModel)
		vehicleChanging(g_MapOptions.classicchangez, vehModel)
	end
	triggerServerEvent('onPlayerReachCheckpointInternal', g_Me, g_CurrentCheckpoint)
	triggerEvent("onClientPlayerReachCheckpoint", g_Me, g_CurrentCheckpoint)
	
	if g_CurrentCheckpoint < #g_Checkpoints then
		showNextCheckpoint()
	else
		destroyCheckpoint(#g_Checkpoints)
        triggerEvent('onClientPlayerFinish', g_Me)
		toggleAllControls(false, true, false)
	end
end

function startHurry()
	triggerEvent("race.onStartHurry", resourceRoot, isPlayerFinished(g_Me))
end

function setTimeLeft(timeLeft)
	g_Duration = (getTickCount() - g_StartTick) + timeLeft
end

-----------------------------------------------------------------------
-- Spectate
-----------------------------------------------------------------------
Spectate = {}
Spectate.active = false
Spectate.target = nil
Spectate.blockUntilTimes = {}
Spectate.savePos = false
Spectate.manual = false
Spectate.droppedCameraTimer = Timer:create()
Spectate.tickTimer = Timer:create()
Spectate.fadedout = true
Spectate.blockManual = false
Spectate.blockManualTimer = nil


-- Request to switch on
function Spectate.start(type)
	outputDebug( 'SPECTATE', 'Spectate.start '..type )
	assert(type=='manual' or type=='auto', "Spectate.start : type == auto or manual")
	Spectate.blockManual = false
	if type == 'manual' then
		if Spectate.active then
			return					-- Ignore if manual request and already on
		end
		Spectate.savePos = true	-- Savepos and start if manual request and was off
	elseif type == 'auto' then
		Spectate.savePos = false	-- Clear restore pos if an auto spectate is requested
	end
	if not Spectate.active then
		Spectate._start()			-- Switch on here, if was off
	end
end


-- Request to switch off
function Spectate.stop(type)
	outputDebug( 'SPECTATE', 'Spectate.stop '..type )
	assert(type=='manual' or type=='auto', "Spectate.stop : type == auto or manual")
	if type == 'auto' then
		Spectate.savePos = false	-- Clear restore pos if an auto spectate is requested
	end
	if Spectate.active then
		Spectate._stop()			-- Switch off here, if was on
	end
end


function Spectate._start()
	outputDebug( 'SPECTATE', 'Spectate._start ' )
	triggerServerEvent('onClientNotifySpectate', g_Me, true )
	assert(not Spectate.active, "Spectate._start - not Spectate.active")
	
	if Spectate.savePos then
		savePosition()
	end
	Spectate.setTarget( Spectate.findNewTarget(g_Me,1) )
	bindKey('arrow_l', 'down', Spectate.previous)
	bindKey('arrow_r', 'down', Spectate.next)
	MovePlayerAway.start()
	Spectate.setTarget( Spectate.target )
    Spectate.validateTarget(Spectate.target)
	Spectate.tickTimer:setTimer( Spectate.tick, 500, 0 )
end

-- Stop spectating. Will restore position if Spectate.savePos is set
function Spectate._stop()
	Spectate.cancelDropCamera()
	Spectate.tickTimer:killTimer()
	triggerServerEvent('onClientNotifySpectate', g_Me, false )
	outputDebug( 'SPECTATE', 'Spectate._stop ' )
	assert(Spectate.active, "Spectate._stop - Spectate.active")
	unbindKey('arrow_l', 'down', Spectate.previous)
	unbindKey('arrow_r', 'down', Spectate.next)
	MovePlayerAway.stop()
	setCameraTarget(g_Me)
	Spectate.target = nil
	Spectate.active = false
	if Spectate.savePos then
		Spectate.savePos = false
		restorePosition()
	end
end

function Spectate.previous(bGUIFeedback)
	Spectate.setTarget( Spectate.findNewTarget(Spectate.target,-1) )
	if bGUIFeedback then
		triggerEvent("race.onSpecPrev", resourceRoot)
	end
end

function Spectate.next(bGUIFeedback)
	Spectate.setTarget( Spectate.findNewTarget(Spectate.target,1) )
	if bGUIFeedback then
		triggerEvent("race.onSpecNext", resourceRoot)
	end
end

---------------------------------------------
-- Step along to the next player to spectate
local playersRankSorted = {}
local playersRankSortedTime = 0

function Spectate.findNewTarget(current,dir)

	-- Time to update sorted list?
	local bUpdateSortedList = ( getTickCount() - playersRankSortedTime > 1000 )

	-- Need to update sorted list because g_Players has changed size?
	bUpdateSortedList = bUpdateSortedList or ( #playersRankSorted ~= #g_Players )

	if not bUpdateSortedList then
		-- Check playersRankSorted contains the same elements as g_Players
		for _,item in ipairs(playersRankSorted) do
			if not table.find(g_Players, item.player) then
				bUpdateSortedList = true
				break
			end
		end
	end

	-- Update sorted list if required
	if bUpdateSortedList then
		-- Remake list
		playersRankSorted = {}
		for _,player in ipairs(g_Players) do
			local rank = tonumber(getElementData(player, 'race rank')) or 0
			table.insert( playersRankSorted, {player=player, rank=rank} )
		end
		-- Sort it by rank
		table.sort(playersRankSorted, function(a,b) return(a.rank > b.rank) end)

		playersRankSortedTime = getTickCount()
	end

	-- Find next player in list
	local pos = table.find(playersRankSorted, 'player', current) or 1
	for i=1,#playersRankSorted do
		pos = ((pos + dir - 1) % #playersRankSorted ) + 1
		if Spectate.isValidTarget(playersRankSorted[pos].player) then
			return playersRankSorted[pos].player
		end
	end
	return nil
end
---------------------------------------------

function Spectate.isValidTarget(player)
	if player == nil then
		return true
	end
	if player == g_Me or isPlayerFinished(player) or isPlayerRaceDead(player) or isPlayerSpectating(player) then
		return false
	end
	if ( Spectate.blockUntilTimes[player] or 0 ) > getTickCount() then
		return false
	end
	if not table.find(g_Players, player) or not isElement(player) then
		return false
	end
	local x,y,z = getElementPosition(player)
	if z > 20000 then
		return false
	end
	if x > -1 and x < 1 and y > -1 and y < 1 then
		return false
	end
	return true
end

-- If player is the current target, check to make sure is valid
function Spectate.validateTarget(player)
	if Spectate.active and player == Spectate.target then
		if not Spectate.isValidTarget(player) then
			Spectate.previous(false)
		end
	end
end

function Spectate.dropCamera( player, time )
	if Spectate.active and player == Spectate.target then
		if not Spectate.hasDroppedCamera() then
			setCameraMatrix( getCameraMatrix() )
			Spectate.target = nil
			Spectate.droppedCameraTimer:setTimer(Spectate.cancelDropCamera, time, 1, player )
		end
	end
end

function Spectate.hasDroppedCamera()
	return Spectate.droppedCameraTimer:isActive()
end

function Spectate.cancelDropCamera()
	if Spectate.hasDroppedCamera() then
		Spectate.droppedCameraTimer:killTimer()
		Spectate.tick()
	end
end

function Spectate.setTarget( player )
	if Spectate.hasDroppedCamera() then
		return
	end
	
	Spectate.active = true
	Spectate.target = player
	if Spectate.target then
		if Spectate.getCameraTargetPlayer() ~= Spectate.target then
			setCameraTarget(Spectate.target)
		end
		
	else
		local x,y,z = getElementPosition(g_Me)
		x = x - ( x % 32 )
		y = y - ( y % 32 )
		z = getGroundPosition ( x, y, 5000 ) or 40
		setCameraTarget( g_Me )
		setCameraMatrix( x,y,z+10,x,y+50,z+60)
	end
	
	local joinBtn = false
	if Spectate.active and Spectate.savePos then
		joinBtn = true
	end
	
	triggerEvent("race.onSpecTargetChange", resourceRoot, Spectate.target, joinBtn)
end

function Spectate.blockAsTarget( player, ticks )
	Spectate.blockUntilTimes[player] = getTickCount() + ticks
	Spectate.validateTarget(player)
end

function Spectate.tick()
	if Spectate.target and Spectate.getCameraTargetPlayer() and Spectate.getCameraTargetPlayer() ~= Spectate.target then
		if Spectate.isValidTarget(Spectate.target) then
			setCameraTarget(Spectate.target)
			return
		end
	end
	if not Spectate.target or ( Spectate.getCameraTargetPlayer() and Spectate.getCameraTargetPlayer() ~= Spectate.target ) or not Spectate.isValidTarget(Spectate.target) then
		Spectate.previous(false)
	end
end

function Spectate.getCameraTargetPlayer()
	local element = getCameraTarget()
	if element and getElementType(element) == "vehicle" then
		element = getVehicleController(element)
	end
	return element
end


g_SavedPos = {}
function savePosition()
	g_SavedPos.x, g_SavedPos.y, g_SavedPos.z = getElementPosition(g_Me)
	g_SavedPos.rz = getPedRotation(g_Me)
	g_SavedPos.vx, g_SavedPos.vy, g_SavedPos.vz = getElementPosition(g_Vehicle)
	g_SavedPos.vrx, g_SavedPos.vry, g_SavedPos.vrz = getElementRotation(g_Vehicle)
end

function restorePosition()
	setElementPosition( g_Me, g_SavedPos.x, g_SavedPos.y, g_SavedPos.z )
	setPedRotation( g_Me, g_SavedPos.rz )
	setElementPosition( g_Vehicle, g_SavedPos.vx, g_SavedPos.vy, g_SavedPos.vz )
	setElementRotation( g_Vehicle, g_SavedPos.vrx, g_SavedPos.vry, g_SavedPos.vrz )
end

addEvent ( "onClientPreRender", true )
addEventHandler ( "onClientPreRender", g_Root,
	function()
		if isPlayerRaceDead( g_Me ) then
			setCameraMatrix( getCameraMatrix() )
		elseif g_MapOptions and g_MapOptions.compmode and g_Vehicle then
			local x, y, z = getElementPosition ( g_Vehicle )
			if z < -50 then setElementPosition ( g_Vehicle, x, y, -50 ) end
		end
		updateSpectatingCheckpointsAndRank()
	end
)

-----------------------------------------------------------------------

-----------------------------------------------------------------------
-- MovePlayerAway - Super hack - Fixes the spec cam problem
-----------------------------------------------------------------------
MovePlayerAway = {}
MovePlayerAway.timer = Timer:create()
MovePlayerAway.posX = 0
MovePlayerAway.posY = 0
MovePlayerAway.posZ = 0
MovePlayerAway.rotZ = 0
MovePlayerAway.health = 0

function MovePlayerAway.start()
	local element = g_Vehicle or getPedOccupiedVehicle(g_Me) or g_Me
	MovePlayerAway.posX, MovePlayerAway.posY, MovePlayerAway.posZ = getElementPosition(element)
	MovePlayerAway.posZ = 34567 + math.random(0,4000)
	MovePlayerAway.rotZ = 0
	MovePlayerAway.health = math.max(1,getElementHealth(element))
	setElementHealth( element, 2000 )
	setElementHealth( g_Me, 90 )
	MovePlayerAway.update(true)
	MovePlayerAway.timer:setTimer(MovePlayerAway.update,500,0)
	triggerServerEvent("onRequestMoveAwayBegin", g_Me)
end


function MovePlayerAway.update(nozcheck)
	-- Move our player far away
	local camTarget = getCameraTarget()
	if not getPedOccupiedVehicle(g_Me) then
		setElementPosition( g_Me, MovePlayerAway.posX-10, MovePlayerAway.posY-10, MovePlayerAway.posZ )
	end
	if getPedOccupiedVehicle(g_Me) then
		if not nozcheck then
			if camTarget then
				MovePlayerAway.posX, MovePlayerAway.posY = getElementPosition(camTarget)
				if getElementType(camTarget) ~= "vehicle" then
					outputDebug( 'SPECTATE', 'camera target type:' .. getElementType(camTarget) )
				end
				if getElementType(camTarget) == 'ped' then
					MovePlayerAway.rotZ = getPedRotation(camTarget)
				else
					_,_, MovePlayerAway.rotZ = getElementRotation(camTarget)
				end
			end  
		end
		local vehicle = g_Vehicle
		if vehicle then
			fixVehicle( vehicle )
			setElementFrozen ( vehicle, true )
			setElementPosition( vehicle, MovePlayerAway.posX, MovePlayerAway.posY, MovePlayerAway.posZ )
			setElementVelocity( vehicle, 0,0,0 )
			setVehicleTurnVelocity( vehicle, 0,0,0 )
			setElementRotation ( vehicle, 0,0,MovePlayerAway.rotZ )
		end
	end
	setElementHealth( g_Me, 90 )

	if camTarget and camTarget ~= getCameraTarget() then
		setCameraTarget(camTarget)
	end
end

function MovePlayerAway.stop()
	triggerServerEvent("onRequestMoveAwayEnd", g_Me)
	if MovePlayerAway.timer:isActive() then
		MovePlayerAway.timer:killTimer()
		local vehicle = g_Vehicle
		if vehicle then
			setElementVelocity( vehicle, 0,0,0 )
			setVehicleTurnVelocity( vehicle, 0,0,0 )
			setElementFrozen ( vehicle, false )
			setVehicleDamageProof ( vehicle, false )
			setElementHealth ( vehicle, MovePlayerAway.health )
		end
		setElementVelocity( g_Me, 0,0,0 )
	end
end

-----------------------------------------------------------------------
-- Camera transition for our player's respawn
-----------------------------------------------------------------------
function remoteStopSpectateAndBlack()
	Spectate.stop('auto')
	fadeCamera(false,0.0, 0,0,0)			-- Instant black
end

function remoteSoonFadeIn( bNoCameraMove )
    setTimer(fadeCamera,250+500,1,true,1.0)		-- And up
	if not bNoCameraMove then
		setTimer( function() setCameraBehindVehicle( g_Vehicle ) end ,250+500-150,1 )
	end
	setTimer(checkVehicleIsHelicopter,250+500,1)
end
-----------------------------------------------------------------------

function raceTimeout()
	if g_CurrentCheckpoint then
		destroyCheckpoint(g_CurrentCheckpoint)
		destroyCheckpoint(g_CurrentCheckpoint + 1)
	end
	triggerEvent("onClientPlayerOutOfTime", g_Me)
	toggleAllControls(false, true, false)
end

function unloadAll()
    triggerEvent('onClientMapStopping', g_Me)
	for i=1,#g_Checkpoints do
		destroyCheckpoint(i)
	end
	g_Checkpoints = {}
	g_CurrentCheckpoint = nil
	
	for colshape,pickup in pairs(g_Pickups) do
		destroyElement(colshape)
		if pickup.object then
			destroyElement(pickup.object)
		end
		if pickup.label then
			pickup.label:destroy()
		end
	end
	g_Pickups = {}
	g_VisiblePickups = {}
	
	table.each(g_Objects, destroyElement)
	g_Objects = {}
	
	setElementData(g_Me, 'race.checkpoint', nil)
	
	g_Vehicle = nil
	
	toggleAllControls(true)
	
	TimerManager.destroyTimersFor("map")
	g_StartTick = nil
	g_HurryDuration = nil
	if Spectate.active then
		Spectate.stop('auto')
	end
end

function createCheckpoint(i)
	local checkpoint = g_Checkpoints[i]
	if checkpoint.marker then
		return
	end
	local pos = checkpoint.position
	local color = checkpoint.color or { 0, 0, 255 }
	checkpoint.marker = createMarker(pos[1], pos[2], pos[3], checkpoint.type or 'checkpoint', checkpoint.size, color[1], color[2], color[3])
	if (not checkpoint.type or checkpoint.type == 'checkpoint') and i == #g_Checkpoints then
		setMarkerIcon(checkpoint.marker, 'finish')
	end
	if checkpoint.type == 'ring' and i < #g_Checkpoints then
		setMarkerTarget(checkpoint.marker, unpack(g_Checkpoints[i+1].position))
	end
	checkpoint.blip = createBlip(pos[1], pos[2], pos[3], 0, isCurrent and 2 or 1, color[1], color[2], color[3])
	setBlipOrdering(checkpoint.blip, 1)
	return checkpoint.marker
end

function makeCheckpointCurrent(i,bOtherPlayer)
	local checkpoint = g_Checkpoints[i]
	local pos = checkpoint.position
	local color = checkpoint.color or { 255, 0, 0 }
	if not checkpoint.blip then
		checkpoint.blip = createBlip(pos[1], pos[2], pos[3], 0, 2, color[1], color[2], color[3])
		setBlipOrdering(checkpoint.blip, 1)
	else
		setBlipSize(checkpoint.blip, 2)
	end
	
	if not checkpoint.type or checkpoint.type == 'checkpoint' then
		checkpoint.colshape = createColCircle(pos[1], pos[2], checkpoint.size + 4)
	else
		checkpoint.colshape = createColSphere(pos[1], pos[2], pos[3], checkpoint.size + 4)
	end
	if not bOtherPlayer then
		addEventHandler('onClientColShapeHit', checkpoint.colshape, checkpointReached)
	end
end

function destroyCheckpoint(i)
	local checkpoint = g_Checkpoints[i]
	if checkpoint and checkpoint.marker then
		destroyElement(checkpoint.marker)
		checkpoint.marker = nil
		destroyElement(checkpoint.blip)
		checkpoint.blip = nil
		if checkpoint.colshape then
			destroyElement(checkpoint.colshape)
			checkpoint.colshape = nil
		end
	end
end

function setCurrentCheckpoint(i, bOtherPlayer)
	destroyCheckpoint(g_CurrentCheckpoint)
	destroyCheckpoint(g_CurrentCheckpoint + 1)
	createCheckpoint(i)
	g_CurrentCheckpoint = i - 1
	showNextCheckpoint(bOtherPlayer)
end

function isPlayerRaceDead(player)
	return not getElementHealth(player) or getElementHealth(player) < 1e-45 or isPlayerDead(player)
end

function isPlayerFinished(player)
	return getElementData(player, 'race.finished')
end

function isPlayerSpectating(player)
	return getElementData(player, 'race.spectating')
end

addEventHandler('onClientPlayerJoin', g_Root,
	function()
		table.insertUnique(g_Players, source)
	end
)

addEventHandler('onClientPlayerSpawn', g_Root,
	function()
		Spectate.blockAsTarget( source, 2000 )	-- No spectate at this player for 2 seconds
    end
)

addEventHandler('onClientPlayerWasted', g_Root,
	function()
		if not g_StartTick then
			return
		end
		local player = source
		local vehicle = getPedOccupiedVehicle(player)
		if player == g_Me then
			if #g_Players > 1 and (g_MapOptions.respawn == 'none' or g_MapOptions.respawntime >= 10000) then
				if Spectate.blockManualTimer and isTimer(Spectate.blockManualTimer) then
					killTimer(Spectate.blockManualTimer)
				end
				TimerManager.createTimerFor("map"):setTimer(Spectate.start, 2000, 1, 'auto')
			end
		else
			Spectate.dropCamera( player, 1000 )
		end
	end
)

addEventHandler('onClientPlayerQuit', g_Root,
	function()
		table.removevalue(g_Players, source)
		Spectate.blockUntilTimes[source] = nil
		Spectate.validateTarget(source)		-- No spectate at this player
	end
)

addEventHandler('onClientResourceStop', g_ResRoot,
	function()
		unloadAll()
		killTimer(g_WaterCheckTimer)
		setPedCanBeKnockedOffBike(g_Me, true)
	end
)

------------------------
-- Make vehicle upright

function directionToRotation2D( x, y )
	return rem( math.atan2( y, x ) * (360/6.28) - 90, 360 )
end

function alignVehicleWithUp()
	local vehicle = g_Vehicle
	if not vehicle then return end

	local matrix = getElementMatrix( vehicle )
	local Right = Vector3D:new( matrix[1][1], matrix[1][2], matrix[1][3] )
	local Fwd	= Vector3D:new( matrix[2][1], matrix[2][2], matrix[2][3] )
	local Up	= Vector3D:new( matrix[3][1], matrix[3][2], matrix[3][3] )

	local Velocity = Vector3D:new( getElementVelocity( vehicle ) )
	local rz

	if Velocity:Length() > 0.05 and Up.z < 0.001 then
		-- If velocity is valid, and we are upside down, use it to determine rotation
		rz = directionToRotation2D( Velocity.x, Velocity.y )
	else
		-- Otherwise use facing direction to determine rotation
		rz = directionToRotation2D( Fwd.x, Fwd.y )
	end

	setElementRotation( vehicle, 0, 0, rz )
end


------------------------
-- Script integrity test

setTimer(
	function ()
		if g_Vehicle and not isElement(g_Vehicle) then
			outputChatBox( "Race integrity test fail (client): Your vehicle has been destroyed. Please panic." )
			g_Vehicle = getPedOccupiedVehicle ( g_Me )
		end
	end,
	1000,0
)

---------------------------------------------------------------------------
--
-- Commands and binds
--
--
--
---------------------------------------------------------------------------

function oldSuicideKey ()
	if ( not isPlayerRaceDead ( g_Me ) ) then
		triggerServerEvent ( "onServerCall_race", g_Me, "showMessage", "Press K to kill yourself!", 255, 0, 0, g_Me )
	end
end

function kill()
	if Spectate.active then
		if Spectate.savePos then
			triggerServerEvent('onClientRequestSpectate', g_Me, false )
		end
    else
		Spectate.blockManual = true
		triggerServerEvent('onRequestKillPlayer', g_Me)
		Spectate.blockManualTimer = setTimer(function() Spectate.blockManual = false end, 3000, 1)
	end
end
addCommandHandler('kill',kill)
addCommandHandler('Commit suicide',kill)

local key = getKeyBoundToCommand("Commit suicide") or "k"
bindKey(key, "down", "Commit suicide")

if(key == "k") then
	bindKey ( next(getBoundKeys"enter_exit"), "down", oldSuicideKey )
end

function spectate()
	if Spectate.active then
		if Spectate.savePos then
			triggerServerEvent('onClientRequestSpectate', g_Me, false )
		end
	else
		if not Spectate.blockManual then
			triggerServerEvent('onClientRequestSpectate', g_Me, true )
		end
	end
end
addCommandHandler('spectate',spectate)
addCommandHandler('Toggle spectator',spectate)
bindKey("b","down","Toggle spectator")

function setPipeDebug(bOn)
    g_bPipeDebug = bOn
    outputConsole( 'bPipeDebug set to ' .. tostring(g_bPipeDebug) )
end

