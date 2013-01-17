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
	"White Snake"
}

local g_Shaders = {}
local g_CurrentLight = "High Quality"

local g_LightsEnabled = false

local function loadVehicleLights(veh, image)
	if(not g_LightsEnabled) then return end
	
	local controller = getVehicleController(veh)
	if(not controller) then return end
	
	image = image or getElementData(controller, "vehiclelight")
	if(not image) then return end
	
	if(not g_Shaders[image]) then
		local texture = dxCreateTexture("images/"..image..".jpg", "dxt3")
		if(not texture) then
			outputDebugString("dxCreateTexture failed for "..tostring(image), 2)
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

addEventHandler("onClientResourceStart", resourceRoot, function()
	local light = getCookieOption("lights")
	if(light) then
		g_CurrentLight = (light ~= "" and light)
	end
	setElementData(localPlayer, "vehiclelight", g_CurrentLight, true)
	
	enableCustomLights()
end)

addEventHandler("onClientElementStreamIn", root, function()
	if(getElementType(source) == "vehicle") then
		loadVehicleLights(source)
	end
end)

addEventHandler("onClientVehicleEnter", root, function()
	loadVehicleLights(source)
end)

addEventHandler("onClientElementDataChange", root, function(key, oldValue)
	if(key ~= "vehiclelight" or getElementType(source) ~= "player") then return end
	
	local veh = getPedOccupiedVehicle(source)
	if(veh) then
		unloadVehicleLights(veh, oldValue)
		loadVehicleLights(veh)
	end
end)

------------- GUI -------------
local g_LightsWindow, g_LightsComboBox, g_PreviewImage

local function applyChanges(btn)
	if btn ~= "left" then return end
	
	local id = guiComboBoxGetSelected(g_LightsComboBox)
	local light = (id ~= 0 and guiComboBoxGetItemText(g_LightsComboBox, id))
	if(light ~= g_CurrentLight) then
		g_CurrentLight = light
		setElementData(localPlayer, "vehiclelight", g_CurrentLight)
		setCookieOption("lights", g_CurrentLight)
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

local function updatePreview ()
	local id = guiComboBoxGetSelected(g_LightsComboBox)
	local light = (id ~= 0 and guiComboBoxGetItemText(g_LightsComboBox, id))
	if(not light) then
		guiSetVisible(g_PreviewImage, false)
	else
		guiSetVisible(g_PreviewImage, true)
		guiStaticImageLoadImage(g_PreviewImage, "images/"..light..".jpg")
	end
end

local function initGui()
	local w, h = 380, 375
	local x, y = 200, 70
	g_LightsWindow = guiCreateWindow (x, y, w, h, "Vehicle Lights", false)
	guiWindowSetSizable (g_LightsWindow, false)
	
	guiCreateLabel(15, 25, 380, 20, "Lights:", false, g_LightsWindow)
	g_LightsComboBox = guiCreateComboBox (15, 45, 350, 160, "", false, g_LightsWindow)
	local id = guiComboBoxAddItem(g_LightsComboBox, "Default")
	guiComboBoxSetSelected(g_LightsComboBox, id)
	
	for i, light in ipairs(g_Lights) do
		local id = guiComboBoxAddItem(g_LightsComboBox, light)
		if(light == g_CurrentLight) then
			guiComboBoxSetSelected(g_LightsComboBox, id)
		end
	end
	addEventHandler("onClientGUIComboBoxAccepted", g_LightsComboBox, updatePreview)
	
	guiCreateLabel (15, 75, 380, 20, "Preview:", false, g_LightsWindow)
	g_PreviewImage = guiCreateStaticImage (15, 95, 350, 220, "images/"..g_CurrentLight..".jpg", false, g_LightsWindow)
	
	local okBtn = guiCreateButton (w - 3*90, h - 35, 80, 25, "OK", false, g_LightsWindow)
	addEventHandler("onClientGUIClick", okBtn, applyChangesAndClose, false)
	local closeBtn = guiCreateButton (w - 2*90, h - 35, 80, 25, "Close", false, g_LightsWindow)
	addEventHandler("onClientGUIClick", closeBtn, closeWindow, false)
	local applyBtn = guiCreateButton (w - 90, h - 35, 80, 25, "Apply", false, g_LightsWindow)
	addEventHandler("onClientGUIClick", applyBtn, applyChanges, false)
end

addCommandHandler("vehiclelights", function ()
	if(g_LightsWindow) then
		guiSetVisible(g_LightsWindow, not guiGetVisible(g_LightsWindow))
		showCursor(guiGetVisible(g_LightsWindow))
	else
		showCursor(true)
		initGui()
	end
end, false, false)
