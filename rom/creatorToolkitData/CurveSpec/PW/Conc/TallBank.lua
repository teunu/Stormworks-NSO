
local Spec = require('PW.Conc.NoBank')
local Bank = require('Lib.Embankment')

local BISet = InterpolationSettings()
BISet.MaxInterpolationDistance = 200
BISet.MaxAngleBetweenInterpolations = 0.01
BISet.MaxSegmentOffset = 0.1
BISet.MinInterpolationDistance = 10

do
	local Extrusion = Bank(
		{
			Colour = Color255(77, 77, 62, 255),
			Height = 7.5,
			BottomWidth = 24,
			YOffset = -0.25
		},
		BISet
	)
	Spec.Extrusions:Add(Extrusion)
end

return Spec