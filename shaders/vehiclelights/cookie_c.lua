local g_Cookies = false

local function loadCookies()
	g_Cookies = {}
	
	local node = xmlLoadFile("cookie.xml")
	if(not node) then return false end
	
	for i, subnode in ipairs(xmlNodeGetChildren(node)) do
		local name = xmlNodeGetName(subnode)
		local value = xmlNodeGetValue(subnode)
		g_Cookies[name] = value
	end
	
	xmlUnloadFile(node)
	return true
end

local function saveCookies()
	local node = xmlCreateFile("cookie.xml", "cookie")
	if(not node) then return false end
	
	for key, value in pairs(g_Cookies) do
		local subnode = xmlCreateChild(node, key)
		xmlNodeSetValue(subnode, tostring(value))
	end
	
	xmlSaveFile(node)
	xmlUnloadFile(node)
	return true
end

function getCookieOption(key)
	if(not g_Cookies) then
		loadCookies()
	end
	
	return g_Cookies[key]
end

function setCookieOption(key, value)
	if(not g_Cookies) then
		loadCookies()
	end
	
	g_Cookies[key] = value
	
	saveCookies()
end
