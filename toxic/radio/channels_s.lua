namespace('Radio')

local g_NotifyPlayers = {}

local function loadChannels()
	channels = {}
	local node, i = xmlLoadFile('conf/radio.xml'), 0
	if(node) then
		while(true) do
			local subnode = xmlFindChild(node, 'channel', i)
			if(not subnode) then break end
			i = i + 1
			
			local ch = {}
			ch.name = xmlNodeGetAttribute(subnode, 'name')
			ch.img = xmlNodeGetAttribute(subnode, 'img')
			ch.url = xmlNodeGetValue(subnode)
			assert(ch.name and ch.url)
			
			table.insert(channels, ch)
		end
		
		xmlUnloadFile(node)
	else
		Debug.warn('Failed to load radio channnels list')
	end
	
	table.sort(channels, function(ch1, ch2) return ch1.name:lower() < ch2.name:lower() end)
	
	return channels
end

local function notifyAll()
	triggerClientEvent(g_NotifyPlayers, 'toxic.onRadioChannelsChange', resourceRoot)
end

function saveChannels(channels)
	local node = xmlCreateFile('conf/radio.xml', 'channels')
	if(not node) then return false end
	
	table.sort(channels, function(ch1, ch2) return ch1.name:lower() < ch2.name:lower() end)
	Cache.set('Radio.Channels', channels, 300)
	
	for i, ch in ipairs(channels) do
		local subnode = xmlCreateChild(node, 'channel')
		xmlNodeSetValue(subnode, ch.url)
		xmlNodeSetAttribute(subnode, 'name', ch.name)
		if(ch.img) then
			xmlNodeSetAttribute(subnode, 'img', ch.img)
		end
	end
	
	xmlSaveFile(node)
	xmlUnloadFile(node)
	
	notifyAll()
end

function getChannels()
	local channels = Cache.get('Radio.Channels')
	if(not channels) then
		channels = loadChannels()
		Cache.set('Radio.Channels', channels, 300)
	end
	
	if(not table.find(g_NotifyPlayers, client)) then
		table.insert(g_NotifyPlayers, client)
	end
	return channels
end

RPC.allow('Radio.getChannels')

addInitFunc(function()
	addEventHandler('onPlayerQuit', root, function()
		table.removeValue(g_NotifyPlayers, source)
	end)
end)