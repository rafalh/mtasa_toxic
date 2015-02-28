local g_LastUrl = false

local function onChatMsg(text)
	text = text:gsub('#%x%x%x%x%x%x', '')
	local url = text:match('https?://[^%s]+') or text:match('www%.[^%s]+')
	if(url) then
		g_LastUrl = url
	end
end

addInitFunc(function()
	addEventHandler('onClientChatMessage', g_Root, onChatMsg)
	
	CmdMgr.register{
		name = 'copyurl',
		desc = "Copies last URL from chatbox to the clipboard",
		func = function(ctx)
			if(not g_LastUrl) then
				outputMsg(Styles.red, "There is no URL to copy!")
			elseif(setClipboard(g_LastUrl)) then
				outputMsg(Styles.yellow, "URL has been copied: %s", g_LastUrl)
			else
				outputMsg(Styles.red, "Failed to copy URL to clipboard!")
			end
		end
	}
end)
