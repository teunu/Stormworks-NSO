local Spec = CurveSpec()

local Bed     = require('Lib.Railbed')

Spec.MaxSegmentLength = 200

-- Embankment InterpolationSettings
local BISet = InterpolationSettings()
BISet.MaxInterpolationDistance      = 200
BISet.MaxAngleBetweenInterpolations = 0.01
BISet.MaxSegmentOffset              = 0.1
BISet.MinInterpolationDistance      = 10

do
	local RailBed = Bed(Bed.Presets.Gravel, BISet)
	Spec.Extrusions:Add(RailBed)
end

return Spec