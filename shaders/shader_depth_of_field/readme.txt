Resource: Shader Depth of Field v0.1.0
Author: Ren712
Contact: knoblauch700@o2.pl

version 0.1.0
-Removed focal adaptation lua code ( all that is needed is in shader)
-Added depth sorting algorythm to prevent color bleeding.

This resource adds a simple full screen effect.
What it does is create the depth of field effect.
Works good with all the postprocess shaders.

The resource might not work on some older GFX (especially INTEL).
It is due to Zbuffer usage.

-- Reading depth buffer supported by:
-- NVidia - from GeForce 6 (2004)
-- Radeon - from 9500 (2002)
-- Intel - from G45 (2008)