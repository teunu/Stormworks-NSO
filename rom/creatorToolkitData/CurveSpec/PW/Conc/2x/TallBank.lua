
local rootSpec = CurveSpec()

local Embankment = require('Lib.Embankment')

local left  = require("PW.Conc.NoBank")
local right = left:Clone()

local separation = 4.75

local BISet = left.TrainPhysics[0].InterpolationSettings


do -- Create Embankment
	-- Pass nil to settings argument to use defaults.
	local extrusion = Embankment({Colour = Color255(77, 77, 62, 255), TopWidth = 10.5, BottomWidth = 28.5, Height = 7.5, YOffset = -0.25 }, BISet)
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