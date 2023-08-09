
local Spec   = require('PW.Conc.NoBank')
local Tunnel = require('Lib.Tunnel')

local BISet = InterpolationSettings()
BISet.MaxInterpolationDistance = 200
BISet.MaxAngleBetweenInterpolations = 0.01
BISet.MaxSegmentOffset = 0.1
BISet.MinInterpolationDistance = 20

do
	local Extrusion = Tunnel(
		{
			Colour     = Color255(77, 77, 62, 255),
			WallColour = Color255(80, 80, 80, 255),
			Shape      = "circle",
			ShapeParam = 9,
			Width   = 5,
			Height  = 8,
			YOffset = -0.25
		},
		BISet
	)
	Spec.Extrusions:Add(Extrusion)
end

return Spec