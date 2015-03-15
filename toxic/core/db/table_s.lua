namespace 'db'

Table = Class('Table')
Table.list = {}
Table.map = {}

function Table.__mt.__index:init(args)
	assert(args.name)
	
	self.name = args.name
	self.colMap = {}
	self:addColumns(args)
	
	table.insert(Table.list, self)
	assert(not Table.map[self.name], 'Table '..tostring(args.name)..' already exists')
	Table.map[self.name] = self
	return self
end

function Table.__mt.__index:addColumns(cols)
	for i, col in ipairs(cols) do
		assert(col[1])
		table.insert(self, col)
		self.colMap[col[1]] = col
	end
end

function Table.__mt.__index:insertDefault()
	return g_Driver and g_Driver:insertDefault(self)
end

function Table.__mt.__index:getColumnsList()
	local ret = {}
	for i, col in ipairs(self) do
		if (col[2]) then
			table.insert(ret, col[1])
		end
	end
	return ret
end

function Table.__mt.__index:hasColumn(colName)
	return self.colMap[colName] and true
end

function Table.__mt:__tostring(tbl)
	return db.getTblPrefix()..self.name
end

function Table.__mt.__concat(a, b)
	if (type(a) == 'table') then
		return db.getTblPrefix()..a.name..tostring(b)
	else
		return tostring(a)..db.getTblPrefix()..b.name
	end
end

function Table.__mt.__index:destroy()
	Table.map[self.name] = nil
	table.removeValue(Table.list, self)
end
