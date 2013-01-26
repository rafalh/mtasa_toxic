
-- c_car_reflect.lua
--
local Variables = {}
Variables.renderDistance= 50 -- shader will be applied to textures nearer than this
Variables.brightnessFactorPaint= 0.081
Variables.brightnessFactorWShield= 0.49
Variables.bumpSize =0.02 -- for car paint
Variables.bumpSizeWnd =0 -- for windshields
Variables.normal = 1.5 -- the higher , the less normalised 0-2
Variables.brightnessAdd =0.5 -- before bright pass
Variables.brightnessMul = 1.5 -- multiply after brightpass
Variables.brightpassCutoff = 0.16 -- 0-1
Variables.brightpassPower = 2 -- 1-5
Variables.reflectionFlip = 1 -- 0 or 1
Variables.reflectionFlipAngle =0.25 -- -1,1
Variables.dirtTexture = 1 -- 0 or 1

Variables.sProjectedXsize=0.5
Variables.sProjectedXvecMul=1
Variables.sProjectedXoffset=-0.021
Variables.sProjectedYsize=0.5
Variables.sProjectedYvecMul=1
Variables.sProjectedYoffset=-0.22

local g_Shaders = {
	grunShader = {
		"vehiclegrunge256", "?emap*",
		"predator92body128", "monsterb92body256a", "monstera92body256a", "andromeda92wing", "fcr90092body128",
		"hotknifebody128b", "hotknifebody128a", "rcbaron92texpage64", "rcgoblin92texpage128", "rcraider92texpage128", 
		"rctiger92body128", "rhino92texpage256", "petrotr92interior128", "artict1logos","rumpo92adverts256", "dash92interior128",
		"coach92interior128","combinetexpage128","hotdog92body256",
		"raindance92body128", "cargobob92body256", "andromeda92body", "at400_92_256", "nevada92body256",
		"polmavbody128a", "sparrow92body128", "hunterbody8bit256a", "seasparrow92floats64" , 
		"dodo92body8bit256", "cropdustbody256", "beagle256", "hydrabody256", "rustler92body256", 
		"shamalbody256", "skimmer92body128", "stunt256", "maverick92body128", "leviathnbody8bit256" },
	geneShader = {"vehiclegeneric256", "hotdog92glass128", "okoshko"},
	shatShader = {"vehicleshatter128"},
}

local scx, scy = guiGetScreenSize()
local myScreenSource, textureVol

local function updateScreen()
	if myScreenSource then
		dxUpdateScreenSource(myScreenSource)
	end
end

function enableCarReflect()
		-- Version check
		if getVersion ().sortable < "1.3.0" then
			--outputChatBox( "Resource is not compatible with this client." )
			return false
		end
		
		-- you migh want to experiment with differend resolutions and bumpsizes
		myScreenSource = dxCreateScreenSource ( scx/2, scy/2 )
		
		grunShader = dxCreateShader("car_refgrun.fx",1,Variables.renderDistance,false)
		geneShader = dxCreateShader("car_refgene.fx",1,Variables.renderDistance,true)
		shatShader = dxCreateShader("car_refgene.fx",1,Variables.renderDistance,true)
		
		if not grunShader or not geneShader or not shatShader then
			return false
			--outputChatBox( "Could not create shader. Please use debugscript 3" )
		else
			--outputChatBox( "Started: Shader Car paint reflect.")
						
			addEventHandler ( "onClientHUDRender", getRootElement (), updateScreen )
	
			--Set variables
			dxSetShaderValue ( grunShader, "sCutoff",Variables.brightpassCutoff)
			dxSetShaderValue ( grunShader, "sPower", Variables.brightpassPower)			
			dxSetShaderValue ( grunShader, "sAdd", Variables.brightnessAdd)
			dxSetShaderValue ( grunShader, "sMul", Variables.brightnessMul)
			dxSetShaderValue ( grunShader, "sRefFl", Variables.reflectionFlip)
			dxSetShaderValue ( grunShader, "sRefFlan", Variables.reflectionFlipAngle)
			dxSetShaderValue ( grunShader, "sNorFac", Variables.normal)
		    dxSetShaderValue ( grunShader, "brightnessFactor",Variables.brightnessFactorPaint)  
			
			dxSetShaderValue ( geneShader, "sCutoff",Variables.brightpassCutoff)
			dxSetShaderValue ( geneShader, "sPower", Variables.brightpassPower)	
			dxSetShaderValue ( geneShader, "sAdd", Variables.brightnessAdd)
			dxSetShaderValue ( geneShader, "sMul", Variables.brightnessMul)
			dxSetShaderValue ( geneShader, "sRefFl", Variables.reflectionFlip)
			dxSetShaderValue ( geneShader, "sRefFlan", Variables.reflectionFlipAngle)
			dxSetShaderValue ( geneShader, "sNorFac", Variables.normal)
            dxSetShaderValue ( geneShader, "brightnessFactor",Variables.brightnessFactorWShield) 
			
		    dxSetShaderValue ( shatShader, "sCutoff",Variables.brightpassCutoff)
			dxSetShaderValue ( shatShader, "sPower", Variables.brightpassPower)	
			dxSetShaderValue ( shatShader, "sAdd", Variables.brightnessAdd)
			dxSetShaderValue ( shatShader, "sMul", Variables.brightnessMul)
			dxSetShaderValue ( shatShader, "sRefFl", Variables.reflectionFlip)
			dxSetShaderValue ( shatShader, "sRefFlan", Variables.reflectionFlipAngle)
			dxSetShaderValue ( shatShader, "sNorFac", Variables.normal)
			dxSetShaderValue ( shatShader, "brightnessFactor",Variables.brightnessFactorWShield) 		
			
			dxSetShaderValue ( grunShader, "dirtTex",Variables.dirtTexture)
		    dxSetShaderValue ( grunShader, "bumpSize",Variables.bumpSize)
			dxSetShaderValue ( geneShader, "bumpSize",Variables.bumpSizeWnd)

			dxSetShaderValue ( grunShader, "sProjectedXsize",Variables.sProjectedXsize)
			dxSetShaderValue ( grunShader, "sProjectedXvecMul",Variables.sProjectedXvecMul)
			dxSetShaderValue ( grunShader, "sProjectedXoffset",Variables.sProjectedXoffset)
			dxSetShaderValue ( grunShader, "sProjectedYsize",Variables.sProjectedYsize)
			dxSetShaderValue ( grunShader, "sProjectedYvecMul",Variables.sProjectedYvecMul)
			dxSetShaderValue ( grunShader, "sProjectedYoffset",Variables.sProjectedYoffset)
			
			dxSetShaderValue ( geneShader, "sProjectedXsize",Variables.sProjectedXsize)
			dxSetShaderValue ( geneShader, "sProjectedXvecMul",Variables.sProjectedXvecMul)
			dxSetShaderValue ( geneShader, "sProjectedXoffset",Variables.sProjectedXoffset)
			dxSetShaderValue ( geneShader, "sProjectedYsize",Variables.sProjectedYsize)
			dxSetShaderValue ( geneShader, "sProjectedYvecMul",Variables.sProjectedYvecMul)
			dxSetShaderValue ( geneShader, "sProjectedYoffset",Variables.sProjectedYoffset)

			dxSetShaderValue ( shatShader, "sProjectedXsize",Variables.sProjectedXsize)
			dxSetShaderValue ( shatShader, "sProjectedXvecMul",Variables.sProjectedXvecMul)
			dxSetShaderValue ( shatShader, "sProjectedXoffset",Variables.sProjectedXoffset)
			dxSetShaderValue ( shatShader, "sProjectedYsize",Variables.sProjectedYsize)
			dxSetShaderValue ( shatShader, "sProjectedYvecMul",Variables.sProjectedYvecMul)
			dxSetShaderValue ( shatShader, "sProjectedYoffset",Variables.sProjectedYoffset)
		
			-- Set textures
			textureVol = dxCreateTexture ( "images/smallnoise3d.dds" );
			
			dxSetShaderValue ( grunShader, "sRandomTexture", textureVol );
			dxSetShaderValue ( grunShader, "sReflectionTexture", myScreenSource );
            
			dxSetShaderValue ( geneShader, "gShatt", 0 );
			dxSetShaderValue ( geneShader, "sRandomTexture", textureVol );
			dxSetShaderValue ( geneShader, "sReflectionTexture", myScreenSource );
			
			dxSetShaderValue ( shatShader, "gShatt", 1 );
            dxSetShaderValue ( shatShader, "sRandomTexture", textureVol );
			dxSetShaderValue ( shatShader, "sReflectionTexture", myScreenSource );			
			
			for shaderName, textures in pairs(g_Shaders) do
				local shader = _G[shaderName]
				if(shader) then
					for i, texName in ipairs(textures) do
						engineApplyShaderToWorldTexture(shader, texName)
					end
				else
					outputDebugString("Shader is invalid "..shaderName, 2)
				end
			end
			
			return true
		end
		
end

function disableCarReflect()
	removeEventHandler("onClientHUDRender", getRootElement(), updateScreen)
	destroyElement(grunShader)
	destroyElement(geneShader)
	destroyElement(shatShader)
	destroyElement(textureVol)
	destroyElement(myScreenSource)
end