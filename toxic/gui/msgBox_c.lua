MsgBox = Class('MsgBox')

local DEFAULT_FONT = 'default-normal'
local DEFAULT_BUTTONS = {"OK"}
local ICON_SIZE = 64

function MsgBox.__mt.__index:init(title, text, icon)
	self.title = title
	self.text = text
	self.icon = icon
	self.font = DEFAULT_FONT
	self.buttons = DEFAULT_BUTTONS
	self.closeHandlers = {}
end

function MsgBox.__mt.__index:setButtons(buttons)
	self.buttons = buttons
end

function MsgBox.__mt.__index:recalcSize()
	local titleW = GUI.getTextWidth(self.title)
	local textW, textH = 0, 0
	local fontH = GUI.getFontHeight(self.font)
	local textRows = 0
	
	local textLines = split(self.text, '\n')
	for i, line in ipairs(textLines) do
		local lineW = GUI.getTextWidth(line, self.font)
		local rows = 1
		
		if(lineW > g_ScreenSize[1]*0.5) then
			rows = math.ceil(lineW / (g_ScreenSize[1]*0.5))
			lineW = g_ScreenSize[1]*0.5
		end
		
		textW = math.max(textW, lineW + 10) -- add 10 to make sure text fits
		textH = textH + rows*fontH
		textRows = textRows + rows
	end
	
	if(self.icon) then
		textH = math.max(textH, ICON_SIZE)
	end
	
	local buttonsW = #self.buttons * 10 -- spacing
	for i, btn in ipairs(self.buttons) do
		local btnW = math.max(GUI.getTextWidth(btn) + 10, 80)
		buttonsW = buttonsW + btnW
	end
	self.buttonsW = buttonsW
	
	--Debug.info('textW '..textW..' rows '..textRows)
	local iconW = self.icon and (ICON_SIZE + 10) or 0
	self.w = math.max(textW + iconW, buttonsW) + 20
	self.h = textH + 70
end

function MsgBox.__mt.__index:isVisible()
	return self.wnd and guiGetVisible(self.wnd)
end

function MsgBox.__mt.__index:show()
	if(self.wnd) then
		destroyElement(self.wnd)
	end
	
	if(not self.w) then
		self:recalcSize()
	end
	
	local x, y = (g_ScreenSize[1] - self.w)/2, (g_ScreenSize[2] - self.h)/2
	self.wnd = guiCreateWindow(x, y, self.w, self.h, self.title, false)
	if(not self.wnd) then return false end
	guiWindowSetSizable(self.wnd, false)
	
	local textX = 10
	if(self.icon) then
		guiCreateStaticImage(10, 25, ICON_SIZE, ICON_SIZE, 'img/msgbox/'..self.icon..'.png', false, self.wnd)
		textX = textX + ICON_SIZE + 10
	end
	
	--Debug.info('text label width '..(self.w - textX - 10))
	self.textLabel = guiCreateLabel(textX, 25, self.w - textX - 20, self.h - 25 - 45, self.text, false, self.wnd)
	guiLabelSetHorizontalAlign(self.textLabel, 'center', true)
	guiLabelSetVerticalAlign(self.textLabel, 'center')
	
	local btnX = (self.w - self.buttonsW)/2
	for i, btn in ipairs(self.buttons) do
		local btnW = math.max(GUI.getTextWidth(btn) + 10, 80)
		local btn = guiCreateButton(btnX, self.h - 35, btnW, 25, btn, false, self.wnd)
		btnX = btnX + btnW + 10
		
		addEventHandler('onClientGUIClick', btn, function()
			self:close(btn)
		end, false)
	end
	
	guiBringToFront(self.wnd)
	showCursor(true)
	return true
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

-- used by RPC
function MsgBox.showInfo(title, text)
	MsgBox(title, text, 'info'):show()
end

#local MSGBOX_TEST = false
#if(MSGBOX_TEST) then
	Debug.warn('Enter /msgboxtest to test MsgBox')
	
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
		elseif(n == 3) then
			msgBox = MsgBox('Some weird title!', 'Simple short text message...', 'info')
		else
			outputChatBox('No test number given!', 255, 0, 0)
			return
		end
		msgBox:show()
	end, false)
#end -- MSGBOX_TEST
