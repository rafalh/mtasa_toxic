function namespace(name)
	local components = split(name, '.')
	local ref = _G
	for i, comp in ipairs(components) do
		if (not ref[comp]) then
			ref[comp] = {}
			setmetatable(ref[comp], {__index = _G})
		end
		ref = ref[comp]
	end
	
	setfenv(2, ref)
	return ref
end

-- Simple test
#if(TEST) then
addInitFunc(function()
	Test.register('namespace', function()
		(function()
			namespace('abc')
			x = 1
			namespace('def')
			x = 2
		end)()
		
		Test.checkEq(abc.x, 1)
		Test.checkEq(def.x, 2)
		--Test.checkEq(abc.outputChatBox, nil)
	end)
end)
#end
