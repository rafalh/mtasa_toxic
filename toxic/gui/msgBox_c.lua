MsgBox = Class('MsgBox')

local DEFAULT_FONT = 'default-normal'
local DEFAULT_BUTTONS = {"OK"}

function MsgBox.__mt.__index:init(title, text)
	self.title = title
	self.text = text
	--self.icon = false
	self.font = DEFAULT_FONT
	self.buttons = DEFAULT_BUTTONS
	self.closeHandlers = {}
end

function MsgBox.__mt.__index:setButtons(buttons)
	self.buttons = buttons
end

function MsgBox.__mt.__index:recalcSize()
	local textLines = split(self.text, '\n')
	
	local titleW = GUI.getTextWidth(self.title)
	local textW, textH = 0, 0
	local fontH = GUI.getFontHeight(self.font)
	
	for i, line in ipairs(textLines) do
		local lineW = GUI.getTextWidth(line, self.font)
		local rows = 1
		
		if(lineW > g_ScreenSize[1]*0.5) then
			rows = lineW / (g_ScreenSize[1]*0.5)
			lineW = g_ScreenSize[1]*0.5
		end
		
		textW = math.max(textW, lineW)
		textH = textH + rows*fontH
	end
	
	local buttonsW = #self.buttons * 10 -- spacing
	for i, btn in ipairs(self.buttons) do
		local btnW = math.max(GUI.getTextWidth(btn) + 10, 80)
		buttonsW = buttonsW + btnW
	end
	self.buttonsW = buttonsW
	
	self.w = math.max(textW, buttonsW) + 20
	self.h = textH + 70
end

function MsgBox.__mt.__index:isVisible()
	return self.wnd and guiGetVisible(self.wnd)
end

function MsgBox.__mt.__index:show()
	if(not self.w) then
		self:recalcSize()
	end
	
	if(self.wnd) then
		destroyElement(self.wnd)
	end
	
	local x, y = (g_ScreenSize[1] - self.w)/2, (g_ScreenSize[2] - self.h)/2
	self.wnd = guiCreateWindow(x, y, self.w, self.h, self.title, false)
	if(not self.wnd) then return false end
	guiWindowSetSizable(self.wnd, false)
	
	self.textLabel = guiCreateLabel(10, 25, self.w - 20, self.h - 45, self.text, false, self.wnd)
	guiLabelSetHorizontalAlign(self.textLabel, 'center', true)
	
	local btnX = (self.w - self.buttonsW)/2
	for i, btn in ipairs(self.buttons) do
		local btnW = math.max(GUI.getTextWidth(btn) + 10, 80)
		local btn = guiCreateButton(btnX, self.h - 35, btnW, 25, btn, false, self.wnd)
		btnX = btnX + btnW + 10
		
		addEventHandler('onClientGUIClick', btn, function()
			self:close(btn)
		end, false)
	end
	
	showCursor(true)
end

function MsgBox.__mt.__index:close(btn)
	assert(self.wnd)
	
	destroyElement(self.wnd)
	self.wnd = false
	
	showCursor(false)
	
	for i, func in ipairs(self.closeHandlers) do
		func(btn)
	end
end

function MsgBox.__mt.__index:addCloseHandler(func)
	table.insert(self.closeHandlers, func)
end

#local TEST = false
#if(TEST) then
	outputDebugString('Enter /msgboxtest to test MsgBox', 2)
	
	addCommandHandler('msgboxtest', function(cmdName, n)
		n = tonumber(n)
		local msgBox
		if(n == 0) then
			msgBox = MsgBox('Some weird title!', 'Simple short text message...')
		elseif(n == 1) then
			msgBox = MsgBox('Some weird title!', 'Overly long unformatted statements present fellow editors a dilemma: spend excessive time parsing out what a writer means or being mildly rude in not actually reading what is written. It is more collegial and collaborative to take an extra few moments to distill one\'s thoughts into bite size pieces.')
		elseif(n == 2) then
			msgBox = MsgBox('Some weird title!', 'Overly long unformatted statements present fellow editors a dilemma: spend excessive time parsing out what a writer means or being mildly rude in not actually reading what is written. It is more collegial and collaborative to take an extra few moments to distill one\'s thoughts into bite size pieces.\n'..
				'Traditionally, the phrase too long; didn\'t read (abbreviated tl;dr or simply tldr) has been used on the Internet as a reply to an excessively long statement. It indicates that the reader did not actually read the statement due to its undue length.\n[2] This essay especially considers the term as used in Wikipedia discussions, and examines methods of fixing the problem when found in article content.')
		else
			outputChatBox('No test number given!', 255, 0, 0)
			return
		end
		msgBox:show()
	end, false)
#end
