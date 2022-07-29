function onCreate(is_world_create)
	if is_world_create then
		spawnAll()
	end
end

function spawnAll()
	local addonIndex = server.getAddonIndex()
	local anchorComponentId

	for locationIndex = 0, server.getAddonData(addonIndex).location_count - 1 do
		local locationData = server.getLocationData(addonIndex, locationIndex)
		if not locationData.is_env_mod then
			for componentIndex = 0, locationData.component_count - 1 do
				local componentData = server.getLocationComponentData(addonIndex, locationIndex, componentIndex)
				for i, tag in pairs(componentData.tags) do
					if tag == "default_bollard" then
						anchorComponentId = componentData.id
					end
				end
			end
		end
	end

	local spawn_zones = server.getZones("bollard_zone")

	for _, zone in pairs(spawn_zones) do
		local spawn_transform = matrix.multiply(zone.transform, matrix.translation(0, -zone.size.y - 0.01, 0))
		local id = server.spawnAddonVehicle(spawn_transform, addonIndex, anchorComponentId)
	end
end
