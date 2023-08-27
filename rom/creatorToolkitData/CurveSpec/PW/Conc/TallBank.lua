local Spec    = require('PW.Conc.Def')
local Bank    = require('Lib.Embankment')
local Colours = require('Lib.Colours')

local BISet = InterpolationSettings()
BISet.MaxInterpolationDistance      = 200
BISet.MaxAngleBetweenInterpolations = 0.01
BISet.MaxSegmentOffset              = 0.1
BISet.MinInterpolationDistance      = 10

do
	local Extrusion = Bank(
		{
			Colour      = Colours.Rock,
			Height      = 7.5,
			BottomWidth = 24,
			YOffset     = -0.6
		},
		BISet
	)
	Spec.Extrusions:Add(Extrusion)
end

return Spec