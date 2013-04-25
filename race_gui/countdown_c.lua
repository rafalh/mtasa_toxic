Countdown = {}
Countdown.timer = false
Countdown.value = 0
Countdown.type = ''
Countdown.images = {}

function Countdown.stop()
	hideGUIComponents('countdown')
	
	if(Countdown.timer) then
		killTimer(Countdown.timer)
		Countdown.timer = false
	end
	
	for i, img in ipairs(Countdown.images) do
		destroyElement(img)
	end
	Countdown.images = {}
end

function Countdown.update()
	local stopVal = Countdown.type == "race" and -1 or 0
	if(Countdown.value <= stopVal) then
		Countdown.stop()
		return
	end
	
	if(Countdown.type == "respawn") then
		g_dxGUI.countdown:text('You will respawn in: '..Countdown.value..' seconds')
	elseif(Countdown.type == "nextmap") then
		g_dxGUI.countdown:text('Vote for next map in: '..Countdown.value..' seconds')
	elseif(Countdown.type == "race") then
		for i, img in ipairs(Countdown.images) do
			destroyElement(img)
		end
		Countdown.images = {}
		
		local numImages = Countdown.value == 0 and 3 or 1
		for i = 1, numImages do
			Countdown.images[i] = guiCreateStaticImage(
				math.floor(g_ScrW/2 - g_Images.countdown.w/2),
				math.floor(g_ScrH/2 - g_Images.countdown.h/2),
				g_Images.countdown.w,
				g_Images.countdown.h,
				string.format(g_Images.countdown.path, Countdown.value),
				false,
				nil)
		end
		Animation.createAndPlay(
			Countdown.images,
			{ from = 0, to = 1, time = 1000, fn = zoomFades, width = g_Images.countdown.w, height = g_Images.countdown.h }
		)
	end
	
	Countdown.value = Countdown.value - 1
end

addEvent("race.onCountdownStart")
addEventHandler("race.onCountdownStart", root, function(name, seconds)
	Countdown.value = math.floor(seconds)
	Countdown.type = name
	
	if(name ~= "race") then
		showGUIComponents('countdown')
	end
	
	if(Countdown.timer) then
		resetTimer(Countdown.timer)
	else
		Countdown.timer = setTimer(Countdown.update, 1000, 0)
	end
	
	Countdown.update()
end)

-- Custom fancy effect for final countdown image
function zoomFades(elems, val, info)
	if type( val ) == 'table' then
		return
	end

	local valinv = 1 - val
	local width = info.width
	local height = info.height

	local val = 1-((1-val) * (1-val))
	local slope = val * 0.95
	local alphas = { valinv, (valinv-0.35) * 0.20, (valinv-0.5) * 0.125 }

	if #elems > 1 then
		alphas[1] = valinv*valinv-valinv*0.5
	end

	for i,elem in ipairs(elems) do
		if isElement(elem) then
			local scalex = 1 + slope * (i-1)
			local scaley = 1 + slope * (i-1)
			local sx = width * scalex
			local sy = height * scaley
			local screenWidth, screenHeight = guiGetScreenSize()
			sx = math.min( screenWidth, sx )
			sy = math.min( screenHeight, sy )
			local px = math.floor(screenWidth/2 - sx/2)
			local py = math.floor(screenHeight/2 - sy/2)
			guiSetPosition( elem, px, py, false )
			guiSetSize( elem, sx, sy, false )
			guiSetAlpha( elem, alphas[i] )
		end
	end
end
