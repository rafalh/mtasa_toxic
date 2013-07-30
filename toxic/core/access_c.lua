AccessRight = Class("AccessRight")
AccessRight.list = {}

function AccessRight.__mt:__tostring()
	return "AccessRight("..self.name..")"
end

function AccessRight.__mt.__index:init(name)
	assert(name)
	self.name = name
	table.insert(AccessRight.list, self)
end

function AccessRight.__mt.__index:check()
	return LocalACL:checkAccess(self)
end

AccessList = Class("AccessList")
function AccessList.__mt.__index:checkAccess(right)
	return self.tbl[right.name]
end

function AccessList.__mt.__index:init(tbl)
	self.tbl = tbl
end

function AccessList.updateLocal(tbl)
	LocalACL = AccessList(tbl)
end

LocalACL = AccessList()