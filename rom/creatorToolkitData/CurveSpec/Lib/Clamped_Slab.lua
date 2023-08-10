local Settings = require('Lib.Settings')
local Interval = 0.6

local Spec = PeriodicItemSpec()
Spec.Physics = false

local Group = PeriodicGroup()
Group.IdealDistance = Interval

local Sleeper = MeshSpec()
Sleeper.MeshPath = "nso_mod/meshes/railway/Sleeper_Slab.mesh"
Sleeper.Transform.LocalPosition = Vector3(0, -0.315, 0)

Group.Entries:Add(Sleeper)

Spec.Items:Add(Group)

Spec.Enabled = Settings.SleepersOn

return Spec