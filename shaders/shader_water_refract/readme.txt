Resource: Shader Water Refract 0.1.6
Author: Ren712
Contact: knoblauch700@o2.pl
Update 0.1.6:
-the refraction is drawn permanently, without effect switching (SM3, MRT and DB required)
Update 0.1.5:
-the refraction enabled effects are now working properly with or without anti aliasing 
  (resigned from ZWriteEnable state and replaced with readable depthBuffer masking)
Update 0.1.4:
-the effect doesn't require readable depthbuffer support (but might use it to fix refraction leaking)
-shader model 2.0 support (no sunlight)
-more accurate fog fading
-water texture masking (if MRT in shaders enabled)
Update 0.1.3:
-reverted effect type back to 0.0.8 (Does not reqire MRT in shader)
-rewritten matrix calculations
-simplified tex_water effect
Update 0.0.7:
-minimized refraction bleeding for objects above water
-two dxImages are being drawn (instead of 9)
-updated list of excluded zones
Update 0.0.6:
-added refraction distortion multiplier
-lowered the water alpha multiplier

This resource works with (but does not require) shader_dynamic_sky:
https://community.multitheftauto.com/index.php?p=resources&s=details&id=6828

The shader is applied to water texture. It makes refractions
of what is below and in it. The method used doesn't need a separate frame to pick 
the refraction texture like used in a previous water refract resource. Instead i've used
dxDrawImage transformed to world space.

The effect also creates a light sun specular on the water surface. The position of 
the highlight changes during the night and day.

The resource might not work on some older GFX (especially INTEL).

-- Reading depth buffer supported by:
-- NVidia - from GeForce 6 (2004)
-- Radeon - from 9500 (2002)
-- Intel - from G45 (2008)