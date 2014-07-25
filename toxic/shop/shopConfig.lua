namespace('Shop.Config')

local g_ItemsConfig = {}

local function loadConfig()
	local node = xmlLoadFile('conf/shop.xml')
	if(not node) then
		Debug.warn('Failed to load shop.xml')
		return
	end
	
	for i, subnode in ipairs(xmlNodeGetChildren(node)) do
		local name = xmlNodeGetName(subnode)
		local attr = xmlNodeGetAttributes(subnode)
		
		if (name == 'item') then
			local itemConfig = {
				id = attr.id,
				price = touint(attr.price),
				params = {},
			}
			
			for i, subnode2 in ipairs(xmlNodeGetChildren(subnode)) do
				local name = xmlNodeGetName(subnode2)
				local attr = xmlNodeGetAttributes(subnode2)
				if (name == 'param' and attr.name and attr.value) then
					itemConfig.params[attr.name] = attr.value
				end
			end
			
			if (not itemConfig.id or not itemConfig.price) then
				Debug.err('expected id and price')
			else
				g_ItemsConfig[itemConfig.id] = itemConfig
			end
		end
	end
	
	xmlUnloadFile(node)
end

function get(id)
	return g_ItemsConfig[id]
end

if (g_ServerSide) then
	addInitFunc(loadConfig)
else
	addEventHandler('onClientResourceStart', resourceRoot, loadConfig)
end
