AccessRight = Class('AccessRight')
AccessRight.list = {}

function AccessRight.__mt:__tostring()
	return 'AccessRight('..self.name..')'
end

function AccessRight.__mt.__index:init(name)
	assert(name)
	self.name = name
	table.insert(AccessRight.list, self)
end

function AccessRight.__mt.__index:check(player)
	if(type(player) ~= 'table') then
		player = Player.fromEl(player)
	end
	return player.acl:check(self)
end

AccessList = Class('AccessList')

function AccessList.__mt.__index:update(accountName)
	local obj = 'user.'..(accountName or 'guest')
	for i, right in ipairs(AccessRight.list) do
		local fullName = 'resource.'..g_ResName..'.'..right.name
		self[right] = hasObjectPermissionTo(obj, fullName, false)
	end
end

function AccessList.__mt.__index:check(right)
	return self[right] or false
end

function AccessList.__mt.__index:send(player)
	local tbl = {}
	for right, perm in pairs(self) do
		tbl[right.name] = perm
	end
	RPC('AccessList.updateLocal', tbl):setClient(player):exec()
end