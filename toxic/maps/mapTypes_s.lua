local function LoadMapTypes()
	local node = xmlLoadFile('conf/map_types.xml')
	if(not node) then return false end
	
	for i, subnode in ipairs(xmlNodeGetChildren(node)) do
		local data = {}
		data.name = xmlNodeGetAttribute(subnode, 'name')
		data.pattern = xmlNodeGetAttribute(subnode, 'pattern')
		data.preg = xmlNodeGetAttribute(subnode, 'preg')
		
		local gm = xmlNodeGetAttribute(subnode, 'ghostmode')
		data.gm = touint(gm) or (gm == 'true')
		
		data.others_in_row = 0
		data.max_others_in_row = touint(xmlNodeGetAttribute(subnode, 'max_others_in_row'))
		
		local winning_veh_str = xmlNodeGetAttribute(subnode, 'winning_vehicles') or ''
		local id_list = split(winning_veh_str, ',')
		local added = false
		local winning_veh = {}
		
		for j, v in ipairs(id_list) do
			local id = touint(v)
			if(id) then
				winning_veh[id] = true
				added = true
			end
		end
		
		if(added) then
			data.winning_veh = winning_veh
		end

		local disabled_shop_items_str = xmlNodeGetAttribute(subnode, 'disabled_shop_items') or ''
		data.disabled_shop_items = split(disabled_shop_items_str, ',')
		
		data.max_fps = touint(xmlNodeGetAttribute(subnode, 'max_fps'))
		
		assert(data.name)
		table.insert(g_MapTypes, data)
	end
	
	xmlUnloadFile(node)
	return true
end

addInitFunc(LoadMapTypes, -10)
