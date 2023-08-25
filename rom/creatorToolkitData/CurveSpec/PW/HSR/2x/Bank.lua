
local rootSpec = CurveSpec()
rootSpec.MaxSegmentLength = 200

local Embankment = require('Lib.Embankment')

local left  = require("PW.HSR.Def")
local right = left:Clone()

local separation = 4.75

local BISet = left.TrainPhysics[0].InterpolationSettings
BISet.MaxInterpolationDistance = 200
BISet.MaxAngleBetweenInterpolations = 0.01
BISet.MaxSegmentOffset = 0.1
BISet.MinInterpolationDistance = 20

do -- Create Embankment
	-- Pass nil to settings argument to use defaults.
	local extrusion = Embankment(
		{
			Colour = Color255(63, 61, 53, 255),
			TopWidth = 12,
			BottomWidth = 14,
			Height = 0.75,
			YOffset = -0.6
		},
		BISet
	)
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