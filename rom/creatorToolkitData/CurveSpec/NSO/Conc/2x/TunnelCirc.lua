
local rootSpec = CurveSpec()

local Tunnel = require('Lib.Tunnel')

local left  = require("NSO.Conc.NoBank")
local right = left:Clone()

local separation = 4.5

local ISet = left.TrainPhysics[0].InterpolationSettings


do -- Create Embankment
	-- Pass nil to settings argument to use defaults.
	local extrusion = Tunnel({Colour = Color255(77, 77, 62, 255), WallColour = Color255(80, 80, 80, 255), Shape = "circle", ShapeParam = 9, Width = 9, Height = 10, YOffset = -0.25 }, ISet)
	rootSpec.Extrusions:Add(extrusion)
end


local scale = left.Transform.LocalScale
left.Transform.LocalScale = Vector3(1,1,1)
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