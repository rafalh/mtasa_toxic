local g_Queries = {}
local g_BingAppId = '3F57A5F6F90AA286DB6B0557CC897B1C4C88206E'
local g_Langs = false

addEvent('onTranslateReq', true)
addEvent('onTranslateLangListReq', true)
addEvent('onClientTranslate', true)
addEvent('onClientTranslateLangList', true)
addEvent('onHttpResult')

local function xmlUnescape(str)
	return str:gsub('&lt;', '<'):gsub('&gt;', '>'):gsub('&amp;', '&')
end

local function onTranslateResult(data, errno, old_text, lang_to)
	if(data == 'ERROR' or not data) then
		Debug.info('Failed to translate: '..tostring(errno))
		return
	end
	
	new_text = data:match("<string[^>]*>([^<]*)</string>")
	new_text = xmlUnescape(new_text)
	
	if(g_Queries[old_text]) then
		for i, data in ipairs(g_Queries[old_text]) do
			-- Note: unpack must be last arg
			data.func(new_text, unpack(data.args))
		end
		
		g_Queries[old_text] = nil
	end
end

function translate(text, from, to, callback, ...)
	if (not g_Queries[text]) then
		g_Queries[text] = {}
	end
	table.insert(g_Queries[text], {func = callback, args = {...}})
	
	local text_enc = urlEncode(text)
	local from_enc = urlEncode(from or '')
	local to_enc = urlEncode(to or 'en')
	local url = 'https://api.microsofttranslator.com/v2/http.svc/Translate?appId='..g_BingAppId..'&text='..text_enc..'&from='..from_enc..'&to='..to_enc
	--Debug.warn(url)
	if(not fetchRemote(url, onTranslateResult, '', false, text, to)) then
		return false
	end
	
	return true
end

function sayAsPlayer(text, playerEl)
	local player = Player.fromEl(playerEl)
	
	if(isPlayerMuted(player.el)) then
		outputMsg(player, Styles.red, "translate: You are muted!")
		return
	end
	
	local punishment = false
	if(CsProcessMsg) then
		text, punishment = CsProcessMsg(text)
		if(not text) then
			-- Message has been blocked
			CsPunish(player, punishment)
			return
		end
	end
	
	local clr
	if(not player.is_console) then
		local r, g, b = getPlayerNametagColor(player.el)
		clr = ('#%02X%02X%02X'):format(r, g, b)
	else
		clr = '#FF80FF' -- console
	end
	
	local name = player:getName(true)
	local namePlain = player:getName(false)
	local msg = name..': #FFFF00'..text
	
	for el, recipient in pairs(g_Players) do
		local ignored = getElementData(recipient.el, 'ignored_players')
		if(type(ignored) ~= 'table' or not ignored[namePlain]) then
			outputMsg(recipient, clr, '%s', msg)
		end
	end
	outputServerLog('TSAY: '..msg:gsub('#%x%x%x%x%x%x', ''))
	
	if(punishment) then
		CsPunish(player, punishment)
	end
end

local function onTranslateReq(text, from, to, say)
	translate(text, from, to, function(text, player)
		if(not isElement(player)) then return end
		
		if(say) then
			sayAsPlayer(text, player)
		end
		triggerClientEvent(player, 'onClientTranslate', g_Root, text)
	end, client)
	
	AchvActivate(client, 'Try built-in translator')
end

local function onTranslateLangList(data, errno, player)
	if(data == 'ERROR') then
		Debug.warn('Failed to get translator languages: '..tostring(errno))
		return
	end
	
	g_Langs = {}
	for lang in data:gmatch("<string>(%a+)</string>") do
		table.insert(g_Langs, lang)
	end

	triggerClientEvent(player, 'onClientTranslateLangList', g_Root, g_Langs)
end

local function onTranslateLangListReq()
	if(not g_Langs) then
		local url = 'https://api.microsofttranslator.com/v2/http.svc/GetLanguagesForTranslate?appId='..g_BingAppId
		fetchRemote(url, onTranslateLangList, '', false, client)
	else
		triggerClientEvent(client, 'onClientTranslateLangList', g_Root, g_Langs)
	end
end

addInitFunc(function()
	addEventHandler('onTranslateReq', g_Root, onTranslateReq)
	addEventHandler('onTranslateLangListReq', g_Root, onTranslateLangListReq)
end)
