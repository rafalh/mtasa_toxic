AccessRight = Class('AccessRight')
AccessRight.list = {}

function AccessRight.__mt:__tostring()
	return 'AccessRight('..self.name..')'
end

function AccessRight.__mt.__index:init(name, absolute)
	assert(name)
	local fullName = absolute and name or 'resource.'..g_ResName..'.'..name
	self.name = fullName
	self.handlers = {}
	table.insert(AccessRight.list, self)
end

function AccessRight.__mt.__index:check()
	return LocalACL:checkAccess(self)
end

function AccessRight.__mt.__index:addChangeHandler(func)
	table.insert(self.handlers, func)
end

function AccessRight.__mt.__index:onChange()
	for i, func in ipairs(self.handlers) do
		func()
	end
end

AccessList = Class('AccessList')
function AccessList.__mt.__index:checkAccess(right)
	return self.tbl[right.name]
end

function AccessList.__mt.__index:init(tbl)
	self.tbl = tbl
end

function AccessList.updateLocal(tbl)
	local oldTbl = LocalACL.tbl
	LocalACL = AccessList(tbl)
	
	for i, right in ipairs(AccessRight.list) do
		if((oldTbl[right.name] or false) ~= (tbl[right.name] or false)) then
			right:onChange()
		end
	end
end

LocalACL = AccessList{}
