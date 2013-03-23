---------------------------------------------------------------------------------
--
-- Nitro shader
--
--
---------------------------------------------------------------------------------

local R, G, B = 255, 128, 0
local g_Shader

-- This function will set the new color of the nitro
function enableNitroClr()
	g_Shader = dxCreateShader("nitro.fx")
	engineApplyShaderToWorldTexture(g_Shader, "smoke")
	dxSetShaderValue(g_Shader, "gNitroColor", R/255, G/255, B/255 )
end

-- This function will reset the nitro back to the original
function disableNitroClr()
	engineRemoveShaderFromWorldTexture(g_Shader, "smoke")
	destroyElement(g_Shader)
end
