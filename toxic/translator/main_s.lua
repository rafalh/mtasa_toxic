local g_Queries = {}
local g_BingAppId = '3F57A5F6F90AA286DB6B0557CC897B1C4C88206E'
local g_Langs = false

addEvent('onTranslateReq', true)
addEvent('onTranslateLangListReq', true)
addEvent('onClientTranslate', true)
addEvent('onClientTranslateLangList', true)
addEvent('onHttpResult')

local function onTranslateResult(new_text, errno, old_text, lang_to)
	if(new_text == 'ERROR' or not new_text) then
		outputDebugString('Failed to translate: '..tostring(errno), 1)
		return
	end
	
	-- remove UTF-8 BOM
	local b1, b2, b3 = new_text:byte(1, 3)
	if(b1 == 0xEF and b2 == 0xBB and b3 == 0xBF) then
		new_text = new_text:sub(4)
	end
	
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
	local url = 'http://api.microsofttranslator.com/v1/Http.svc/Translate?appId='..g_BingAppId..'&text='..text_enc..'&from='..from_enc..'&to='..to_enc
	--outputDebugString(url, 2)
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
			cancelEvent()
			return
		end
	end
	
	local r, g, b
	if(not player.is_console) then
		r, g, b = getPlayerNametagColor(player.el)
	else
		r, g, b = 255, 128, 255 -- console
	end
	local msg = getPlayerName(player.el)..': #FFFF00'..text
	outputChatBox(msg, g_Root, r, g, b, true)
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
		outputDebugString('Failed to get translator languages: '..tostring(errno), 2)
		return
	end
	
	g_Langs = split(data, '\r\n')
	triggerClientEvent(player, 'onClientTranslateLangList', g_Root, g_Langs)
end

local function onTranslateLangListReq()
	if(not g_Langs) then
		local url = 'http://api.microsofttranslator.com/v1/Http.svc/GetLanguages?appId='..g_BingAppId
		fetchRemote(url, onTranslateLangList, '', false, client)
	else
		triggerClientEvent(client, 'onClientTranslateLangList', g_Root, g_Langs)
	end
end

addInitFunc(function()
	addEventHandler('onTranslateReq', g_Root, onTranslateReq)
	addEventHandler('onTranslateLangListReq', g_Root, onTranslateLangListReq)
end)
