--
-- c_switch.lua
--

----------------------------------------------------------------
----------------------------------------------------------------
-- Effect switching on and off
--
--	To switch on:
--			triggerEvent( "switchDoF", root, true )
--
--	To switch off:
--			triggerEvent( "switchDoF", root, false )
--
----------------------------------------------------------------
----------------------------------------------------------------

--------------------------------
-- onClientResourceStart
--		Auto switch on at start
--------------------------------
local forceOnIfNoDB = false 
addEventHandler( "onClientResourceStart", getResourceRootElement( getThisResource()),
	function()
		if isDepthBufferAccessible() or forceOnIfNoDB then 
			triggerEvent( "switchDoF", resourceRoot, 0 )
			addCommandHandler( "sDoF",
				function()
					triggerEvent( "switchDoF", resourceRoot, not dEffectEnabled )
				end)
		else
			outputChatBox('DoF: Depth Buffer not supported',255,0,0) return 
		end
	end
)


--------------------------------
-- Switch effect on or off
--------------------------------
function switchDoF( aaOn )
	outputDebugString( "switchDoF: " .. tostring(aaOn) )
	if aaOn then
		enableDoF()
	else
		disableDoF()
	end
end

addEvent( "switchDoF", true )
addEventHandler( "switchDoF", resourceRoot, switchDoF )
