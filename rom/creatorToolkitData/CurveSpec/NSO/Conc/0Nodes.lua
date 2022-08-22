
local Rails	= require('Lib.NSORailGenerator')

local spec = CurveSpec()
local ISet = InterpolationSettings()

ISet.MaxInterpolationDistance		= 50 -- meters
ISet.MaxAngleBetweenInterpolations	= 0.01 -- degrees
ISet.MaxSegmentOffset				= 0.1 -- meters
ISet.MinInterpolationDistance		= 4 -- meters

do -- Make trains be able to drive
	local train = TrainPhysics()
	local MySettings	= ISet:Clone()

	MySettings.MaxInterpolationDistance	= 500
	MySettings.MinInterpolationDistance	= 400

	train.InterpolationSettings	= MySettings

	spec.TrainPhysics:Add(train)
end

do -- Add rails
	local railSettings = Rails.presets.UIC60
	local extrusion = Rails(railSettings, ISet)

	-- Convert to stormworks (wide) gauge.
	extrusion.Transform.LocalScale = Vector3(1.115, 1.115, 1)

	spec.Extrusions:Add(extrusion)
end

spec.Periodics:Add(require('lib.Sleepers'))

return spec