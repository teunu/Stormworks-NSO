
local Spec = require('PW.Conc.NoBank')
local Bank = require('Lib.Embankment')

-- Embankment InterpolationSettings
local BISet = InterpolationSettings()
BISet.MaxInterpolationDistance = 200
BISet.MaxAngleBetweenInterpolations = 0.01
BISet.MaxSegmentOffset = 0.1
BISet.MinInterpolationDistance = 10

do
	local extrusion = Bank(
		{
			Colour = Color255(77, 77, 62, 255),
			BottomWidth = 9,
			Height = 0.5,
			YOffset = -0.25
		},
		BISet
	)
	Spec.Extrusions:Add(extrusion)
end

return Spec