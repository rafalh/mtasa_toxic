Event = Class('Event')
Event.map = {}

function Event.__mt.__index:handle(...)
	--outputDebugString('Event.handle filters '..#self.filters..' handlers '..#self.handlers, 3)
	
	for i, filter in ipairs(self.filters) do
		if(not filter(...)) then
			cancelEvent()
			return
		end
	end
	
	for i, handler in ipairs(self.handlers) do
		handler(...)
	end
end

function Event.__mt.__index:addFilter(filter)
	table.insert(self.filters, filter)
end

function Event.__mt.__index:addHandler(handler)
	table.insert(self.handlers, handler)
end

function Event.preInit(eventName, attachedTo)
	--outputDebugString('Event.preInit eventName '..eventName, 3)
	
	local tbl = Event.map[eventName]
	if(not tbl) then return end
	for i, ev in ipairs(tbl) do
		if(ev.attachedTo == attachedTo) then
			return ev
		end
	end
end

function Event.__mt.__index:init(eventName, attachedTo)
	self.filters = {}
	self.handlers = {}
	self.attachedTo = attachedTo
	
	local tbl = Event.map[eventName]
	if(not tbl) then
		tbl = {}
		Event.map[eventName] = tbl
	end
	
	table.insert(tbl, self)
	
	addEventHandler(eventName, attachedTo or g_Root, function(...)
		self:handle(...)
	end)
end
