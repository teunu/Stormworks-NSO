
local Spec = require('PW.HSR.NoBank')
local Bed  = require('Lib.Railbed')
local Bank = require('Lib.Embankment')

local BISet = InterpolationSettings()
BISet.MaxInterpolationDistance = 200
BISet.MaxAngleBetweenInterpolations = 0.01
BISet.MaxSegmentOffset = 0.1
BISet.MinInterpolationDistance = 20

do
	local RailBed = Bed(Bed.Presets.Concrete, BISet)
	Spec.Extrusions:Add(RailBed)
end

do
	local extrusion = Bank(
		{
			Colour = Color255(77, 77, 62, 255),
			BottomWidth = 24,
			YOffset = -0.25
		},
		BISet
	)
	Spec.Extrusions:Add(extrusion)
end

return Spec