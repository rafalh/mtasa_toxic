AccessRight = Class('AccessRight')
AccessRight.list = {}
AccessRight.map = {}

function AccessRight.__mt:__tostring()
	return 'AccessRight('..self.name..')'
end

function AccessRight.preInit(name, absolute)
	local fullName = absolute and name or 'resource.'..g_ResName..'.'..name
	return AccessRight.map[fullName]
end

function AccessRight.__mt.__index:init(name, absolute)
	assert(name)
	local fullName = absolute and name or 'resource.'..g_ResName..'.'..name
	self.name = fullName
	table.insert(AccessRight.list, self)
	AccessRight.map[self.name] = self
end

function AccessRight.__mt.__index:check(player)
	local acl
	if(isElement(player)) then
		player = Player.fromEl(player)
	elseif(type(player) == 'userdata') then -- account
		local fullName = self:getFullName()
		local obj = 'user.'..getAccountName(player)
		return hasObjectPermissionTo(obj, fullName, false)
	end
	
	acl = player and player.acl
	assert(acl)
	return acl:check(self)
end

function AccessRight.__mt.__index:getFullName()
	return self.name
end

AccessList = Class('AccessList')

function AccessList.__mt.__index:update(accountName)
	local obj = 'user.'..(accountName or 'guest')
	for i, right in ipairs(AccessRight.list) do
		local fullName = right:getFullName()
		--Debug.info('Checking access '..fullName)
		self[right] = hasObjectPermissionTo(obj, fullName, false)
	end
end

function AccessList.__mt.__index:check(right)
	return self[right] or false
end

function AccessList.__mt.__index:send(player)
	local tbl = {}
	for right, perm in pairs(self) do
		tbl[right:getFullName()] = perm
	end
	RPC('AccessList.updateLocal', tbl):setClient(player):exec()
end
