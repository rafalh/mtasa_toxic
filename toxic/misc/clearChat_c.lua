CmdMgr.register{
	name = 'clearchat',
	desc = "Clears the chatbox by scrolling content many lines up",
	func = function(ctx)
		local chatLayout = getChatboxLayout()
		for i = 1, chatLayout.chat_lines do
			outputChatBox('')
		end
	end
}
