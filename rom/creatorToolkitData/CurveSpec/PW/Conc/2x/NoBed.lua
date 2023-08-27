local rootSpec = CurveSpec()
rootSpec.MaxSegmentLength = 200


local left  = require('PW.Conc.NoBed')
local right = left:Clone()

local separation = 4.75

local scale = left.Transform.LocalScale
left.Transform.LocalScale  = Vector3(1,1,1)
right.Transform.LocalScale = Vector3(1,1,1)


local o = left.Transform.LocalPosition

o.X = - separation / 2
left.Transform.LocalPosition = o

o.X = separation / 2
right.Transform.LocalPosition = o

rootSpec.SubSpecs:Add(left)
rootSpec.SubSpecs:Add(right)

rootSpec.Transform.LocalScale = scale

return rootSpec