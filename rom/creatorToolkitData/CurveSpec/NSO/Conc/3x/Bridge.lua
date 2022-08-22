


local rootSpec = CurveSpec()


local center = require("NSO.Conc.Bridge")
local left   = center:Clone()
local right  = center:Clone()

local separation = 4.5


local scale = center.Transform.LocalScale
center.Transform.LocalScale = Vector3(1,1,1)
left.Transform.LocalScale   = Vector3(1,1,1)
right.Transform.LocalScale  = Vector3(1,1,1)


local o = center.Transform.LocalPosition

o.X = - separation
left.Transform.LocalPosition = o

o.X = separation
right.Transform.LocalPosition = o


rootSpec.SubSpecs:Add(center)
rootSpec.SubSpecs:Add(left)
rootSpec.SubSpecs:Add(right)

rootSpec.Transform.LocalScale = scale


return rootSpec