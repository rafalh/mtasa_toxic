Quaternion = Class('Quaternion')

function Quaternion.__mt.__index:transform(vec)
	assert(vec.cls == Vector3)
	
    local xx = self[1] * self[1] local yy = self[2] * self[2] local zz = self[3] * self[3]
    local xy = self[1] * self[2] local xz = self[1] * self[3]
    local yz = self[2] * self[3] local wx = self[4] * self[1]
    local wy = self[4] * self[2] local wz = self[4] * self[3]

	local x =
		(1.0 - 2.0 * ( yy + zz )) * vec[1] +
		(2.0 * ( xy - wz )) * vec[2]  +
		(2.0 * ( xz + wy )) * vec[3];
	local y =
		(2.0 * ( xy + wz )) * vec[1] +
		(1.0 - 2.0 * ( xx + zz )) * vec[2] +
		(2.0 * ( yz - wx )) *vec[3];
	local z =
		(2.0 * ( xz - wy )) * vec[1] +
		(2.0 * ( yz + wx )) * vec[2] +
		(1.0 - 2.0 * ( xx + yy )) * vec[3];
	return Vector3(x, y, z)
end

function Quaternion.__mt.__index:dot(vec)
	return self[1]*vec[1] + self[2]*vec[2] + self[3]*vec[3] + self[4]*vec[4]
end

function Quaternion.__mt.__index:len()
	return (self[1]^2 + self[2]^2 + self[3]^2 + self[4]^2)^0.5
end

function Quaternion.__mt.__index:normalized()
	local len = self:len()
	return Quaternion(self[1] / n, self[2] / n, self[3] / n, self[4] / n)
end

function Quaternion.__mt:__unm()
	return Quaternion(-self[1], -self[2], -self[3], -self[4])
end

function Quaternion.__mt.__mul(a, b)
	if(type(b) ~= 'table') then
		return Quaternion(a[1]*b, a[2]*b, a[3]*b, a[4]*b)
	elseif(type(a) ~= 'table') then
		return Quaternion(b[1]*a, b[2]*a, b[3]*a, b[4]*a)
	else
		--assert(a.cls == Quaternion and b.cls == Quaternion, tostring(a.cls)..' '..tostring(b.cls))
		local x = a[4]*b[1] + a[1]*b[4] + a[2]*b[3] - a[3]*b[2];
		local y = a[4]*b[2] + a[2]*b[4] + a[3]*b[1] - a[1]*b[3];
		local z = a[4]*b[3] + a[3]*b[4] + a[1]*b[2] - a[2]*b[1];
		local w = a[4]*b[4] - a[1]*b[1] - a[2]*b[2] - a[3]*b[3];
		return Quaternion(x, y, z, w)
	end
end

function Quaternion.__mt:__eq(vec)
	return self[1] == vec[1] and self[2] == vec[2] and self[3] == vec[3] and self[4] == vec[4]
end

function Quaternion.__mt:__tostring()
	return '('..tostring(self[1])..' '..tostring(self[2])..' '..tostring(self[3])..' '..tostring(self[4])..')'
end

function Quaternion.__mt.__index:init(x, y, z, w)
	self[1] = x or 0
	self[2] = y or 0
	self[3] = z or 0
	self[4] = w or 0
end

function Quaternion.fromRot(axis, angle)
	assert(axis.cls == Vector3)
	local s = math.sin(angle/2);
	local x = s * axis[1];
	local y = s * axis[2];
	local z = s * axis[3];
	local w = math.cos(angle/2);
	return Quaternion(x, y, z, w)
end

function Quaternion.slerp(q1, q2, t)
	local cosOmega = q1:dot(q2)
	if(cosOmega < 0.0) then
		q2 = -q2
		cosOmega = -cosOmega
	end
	
	local k1, k2
	if(cosOmega > 0.9999) then
		k1 = 1.0 - t
		k2 = t
	else
		local sinOmega = (1.0 - cosOmega^2)^0.5
		local omega = math.atan2(sinOmega, cosOmega)
		local oneOverSinOmega = 1.0 / sinOmega
		k1 = math.sin((1.0 - t) * omega) * oneOverSinOmega
		k2 = math.sin(t*omega) * oneOverSinOmega
	end
	local x = q1[1]*k1 + q2[1]*k2
	local y = q1[2]*k1 + q2[2]*k2
	local z = q1[3]*k1 + q2[3]*k2
	local w = q1[4]*k1 + q2[4]*k2
	return Quaternion(x, y, z, w)
end

Quaternion.IDENTITY = Quaternion(0, 0, 0, 1)

-- Simple test
#local TEST = false
#if(TEST) then
	Test.register('Quaternion', function()
		Test.checkEq(Quaternion.IDENTITY*Quaternion.IDENTITY, Quaternion.IDENTITY)
	end)
#end
