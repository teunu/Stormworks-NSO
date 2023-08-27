local rootSpec   = CurveSpec()

local Colours    = require('Lib.Colours')
local Embankment = require('Lib.Embankment')
local left       = require('PW.Conc.Def')
local right      = left:Clone()

local separation = 4.75

local BISet = left.TrainPhysics[0].InterpolationSettings

do -- Create Embankment
	-- Pass nil to settings argument to use defaults.
	local extrusion = Embankment(
		{
			Colour      = Colours.Rock,
			TopWidth    = 10.75,
			Height      = 0.5,
			BottomWidth = 13.75,
			YOffset     = -0.6
		},
		BISet
	)
	rootSpec.Extrusions:Add(extrusion)
end


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