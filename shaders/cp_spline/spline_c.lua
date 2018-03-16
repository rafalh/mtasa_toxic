

local COLOR = { getColorFromString('#C0C0C0FF') }
local WIDTH = 10
local SEGMENTS = 16

local g_checkpoints = {}
local g_effectName = { "CP Spline", pl = "Krzywa CP" }
local g_autoEnable = false
local g_enabled = false
local g_changed = false
local g_lastCpIdx
local g_cachedSplines

-- P_B - point before
-- P_A - point after
-- Algo: https://stackoverflow.com/questions/3526940/how-to-create-a-cubic-bezier-curve-when-given-n-points-in-3d

local function calcControlPoints(P_B, P0, P1, P_A)
	local C0, D0 = {}, {}
	for i = 1, 3 do
		C0[i] = (P0[i] + (P1[i] - P_B[i]) / 6)
		D0[i] = (P1[i] - (P_A[i] - P0[i]) / 6)
	end
	return C0, D0
end

local function bezierCubicSpline(P0, C0, D0, P1, t)
	local b0 = (1-t)^3
	local b1 = 3 * (1-t)^2 * t
	local b2 = 3 * (1-t) * t^2
	local b3 = t^3
	local P = {}
	for i = 1, 3 do
		P[i] = b0 * P0[i] + b1 * C0[i] + b2 * D0[i] + b3 * P1[i]
	end
	return P
end

local function calcSplineSegments(P_B, P0, P1, P_A, alpha0, alpha1)
	local C0, D0 = calcControlPoints(P_B, P0, P1, P_A)
	local prevPoint = P0
	local t = 1/SEGMENTS
	local segmentsTbl = {}

	while t <= 1 do
		local nextPoint = bezierCubicSpline(P0, C0, D0, P1, t)
		local groundZ = getGroundPosition(nextPoint[1], nextPoint[2], nextPoint[3])
		if groundZ == 0 then
			groundZ = getGroundPosition(nextPoint[1], nextPoint[2], nextPoint[3] + 100)
			if groundZ ~= 0 then
				nextPoint[3] = groundZ + 1
			end
		elseif nextPoint[3] < groundZ + 1 then
			nextPoint[3] = groundZ + 1
		end
		local a = alpha0*(1-t) + alpha1*t
		local rgba = { unpack(COLOR) }
		rgba[4] = math.max(math.min(rgba[4] * a, 255), 0)
		local color = tocolor(unpack(rgba))
		table.insert(segmentsTbl, {prevPoint[1], prevPoint[2], prevPoint[3], nextPoint[1], nextPoint[2], nextPoint[3], color, WIDTH})
		prevPoint = nextPoint
		t = t + 1/SEGMENTS
	end
	return segmentsTbl
end

local function calcSplineSegmentsForElements(elB, el0, el1, elA, alpha0, alpha1)
	if not isElement(el0) or not isElement(el1) then return end
	if not isElement(elB) then elB = el0 end
	if not isElement(elA) then elA = el1 end
	local P0 = { getElementPosition(el0) }
	local P1 = { getElementPosition(el1) }
	local P_B = { getElementPosition(elB) }
	local P_A = { getElementPosition(elA) }
	P0[3] = P0[3] + 1
	P1[3] = P1[3] + 1
	P_B[3] = P_B[3] + 1
	P_A[3] = P_A[3] + 1
	return calcSplineSegments(P_B, P0, P1, P_A, alpha0, alpha1)
	
end

local function onClientRender()
	local target = getCameraTarget()
	if target and getElementType(target) == 'vehicle' then
		target = getVehicleOccupant(target)
	end
	if target then
		-- cpIdx is index of next CP (1 at spawnpoint)
		local cpIdx = getElementData(target, 'race.checkpoint')
		if cpIdx then
			if cpIdx ~= g_lastCpIdx then
				--outputDebugString('cp changed', 3)
				g_lastCpIdx = cpIdx
				g_cachedSplines = {}
				local splines = g_cachedSplines
				-- cpIdx-2 - cpIdx-1 (fading)
				splines[#splines+1] = calcSplineSegmentsForElements(g_checkpoints[cpIdx-3], g_checkpoints[cpIdx-2], g_checkpoints[cpIdx-1], g_checkpoints[cpIdx], 0, 1)
				-- target - cpIdx
				splines[#splines+1] = calcSplineSegmentsForElements(g_checkpoints[cpIdx-2], g_checkpoints[cpIdx-1], g_checkpoints[cpIdx], g_checkpoints[cpIdx+1], 1, 1)
				-- cpIdx - cpIdx+1 (fading)
				splines[#splines+1] = calcSplineSegmentsForElements(g_checkpoints[cpIdx-1], g_checkpoints[cpIdx], g_checkpoints[cpIdx+1], g_checkpoints[cpIdx+2], 1, 0)
			end
			for _, spline in ipairs(g_cachedSplines) do
				for i, segm in ipairs(spline) do
					dxDrawLine3D(unpack(segm))
				end
			end
        end
	end
end

local function loadCheckpoints()
	local checkpoints = getElementsByType('checkpoint')
	local idToCp = {}
	local cpToIndex = {}
	
	for i, cp in ipairs(checkpoints) do
		local id = getElementID(cp)
		assert(not idToCp[id])
		idToCp[id] = cp
		cpToIndex[cp] = i
	end
	
	g_checkpoints = {}
	
	local cp = checkpoints[1]
	while cp do
		table.insert(g_checkpoints, cp)
		local nextId = getElementData(cp, 'nextid')
		local nextCp = idToCp[nextId]
		if not nextCp then
			local i = cpToIndex[cp]
			nextCp = checkpoints[i + 1]
		end
		
		idToCp[nextId] = nil -- dont hang
		cp = nextCp
	end
	
	--outputDebugString("Loaded "..#g_Checkpoints.." CPs")
end

local function resetData()
	g_checkpoints = {}
	g_cachedSplines = {}
	g_lastCpIdx = nil
end

local function onClientResourceStart()
	resetData()
	loadCheckpoints()
end

addEvent('onRafalhAddEffect')
addEvent('onRafalhGetEffects')

function setEffectEnabled(enable)
	g_changed = true
	if enable == g_enabled then return true end
	g_enabled = enable
	
	if not enable then
        removeEventHandler('onClientRender', root, onClientRender)
		removeEventHandler('onClientResourceStart', root, onClientResourceStart)
		resetData()
    else
        addEventHandler('onClientRender', root, onClientRender)
		addEventHandler('onClientResourceStart', root, onClientResourceStart)
		loadCheckpoints()
	end
	
	return true
end

function isEffectEnabled()
	return g_enabled
end

local function initDelayed()
	if not g_changed then
		setEffectEnabled(g_autoEnable)
	end
end

addEventHandler('onClientResourceStart', resourceRoot, function ()
	setTimer(initDelayed, 1000, 1)
	triggerEvent('onRafalhAddEffect', root, resource, g_effectName)
	addEventHandler('onRafalhGetEffects', root, function ()
		triggerEvent('onRafalhAddEffect', root, resource, g_effectName)
	end)
end)
