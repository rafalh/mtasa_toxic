---------------------------------------------------------------------------
-- Math extentions
---------------------------------------------------------------------------
function math.lerp(from,to,alpha)
	return from + (to-from) * alpha
end

function math.clamp(low,value,high)
	return math.max(low,math.min(value,high))
end

function math.wrap(low,value,high)
	while value > high do
		value = value - (high-low)
	end
	while value < low do
		value = value + (high-low)
	end
	return value
end

function math.wrapdifference(low,value,other,high)
	return math.wrap(low,value-other,high)+other
end
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- Camera
---------------------------------------------------------------------------
function getCameraRot()
	local px, py, pz, lx, ly, lz = getCameraMatrix()
	local rotz = math.atan2 ( ( lx - px ), ( ly - py ) )
 	local rotx = math.atan2 ( lz - pz, getDistanceBetweenPoints2D ( lx, ly, px, py ) )
 	return math.deg(rotx), 180, -math.deg(rotz)
end
---------------------------------------------------------------------------
