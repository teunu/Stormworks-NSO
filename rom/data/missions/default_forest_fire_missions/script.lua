g_savedata = { missions = {}}

function onForestFireExtinguished(objective_id, x, y, z)

    removeMissionMarkers(g_savedata.missions[objective_id + 1])

end

function onForestFireSpawned(objective_id, x, y, z)

    server.notify(-1, "New Forest Fire", "The location has been marked on your map.", 0)

    g_savedata.missions[objective_id + 1] = { map_markers = {}, data = {} }

    g_savedata.missions[objective_id + 1].title = "Forest Fire"
    g_savedata.missions[objective_id + 1].desc = "Extinguish the fire before it spreads further!"
    g_savedata.missions[objective_id + 1].data.zone_radius = 4000 * (math.random(25, 100) / 100)
	local radius_offset = g_savedata.missions[objective_id + 1].data.zone_radius * (math.random(20, 90) / 100)
    local angle = math.random(0,100) / 100 * 2 * math.pi
    g_savedata.missions[objective_id + 1].data.zone_x = x + radius_offset * math.cos(angle)
    g_savedata.missions[objective_id + 1].data.zone_z = z + radius_offset * math.sin(angle)

    addMarker(g_savedata.missions[objective_id + 1], createZoneMarker(g_savedata.missions[objective_id + 1].data.zone_radius, g_savedata.missions[objective_id + 1].data.zone_x, g_savedata.missions[objective_id + 1].data.zone_z, g_savedata.missions[objective_id + 1].title, g_savedata.missions[objective_id + 1].desc))

end

function onPlayerJoin(steamid, name, peerid, admin, auth)
	if g_savedata.missions ~= nil then
		for k, mission_data in pairs(g_savedata.missions) do
			for k, marker in pairs(mission_data.map_markers) do
				server.addMapObject(peerid, marker.id, 0, 8, marker.x, marker.z, 0, 0, 0, 0, marker.display_label,marker.radius, marker.hover_label)
			end
		end
	end
end

function addMarker(mission_data, marker_data)
	table.insert(mission_data.map_markers, marker_data)
	server.addMapObject(-1, marker_data.id, 0, marker_data.type, marker_data.x, marker_data.z, 0, 0, 0, 0, marker_data.display_label, marker_data.radius, marker_data.hover_label)
end

function createZoneMarker(radius, x, z, display_label, hover_label)	
	local map_id = server.getMapID()

	return { 
		id = map_id, 
		type = 8,
		x = x, 
		z = z, 
		radius = radius, 
		display_label = display_label, 
		hover_label = hover_label 
	}
end

function removeMissionMarkers(mission)
	for i = 1, #mission.map_markers do
		server.removeMapObject(-1, mission.map_markers[i].id)
	end
	mission.map_markers = {}
end