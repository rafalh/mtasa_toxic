--
-- c_car_paint.lua
--

 -- Max redner distance of the shader effect
local renderDistance = 50
 --Pearlescent
local filmDepth = 0.08
local filmIntensity = 0.21
local filmDepthEnable = true

--a table of additional texture names:
			
	local texturegrun = {
			"predator92body128", "monsterb92body256a", "monstera92body256a", "andromeda92wing","fcr90092body128",
			"hotknifebody128b", "hotknifebody128a", "rcbaron92texpage64", "rcgoblin92texpage128", "rcraider92texpage128", 
			"rctiger92body128","rhino92texpage256", "petrotr92interior128","artict1logos","rumpo92adverts256","dash92interior128",
			"coach92interior128","combinetexpage128","hotdog92body256",
			"raindance92body128", "cargobob92body256", "andromeda92body", "at400_92_256", "nevada92body256",
			"polmavbody128a" , "sparrow92body128" , "hunterbody8bit256a" , "seasparrow92floats64" , 
			"dodo92body8bit256" , "cropdustbody256", "beagle256", "hydrabody256", "rustler92body256", 
			"shamalbody256", "skimmer92body128", "stunt256", "maverick92body128", "leviathnbody8bit256" }



function startCarPaint()
		if cpEffectEnabled then return end
		-- Create shader
		myShader, tec = dxCreateShader ( "fx/car_paint.fx",1 ,renderDistance ,false)

		if myShader then
			--outputConsole( "Using technique " .. tec )

			-- Set textures
			textureVol = dxCreateTexture ( "images/smallnoise3d.dds" )
			textureCube = dxCreateTexture ( "images/cube_env256.dds" )
			textureFringe = dxCreateTexture ( "images/ColorRamp01.png" )
			
			dxSetShaderValue ( myShader, "sRandomTexture", textureVol )
			dxSetShaderValue ( myShader, "sReflectionTexture", textureCube )
			dxSetShaderValue ( myShader, "sFringeMap", textureFringe )
			dxSetShaderValue ( myShader, "gFilmDepth", filmDepth )
			dxSetShaderValue ( myShader, "gFilmIntensity", filmIntensity )
			dxSetShaderValue ( myShader, "gFilmDepthEnable", filmDepthEnable )
			
			-- Apply to world texture
			engineApplyShaderToWorldTexture ( myShader, "vehiclegrunge256" )
			engineApplyShaderToWorldTexture ( myShader, "?emap*" )
									
			for _,addList in ipairs(texturegrun) do
			engineApplyShaderToWorldTexture (myShader, addList )
		    end

			cpEffectEnabled = true
		else	
			outputChatBox( "Could not create shader. Please use debugscript 3",255,0,0 ) return
		end
end

function stopCarPaint()
	if not cpEffectEnabled then return end
	engineRemoveShaderFromWorldTexture ( myShader,"*" )
	destroyElement( myShader )
	destroyElement( textureVol )
	destroyElement( textureCube )
	destroyElement( textureFringe )
	myShader = nil
	textureVol = nil
	textureCube = nil
	textureFringe = nil
	cpEffectEnabled = false
end
