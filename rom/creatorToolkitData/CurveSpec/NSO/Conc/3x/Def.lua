
local rootSpec = CurveSpec()

local Embankment = require('Lib.Embankment')

local center = require("NSO.Conc.NoBank")
local left   = center:Clone()
local right  = center:Clone()

local separation = 4.5

local ISet = left.TrainPhysics[0].InterpolationSettings


do -- Create Embankment
	-- Pass nil to settings argument to use defaults.
	local extrusion = Embankment({Colour = Color255(77, 77, 62, 255), TopWidth = 15,BottomWidth = 33, YOffset = -0.25 }, ISet)
	rootSpec.Extrusions:Add(extrusion)
end


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