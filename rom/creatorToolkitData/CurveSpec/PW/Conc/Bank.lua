local Spec    = require('PW.Conc.NoBed')
local Bed     = require('Lib.Railbed')
local Bank    = require('Lib.Embankment')
local Colours = require('Lib.Colours')

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

do
	local extrusion = Bank(
		{
			Colour      = Colours.Rock,
			BottomWidth = 9,
			Height      = 0.5,
			YOffset     = -0.6
		},
		BISet
	)
	Spec.Extrusions:Add(extrusion)
end

return Spec