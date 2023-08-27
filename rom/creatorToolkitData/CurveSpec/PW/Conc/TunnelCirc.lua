local Spec    = require('PW.Conc.NoBed')
local Tunnel  = require('Lib.Tunnel')
local Colours = require('Lib.Colours')

local BISet = InterpolationSettings()
BISet.MaxInterpolationDistance      = 200
BISet.MaxAngleBetweenInterpolations = 0.01
BISet.MaxSegmentOffset              = 0.1
BISet.MinInterpolationDistance      = 20

do
	local Extrusion = Tunnel(
		{
			Colour     = Colours.Gravel,
			WallColour = Colours.Grey,
			Shape      = "circle",
			ShapeParam = 9,
			Width      = 5,
			Height     = 8,
			YOffset    = -0.25
		},
		BISet
	)
	Spec.Extrusions:Add(Extrusion)
end

return Spec