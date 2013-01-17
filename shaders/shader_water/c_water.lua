--
-- c_water.lua
--

local textureVol, textureCube
local g_Timer

function enableWater ()

		-- Version check
		if getVersion ().sortable < "1.1.0" then
			outputChatBox( "Resource is not compatible with this client." )
			return
		end

		-- Create shader
		myShader, tec = dxCreateShader ( "water.fx" )

		if not myShader then
			--outputChatBox( "Could not create shader. Please use debugscript 3" )
			return false
		else
			--outputChatBox( "Using technique " .. tec )

			-- Set textures
			textureVol = dxCreateTexture ( "images/smallnoise3d.dds" );
			textureCube = dxCreateTexture ( "images/cube_env256.dds" );
			dxSetShaderValue ( myShader, "sRandomTexture", textureVol );
			dxSetShaderValue ( myShader, "sReflectionTexture", textureCube );

			-- Update water color incase it gets changed by persons unknown
			g_Timer = setTimer(	function()
							if myShader then
								local r,g,b,a = getWaterColor()
								dxSetShaderValue ( myShader, "sWaterColor", r/255, g/255, b/255, a/255 );
							end
						end
						,100,0 )
			
			engineApplyShaderToWorldTexture ( myShader, "waterclear256" )
			
			return true
		end
end

function disableWater()
	killTimer(g_Timer)
	destroyElement(myShader)
	destroyElement(textureVol)
	destroyElement(textureCube)
end
