local g_Me = getLocalPlayer ()
local g_Root = getRootElement ()
local g_ResRoot = getResourceRootElement ()
local g_Debug = true
local g_DbgX = 500
local g_DbgY = 10
local g_Range = 200

local function ApInit ()
	
end

local function VecAdd ( vec1, vec2 )
	return { vec1[1] + vec2[1], vec1[2] + vec2[2], vec1[3] + vec2[3] }
end

local function VecSub ( vec1, vec2 )
	return { vec1[1] - vec2[1], vec1[2] - vec2[2], vec1[3] - vec2[3] }
end

local function VecLen2 ( vec )
	return vec[1] ^ 2 + vec[2] ^ 2 + vec[3] ^ 2
end

local function VecLen ( vec )
	return VecLen2 ( vec ) ^ 0.5
end

local function VecMult ( vec, a )
	return { vec[1] * a, vec[2] * a, vec[3] * a }
end

local function MatMultVec ( mat, vec )
	local ret = {}
	for i = 1, 3, 1 do
		local row = mat[i]
		ret[i] = row[1] * vec[1] + row[2] * vec[2] + row[3] * vec[3]
	end
	return ret
end

local function ApRayCast ( vec1, vec2 )
	local hit, x, y, z = processLineOfSight ( vec1[1], vec1[2], vec1[3], vec2[1], vec2[2], vec2[3] )
	
	if ( g_Debug ) then
		dxDrawLine3D ( vec1[1], vec1[2], vec1[3], vec2[1], vec2[2], vec2[3], hit and 0xFFFF0000 or 0xFFFFFFFF )
	end
	
	if ( not hit ) then return false end
	
	local hit_pos = { x, y, z }
	local dist = VecLen ( VecSub ( vec1, hit_pos ) )
	return dist
end

local function ApCheckForWall ( pos, target, up )
	local up2 = VecMult ( up, 0.3 )
	local pos2 = VecAdd ( pos, up2 )
	local target2 = VecAdd ( target, up2 )
	
	local dist = ApRayCast ( pos, target )
	local dist2 = ApRayCast ( pos2, target2 )
	
	if ( not dist or not dist2 ) then
		return false
	end
	
	local diff = dist2 - dist
	if ( diff < 0.1 ) then
		return dist
	end
	
	return false
end

local function ApUpdate ()
	local veh = getPedOccupiedVehicle ( g_Me )
	if ( not veh ) then return end
	
	local pos = { getElementPosition ( veh ) }
	local vel = { getElementVelocity ( veh ) }
	local mat = getElementMatrix ( veh )
	local loc_vel = MatMultVec ( mat, vel )
	local speed = loc_vel[2] * 50
	
	local right = mat[1]
	local fw = mat[2]
	local up = mat[3]
	
	local pos2 = VecAdd ( pos, VecMult ( fw, 3 ) )
	local fw2 = VecAdd ( pos, VecMult ( fw, g_Range ) )
	
	local wall1_dist = ApCheckForWall ( pos2, fw2, up ) or math.huge
	local wall2_dist = ApCheckForWall ( VecAdd ( pos2, right ), VecAdd ( fw2, right ), up ) or math.huge
	local wall3_dist = ApCheckForWall ( VecSub ( pos2, right ), VecSub ( fw2, right ), up ) or math.huge
	local wall_dist = math.min ( wall1_dist, wall1_dist, wall3_dist )
	local wall = wall_dist < math.huge
	
	if ( g_Debug ) then
		dxDrawText ( "Wall distance: "..tostring ( wall_dist ), g_DbgX, g_DbgY + 0 )
		dxDrawText ( "Speed: "..tostring ( speed ), g_DbgX, g_DbgY + 10 )
	end
	
	local brake = false
	local accel = true
	local turn_r = false
	local turn_l = false
	
	if ( wall and speed > 0 ) then
		local t = wall_dist / speed
		if ( wall_dist < 1 or t < 1 ) then
			if ( speed > 1 ) then
				brake = true
			end
			accel = false
		end
		dxDrawText ( "Time to crash: "..tostring ( t ), g_DbgX, g_DbgY + 20 )
	elseif ( wall_dist < 1 ) then
		accel = false
	end
	
	local fw_right = VecAdd ( fw2, VecMult ( right, g_Range / 3 ) )
	local fw_left = VecSub ( fw2, VecMult ( right, g_Range / 3 ) )
	local wall_right_dist = ApCheckForWall ( pos2, fw_right, up ) or math.huge
	local wall_left_dist = ApCheckForWall ( pos2, fw_left, up ) or math.huge
	
	if ( wall and wall_right_dist > wall_dist and wall_right_dist > wall_left_dist ) then
		turn_r = true
	elseif ( wall and wall_left_dist > wall_dist and wall_left_dist > wall_right_dist ) then
		turn_l = true
	end
	
	if ( g_Debug ) then
		dxDrawText ( "Accelerate: "..tostring ( accel ), g_DbgX, g_DbgY + 30 )
		dxDrawText ( "Break: "..tostring ( brake ), g_DbgX, g_DbgY + 40 )
		dxDrawText ( "Turn right: "..tostring ( turn_r ), g_DbgX, g_DbgY + 50 )
		dxDrawText ( "Turn left: "..tostring ( turn_l ), g_DbgX, g_DbgY + 60 )
	end
	
	if ( true ) then
		setControlState ( "accelerate", accel )
		setControlState ( "brake_reverse", brake )
		setControlState ( "vehicle_right", turn_r )
		setControlState ( "vehicle_left", turn_l )
	end
end

addEventHandler ( "onResourceStart", g_ResRoot, ApInit )
addEventHandler ( "onClientRender", g_Root, ApUpdate )
