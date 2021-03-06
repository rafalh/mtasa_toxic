local g_Lights = {
	"High Quality",
	"Blue Doom",
	"Blue Estrellas",
	"Blue Flecha",
	"Blue Neon HQ",
	"Blue Oblique",
	"Blue X",
	"Colored",
	--"Green FFS",
	"Green Mustang",
	"Green Onda",
	"Green Paradise",
	"Grey Audi I",
	"MEME Derp HQ",
	"MEME Me Gusta HQ",
	"MEME Troll HQ",
	"Orange Cupido",
	"Orange Led",
	"Orange Lines",
	"Pink Dots",
	"Poland",
	"Purple I",
	"Purple II",
	"Red Alfa Romeo",
	"Red Alien",
	"Red Angry Mouth",
	"Red Angry Shape",
	"Red Audi I",
	"Red Audi II",
	"Red Audi III",
	"Red BMW I",
	"Red BMW II",
	"Red BMW M5",
	"Red Canibus",
	"Red Chevrolet Malibu",
	"Red Citroen Survolt",
	"Red Cupido",
	"Red Curve",
	"Red Curves HQ",
	"Red Dino",
	"Red Double Oval",
	"Red Double Ring",
	"Red Double Ring Led",
	"Red Double Rounded Restangles HQ",
	"Red Double Stripes",
	"Red Fast Line",
	--"Red FFS",
	"Red Infiniti Electric",
	"Red KIA",
	"Red Lamborghini",
	"Red Lexus",
	"Red Lines",
	"Red Metropolis",
	"Red Mustang",
	"Red Passat",
	"Red Peugeot",
	"Red Rhombus",
	"Red Ring",
	"Red Sexy",
	"Red Slanted Stripes",
	"Red Spray",
	"Red Subaru",
	"Red The N",
	"Red The X",
	"Red The Y",
	"Red Triangles",
	"Red Triple Stripes",
	"Red Volkswagen",
	"Violet Lilac",
	"White Slanted Stripes",
	"White Snake",
}

local g_Shaders = {}
local g_CurrentLight = "High Quality"

local g_LightsEnabled = false

local function loadVehicleLights(veh, image)
	if (not g_LightsEnabled) then return end
	
	local controller = getVehicleController(veh)
	if (not controller) then return end
	
	image = image or getElementData(controller, "vehiclelight")
	if (not image) then return end
	
	if (not g_Shaders[image]) then
		local texture = dxCreateTexture("images/"..image..".jpg", "dxt3")
		if(not texture) then
			outputDebugString("dxCreateTexture failed for "..tostring(image).." player "..getPlayerName(controller), 2)
		end
		local shader = dxCreateShader("lights.fx")
		dxSetShaderValue(shader, "gTexture", texture)
		g_Shaders[image] = shader
	end
	engineApplyShaderToWorldTexture(g_Shaders[image], "vehiclelights128", veh)
	engineApplyShaderToWorldTexture(g_Shaders[image], "vehiclelightson128", veh) -- needs messing with alpha
end

local function unloadVehicleLights(veh, image)
	local controller = getVehicleController(veh)
	if(not controller) then return end
	
	image = image or getElementData(controller, "vehiclelight")
	if(not image or not g_Shaders[image]) then return end
	
	engineRemoveShaderFromWorldTexture(g_Shaders[image], "vehiclelights128", veh)
	engineRemoveShaderFromWorldTexture(g_Shaders[image], "vehiclelightson128", veh)
end

function enableCustomLights()
	g_LightsEnabled = true
	
	for i, veh in ipairs(getElementsByType("vehicle")) do
		loadVehicleLights(veh)
	end
end

function disableCustomLights()
	g_LightsEnabled = false
	
	for i, veh in ipairs(getElementsByType("vehicle")) do
		unloadVehicleLights(veh)
	end
	
	for name, shader in pairs(g_Shaders) do
		destroyElement(shader)
	end
	g_Shaders = {}
end

local function isValidLight (lightName)
	for i, currentLight in ipairs(g_Lights) do
		if currentLight == lightName then
			return true
		end
	end
	return false
end

addEventHandler("onClientResourceStart", resourceRoot, function()
	local light = getCookieOption("lights")
	if light then
		if light == '' then
			g_CurrentLight = false
		elseif isValidLight(light) then
			g_CurrentLight = light
		end
	end
	
	setElementData(localPlayer, "vehiclelight", g_CurrentLight)
end)

addEventHandler("onClientElementStreamIn", root, function()
	if (getElementType(source) == "vehicle") then
		loadVehicleLights(source)
	end
end)

addEventHandler("onClientVehicleEnter", root, function()
	loadVehicleLights(source)
end)

local function onPlayerDataChange(key, oldValue)
	if (key ~= "vehiclelight") then return end
	
	local veh = getPedOccupiedVehicle(source)
	if(veh) then
		unloadVehicleLights(veh, oldValue)
		loadVehicleLights(veh)
	end
end

addEventHandler("onClientPlayerJoin", root, function()
	addEventHandler("onClientElementDataChange", source, onPlayerDataChange, false)
end)

------------- GUI -------------
local g_LightsWindow, g_LightsComboBox, g_PreviewImage

local function applyChanges(btn)
	if btn ~= "left" then return end
	
	local id = guiComboBoxGetSelected(g_LightsComboBox)
	local light = (id ~= 0 and guiComboBoxGetItemText(g_LightsComboBox, id))
	if (light ~= g_CurrentLight) then
		g_CurrentLight = light
		setElementData(localPlayer, "vehiclelight", g_CurrentLight)
		setCookieOption("lights", g_CurrentLight or '')
	end
end

local function closeWindow(btn)
	if(btn ~= "left") then return end
	
	guiSetVisible(g_LightsWindow, false)
	showCursor(false)
end

local function applyChangesAndClose(btn)
	if(btn ~= "left") then return end
	
	applyChanges(btn)
	closeWindow(btn)
end

local function updatePreview()
	local id = guiComboBoxGetSelected(g_LightsComboBox)
	local light = (id ~= 0 and guiComboBoxGetItemText(g_LightsComboBox, id))
	if (not light) then
		guiSetVisible(g_PreviewImage, false)
	else
		guiSetVisible(g_PreviewImage, true)
		guiStaticImageLoadImage(g_PreviewImage, "images/"..light..".jpg")
	end
end

local function initGui()
	local w, h = 380, 375
	local x, y = 200, 70
	g_LightsWindow = guiCreateWindow(x, y, w, h, "Vehicle Lights", false)
	guiWindowSetSizable(g_LightsWindow, false)
	
	guiCreateLabel(15, 25, 380, 20, "Lights:", false, g_LightsWindow)
	g_LightsComboBox = guiCreateComboBox(15, 45, 350, 160, "", false, g_LightsWindow)
	local id = guiComboBoxAddItem(g_LightsComboBox, "Default")
	guiComboBoxSetSelected(g_LightsComboBox, id)
	
	for i, light in ipairs(g_Lights) do
		local id = guiComboBoxAddItem(g_LightsComboBox, light)
		if (light == g_CurrentLight) then
			guiComboBoxSetSelected(g_LightsComboBox, id)
		end
	end
	addEventHandler("onClientGUIComboBoxAccepted", g_LightsComboBox, updatePreview)
	
	guiCreateLabel(15, 75, 380, 20, "Preview:", false, g_LightsWindow)
	if (g_CurrentLight) then
		local imgPath = "images/"..g_CurrentLight..".jpg"
		g_PreviewImage = guiCreateStaticImage(15, 95, 350, 220, imgPath, false, g_LightsWindow)
	else
		local imgPath = "images/"..g_Lights[1]..".jpg"
		g_PreviewImage = guiCreateStaticImage(15, 95, 350, 220, imgPath, false, g_LightsWindow)
		guiSetVisible(g_PreviewImage, false)
	end
	
	local okBtn = guiCreateButton (w - 3*90, h - 35, 80, 25, "OK", false, g_LightsWindow)
	addEventHandler("onClientGUIClick", okBtn, applyChangesAndClose, false)
	local closeBtn = guiCreateButton (w - 2*90, h - 35, 80, 25, "Close", false, g_LightsWindow)
	addEventHandler("onClientGUIClick", closeBtn, closeWindow, false)
	local applyBtn = guiCreateButton (w - 90, h - 35, 80, 25, "Apply", false, g_LightsWindow)
	addEventHandler("onClientGUIClick", applyBtn, applyChanges, false)
end

local function closeCustomLightsWnd()
	if(not g_LightsWindow) then return end
	guiSetVisible(g_LightsWindow, false)
	showCursor(false)
end

function openCustomLightsWnd()
	if(not g_LightsWindow or not guiGetVisible(g_LightsWindow)) then
		if(g_LightsWindow) then
			guiSetVisible(g_LightsWindow, true)
		else
			initGui()
		end
		showCursor(true)
	end
	guiBringToFront(g_LightsWindow)
	
end

local function toggleConfigWnd()
	if(g_LightsWindow and guiGetVisible(g_LightsWindow)) then
		closeCustomLightsWnd()
	else
		openCustomLightsWnd()
	end
end

addCommandHandler("vehiclelights", toggleConfigWnd, false, false)
