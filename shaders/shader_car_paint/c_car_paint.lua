--
-- c_car_paint.lua
--

local textureVol
local textureCube
local g_Textures = {"vehiclegrunge256", "?emap*",
	"predator92body128", "monsterb92body256a", "monstera92body256a", "andromeda92wing", "fcr90092body128",
	"hotknifebody128b", "hotknifebody128a", "rcbaron92texpage64", "rcgoblin92texpage128", "rcraider92texpage128", 
	"rctiger92body128", "rhino92texpage256", "petrotr92interior128", "artict1logos","rumpo92adverts256", "dash92interior128",
	"coach92interior128","combinetexpage128","hotdog92body256",
	"raindance92body128", "cargobob92body256", "andromeda92body", "at400_92_256", "nevada92body256",
	"polmavbody128a", "sparrow92body128", "hunterbody8bit256a", "seasparrow92floats64" , 
	"dodo92body8bit256", "cropdustbody256", "beagle256", "hydrabody256", "rustler92body256", 
	"shamalbody256", "skimmer92body128", "stunt256", "maverick92body128", "leviathnbody8bit256" }

function enableCarPaint()
		-- Version check
		if getVersion ().sortable < "1.1.0" then
			outputChatBox( "Resource is not compatible with this client." )
			return
		end

		-- Create shader
		myShader, tec = dxCreateShader ( "car_paint.fx" )

		if not myShader then
			--outputChatBox( "Could not create shader. Please use debugscript 3" )
		else
			--outputChatBox( "Using technique " .. tec )

			-- Set textures
			textureVol = dxCreateTexture ( "images/smallnoise3d.dds" );
			textureCube = dxCreateTexture ( "images/cube_env256.dds" );
			dxSetShaderValue ( myShader, "sRandomTexture", textureVol );
			dxSetShaderValue ( myShader, "sReflectionTexture", textureCube );
		end
		
		for i, tex in ipairs ( g_Textures ) do
			engineApplyShaderToWorldTexture ( myShader, tex )
		end
end

function disableCarPaint()
	destroyElement(myShader)
	destroyElement(textureVol)
	destroyElement(textureCube)
end
