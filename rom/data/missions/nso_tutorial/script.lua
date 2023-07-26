g_savedata = {
	["mission"] = { objects = {}, survivor_list = {}},
	career_info_id = -1,
	tutorial_stage = 0,
	["boatID"] = -1,
	["destboatID"] = -1,
	["destX"] = 0,
	["destY"] = 0,
	["destZ"] = 0,
	["playerRespawningBoat"] = false,
	["notifyVideo"] = false,
	["starterBoatSpawned"] = false
}

STAGE_NONE = 0
STAGE_TUTORIAL_STARTED = 1
STAGE_OUTSIDE_HOUSE = 2
STAGE_AT_HILL = 3
STAGE_AT_STAIRS = 4
STAGE_AT_DOCK = 5
STAGE_SAT_IN_BOAT = 6
STAGE_LEFT_DOCK = 7
STAGE_ARRIVED_AT_BOAT = 8
STAGE_FIRE_EXTINGUISHED = 9
STAGE_IS_ZONE = 10
STAGE_RETURN_TO_BOAT = 11
STAGE_WAITING_FOR_PLAYER_VEHICLE = 12
STAGE_TUTORIAL_ENDED = 13

update_timer = 0

function onCreate(is_world_create)
	if g_savedata.settings == nil then
		g_savedata.settings = {
			PLAYER_STARTING_GRANT = property.slider("Player Starting Grant", 1000, 12000, 1000, 3000),
			GRADUATION_THRESHOLD = property.slider("Prestige Reward on Tutorial Completion", 0, 500, 50, 100)
		}
	end

	if is_world_create then
		server.setTutorial(true) -- prevent missions spawning immediately

		g_savedata["UIID"] = server.getMapID()
		g_savedata["UIID2"] = server.getMapID()
		g_savedata["UIID3"] = server.getMapID()
		g_savedata["Deltars"] = server.getMapID()
		g_savedata["RoboJon"] = server.getMapID()
	end

	UpdateUI()
end

function onTick(delta_worldtime)
	
	--server.notify(user_peer_id, "debug", tostring(update_timer), 6)

	if update_timer == 70 then
		GetNSOCareerData()
		server.notify(user_peer_id, "NSO Tutorial", "cid: " .. tostring(g_savedata.career_info_id), 6)
	end

	for the_id, v2 in pairs(g_savedata["mission"].survivor_list) do
		if v2["rescued"] then
			if v2.convert_timer <= 180 then
				v2.convert_timer = v2.convert_timer + 1
			end
			if v2.convert_timer == 180 then
				server.setCharacterData(the_id, 100, false, false)
			end
		end
	end

	update_timer = update_timer + 1

	if (g_savedata.tutorial_stage > STAGE_NONE and g_savedata.tutorial_stage ~= STAGE_TUTORIAL_ENDED) then
		if update_timer == 60 then
			local players = server.getPlayers()
			for player_index, player_object in pairs(players) do
				local player_pos = server.getPlayerPos(player_object.id)
				local x, y, z = matrix.position(player_pos)
				local distSQ = ((-56 - x)^2) + ((24.7 - y)^2) + ((0 - z)^2)
				if(distSQ > 2500 * 2500) then
					end_mission()
					break
				end
			end
		end
	end

	if(g_savedata.tutorial_stage == STAGE_NONE) then
		if update_timer > 60 then
			update_timer = 0
			local players = server.getPlayers()
			for player_index, player_object in pairs(players) do
				local player_pos = server.getPlayerPos(player_object.id)
				local x, y, z = matrix.position(player_pos)
				local is_purchased_beginner = server.getTilePurchased(matrix.translation(0,0,0))
				local distSQ = ((56 - x)^2) + ((27.7 - y)^2) + ((43 - z)^2)
				if(distSQ < 15 and is_purchased_beginner and server.getGameSettings().unlock_all_components == true and server.getDateValue() < 7) then
					g_savedata.tutorial_stage = STAGE_TUTORIAL_STARTED
					g_savedata["notifyVideo"] = true
					server.setTutorial(true)
					break
				else
					player_not_loading = x ~= 0 and y ~= 0 and z~= 0
					if (player_not_loading and server.getTutorial() == true) then -- allow missions to spawn
						server.setTutorial(false)
					end
				end
			end
		end
		
		g_savedata.tutorial_stage = STAGE_TUTORIAL_STARTED
		server.setTutorial(true)

	elseif(g_savedata.tutorial_stage == STAGE_TUTORIAL_STARTED) then
		local players = server.getPlayers()
		server.setCurrency(0, server.getResearchPoints())

		server.announce(server.getAddonIndex());

		if(g_savedata["starterBoatSpawned"] == false) then
			local playlist_index = server.getAddonIndex()
			server.spawnMissionLocation(matrix.translation(0,0,0), playlist_index, (server.getLocationIndex(playlist_index, "starter")))
			server.spawnMissionLocation(matrix.translation(0,0,0), playlist_index, (server.getLocationIndex(playlist_index, "crash")))


			g_savedata["starterBoatSpawned"] = true
		end

		for player_index, player_object in pairs(players) do
			local x, y, z = matrix.position((server.getPlayerPos(player_object.id)))

			local distSQ = ((36.5 - x)^2) + ((22.5 - y)^2) + ((43.01 - z)^2)
			if(distSQ > 10) then
				g_savedata.tutorial_stage = STAGE_OUTSIDE_HOUSE
				UpdateUI()
				break
			end
		end
	elseif(g_savedata.tutorial_stage == STAGE_OUTSIDE_HOUSE) then
		local players = server.getPlayers()
		
		for player_index, player_object in pairs(players) do
			local x, y, z = matrix.position((server.getPlayerPos(player_object.id)))

			local distSQ = ((12.5 - x)^2) + ((22.5 - y)^2) + ((46 - z)^2)
			if(distSQ < 20)
			then
				g_savedata.tutorial_stage = STAGE_AT_HILL
				UpdateUI()
				break
			end
		end
	elseif(g_savedata.tutorial_stage <= STAGE_AT_HILL) then
		local players = server.getPlayers()
		for player_index, player_object in pairs(players) do
			local x, y, z = matrix.position((server.getPlayerPos(player_object.id)))

			local distSQ = ((0 - x)^2) + ((20 - y)^2) + ((55 - z)^2)
			if(distSQ < 20)
			then
				g_savedata.tutorial_stage = STAGE_AT_STAIRS
				UpdateUI()
				break
			end
		end
	elseif(g_savedata.tutorial_stage <= STAGE_AT_STAIRS) then


		local players = server.getPlayers()
		for player_index, player_object in pairs(players) do
			local x, y, z = matrix.position((server.getPlayerPos(player_object.id)))

			local distSQ = ((-116 - x)^2) + ((1.5 - y)^2) + ((75 - z)^2)
			if(distSQ < 10) then
				g_savedata.tutorial_stage = STAGE_AT_DOCK
				UpdateUI()
				break
			end
		end
	elseif(g_savedata.tutorial_stage <= STAGE_SAT_IN_BOAT) then
		local players = server.getPlayers()
		for player_index, player_object in pairs(players) do
			local x, y, z = matrix.position((server.getPlayerPos(player_object.id)))

			local distSQ = ((-27 - x)^2) + ((2 - y)^2) + ((10 - z)^2)
			if(distSQ > 1725)
			then
				g_savedata.tutorial_stage = STAGE_LEFT_DOCK
				UpdateUI()
				break
			end
		end
	elseif(g_savedata.tutorial_stage == STAGE_LEFT_DOCK) then
		local players = server.getPlayers()
		for player_index, player_object in pairs(players) do
			local x, y, z = matrix.position((server.getPlayerPos(player_object.id)))

			local distSQ = ((g_savedata["destX"] - x)^2) + ((g_savedata["destY"] - y)^2) + ((g_savedata["destZ"] - z)^2)
			if(distSQ <= 875)
			then
				g_savedata.tutorial_stage = STAGE_ARRIVED_AT_BOAT
				UpdateUI()
				break
			end
		end
	elseif(g_savedata.tutorial_stage == STAGE_ARRIVED_AT_BOAT) then
		for the_id, v2 in pairs(g_savedata["mission"].objects) do

			if (v2["type"] == "fire")
			then
				local isfirelit = server.getFireData(the_id)

				if (isfirelit == false) then
					g_savedata.tutorial_stage = STAGE_FIRE_EXTINGUISHED
					UpdateUI()
					break
				end
			end
		end
	elseif(g_savedata.tutorial_stage == STAGE_FIRE_EXTINGUISHED) then
		local total_in_progress = 0

		local zonelistSurvivor = server.getZones("hospital")
		for k, zone in pairs(zonelistSurvivor) do
			for the_id, survivor in pairs(g_savedata["mission"].survivor_list) do
				if (survivor["rescued"] == false) then
					total_in_progress = total_in_progress + 1

					local c = server.getCharacterData(the_id)
					local survivor_transform, is_found = server.getObjectPos(the_id)

					if (server.isInZone(survivor_transform, zone.name)) then
						survivor["rescued"] = true
						survivor.convert_timer = 0
						server.removePopup(-1, g_savedata[survivor["name"]])
						server.notify(-1, "Casualty Rescued", survivor["name"].." has been successfully rescued to the hospital.", 4)
					end

					if survivor["healed"] ~= (c.hp >= 100) then
						survivor["healed"] = (c.hp >= 100)
						if(c.hp < 100) then
							server.setPopup(-1, g_savedata[survivor["name"]], "survivor" .. the_id, true, "Heal this survivor using the First Aid Kit stored on your boat", 0, 1.5, 0, 0, 0, the_id)
						else
							server.setPopup(-1, g_savedata[survivor["name"]], "survivor" .. the_id, true, "Rescue this survivor to St. Sebastiaz on Beginner Island!", 0, 1.5, 0, 0, 0, the_id)
						end
					end
				end
			end
		end

		if total_in_progress == 0 then -- all survivors rescued
			g_savedata.tutorial_stage = STAGE_IS_ZONE
			UpdateUI()
		end
	elseif(g_savedata.tutorial_stage == STAGE_IS_ZONE) then
		local players = server.getPlayers()
		for player_index, player_object in pairs(players) do
			local xv, yv, zv = matrix.position((server.getVehiclePos(g_savedata["boatID"])))
			local x, y, z = matrix.position((server.getPlayerPos(player_object.id)))

			local distSQ = ((xv - x)^2) + ((yv - y)^2) + ((zv - z)^2)
			if(distSQ < 15)
			then
				g_savedata.tutorial_stage = STAGE_RETURN_TO_BOAT
				UpdateUI()
				break
			end
		end
	elseif(g_savedata.tutorial_stage == STAGE_RETURN_TO_BOAT) then
		local players = server.getPlayers()
		for player_index, player_object in pairs(players) do
			local x, y, z = matrix.position((server.getPlayerPos(player_object.id)))

			local distSQ = ((-29 - x)^2) + ((2 - y)^2) + ((-12 - z)^2)
			if(distSQ < 20) then
				g_savedata.tutorial_stage = STAGE_WAITING_FOR_PLAYER_VEHICLE
				UpdateUI()
				break
			end
		end
	end
end

function GetNSOCareerData()
	for i = 1, 256, 1 do
		name, is_success = server.getVehicleName(i)
		if not is_success then break end
		if name == nil or name == '' then
			
		else
			if name == 'vehicle_147' then 
				g_savedata.career_info_id = i
				break
			end
		end
	end
end

function UpdateUI()

	if(g_savedata.tutorial_stage == STAGE_OUTSIDE_HOUSE) then
		server.setPopup(-1, g_savedata["UIID"], "obj", true, "Walk towards the lookout", 36.8, 22, 44.2, 0)
	elseif(g_savedata.tutorial_stage == STAGE_AT_HILL) then
		server.setPopup(-1, g_savedata["UIID2"],"obj", true, "Rescue the survivors!", -213, 12.5, -195, 0)
		server.setPopupScreen(-1, g_savedata["UIID"],"obj", true, "A boat has crashed on those rocks! You should help them!", 0.8, -0.8)
	elseif(g_savedata.tutorial_stage == STAGE_AT_STAIRS) then
		server.setPopup(-1, g_savedata["UIID"],"obj", true, "Get to your boat!", -141, 2, 0, 0)
	elseif(g_savedata.tutorial_stage == STAGE_AT_DOCK) then
		server.setPopup(-1, g_savedata["UIID"],"obj", true, "Interact with the boat Helm", 0.5, 1, 3, 0, g_savedata["boatID"])
	elseif(g_savedata.tutorial_stage == STAGE_SAT_IN_BOAT) then
		server.setPopupScreen(-1, g_savedata["UIID"],"obj", true, "Turn the key labelled Engine on the right to start your boat, then hold W to increase the throttle", 0.5, 0.5)
	elseif(g_savedata.tutorial_stage == STAGE_LEFT_DOCK) then
		server.setPopup(-1, g_savedata["UIID"],"obj", true, "Navigate to the rocks, be careful of shallows!", g_savedata["destX"], g_savedata["destY"] + 20, g_savedata["destZ"], 0)
		server.removeMapID(-1, g_savedata["UIID2"])
	elseif(g_savedata.tutorial_stage == STAGE_ARRIVED_AT_BOAT) then
		for the_id, v2 in pairs(g_savedata["mission"].objects) do
			if (v2["type"] == "fire") then
				server.setPopup(-1, g_savedata["UIID"],"obj", true, "Put out this fire using the extinguisher stored in the floor of your boat", g_savedata["destX"] - 0.3, g_savedata["destY"] + 0.5, g_savedata["destZ"] - 2.7, 0)
			end
		end
	elseif(g_savedata.tutorial_stage == STAGE_FIRE_EXTINGUISHED) then
		local zonelistSurvivor = server.getZones("hospital")
		for k, zone in pairs(zonelistSurvivor) do
			local zone_x, zone_y, zone_z =  matrix.position(zone.transform)
			if zone.name == "St. Sebastiaz Hospital" then
				server.setPopup(-1, g_savedata["UIID"],"hospital", true, "Hospital", zone_x, zone_y + 15, zone_z, 0)
			end
			for the_id, survivor in pairs(g_savedata["mission"].survivor_list) do
				server.setPopup(-1, g_savedata[survivor["name"]], "survivor" .. the_id, true, "Rescue this survivor to St. Sebastiaz on Beginner Island!", 0, 1.5, 0, 0, 0, the_id)
			end
		end
	elseif(g_savedata.tutorial_stage == STAGE_IS_ZONE) then
		server.setPopup(-1, g_savedata["UIID"],"obj", true, "Mission Success! Return to your boat", 0, 5, 0, 0, g_savedata["boatID"])
	elseif(g_savedata.tutorial_stage == STAGE_RETURN_TO_BOAT) then
		server.setPopup(-1, g_savedata["UIID"],"obj", true, "Navigate back to the Coastguard Outpost", -29, 10, -12, 0)
	elseif(g_savedata.tutorial_stage == STAGE_WAITING_FOR_PLAYER_VEHICLE) then
		server.setPopup(-1, g_savedata["UIID"],"refuel", true, "Your vehicle will be auto-refueled when respawning it from a workbench.", -23, 6, -2, 0)
		server.setPopup(-1, g_savedata["UIID2"],"workbench", true, "Use this workbench to edit your boat. Respawn your boat to finish the tutorial!",  -33, 6, 17, 0)
		server.setPopup(-1, g_savedata["UIID3"],"bed", true, "Once the tutorial is complete, sleep in any bed to accelerate time and make missions spawn faster.",  -57.7, 24.7, 1.5, 0)
	end
end

function onPlayerSit(id, vehicle, name)
	if(g_savedata.tutorial_stage == STAGE_AT_DOCK) then
		if(vehicle == g_savedata["boatID"]) then
			g_savedata.tutorial_stage = STAGE_SAT_IN_BOAT
			
			UpdateUI()
		end
	end
end

function onSpawnAddonComponent(id, name, type, playlist_index)
	if (playlist_index == server.getAddonIndex()) then

		if(name ~= "starter_crane" and name ~= "tractor" and name ~= "trailer") then
			g_savedata["mission"].objects[id] = {["name"] = name, ["type"] = type}

			if(type == "character") then
				g_savedata["mission"].survivor_list[id] = {["name"] = name, ["type"] = type, ["rescued"] = false, ["healed"] = true, convert_timer = 0}
			elseif(type == "vehicle") then
				if( g_savedata["boatID"] == -1 and name == "boat2") then
					g_savedata["boatID"] = id
				end

				if( g_savedata["destboatID"] == -1 and name == "boatdest") then
					g_savedata["destboatID"] = id
					g_savedata["destX"], g_savedata["destY"], g_savedata["destZ"] = matrix.position((server.getVehiclePos(g_savedata["destboatID"], 0, 0, 0)))
				end
			end
		end
	end
	UpdateUI()
end

function onVehicleDespawn(vehicle_id, peer_id)
	if vehicle_id == g_savedata["boatID"] then
		g_savedata["playerRespawningBoat"] = true
	end
end

function onVehicleSpawn(vehicle_id, peer_id, x, y, z, cost)
	if peer_id >= 0 then
		if server.getVideoTutorial() == false and g_savedata["notifyVideo"] == true then
			server.notify(peer_id, "Video Tutorials", "Video Tutorials can be found in the Esc menu or on the Main menu", 9)
		end

		if g_savedata.tutorial_stage == STAGE_WAITING_FOR_PLAYER_VEHICLE then
			end_mission()
		else
			if g_savedata["playerRespawningBoat"] == true then
				g_savedata["boatID"] = vehicle_id
				g_savedata["playerRespawningBoat"] = false
			end
		end
		UpdateUI()
	end
end

function onPlayerJoin(steam_id, name, peer_id, is_admin, is_auth)
	UpdateUI()
end

function end_mission()

	g_savedata.tutorial_stage = STAGE_TUTORIAL_ENDED

	server.setTutorial(false)

	for k, v in pairs(g_savedata["mission"].objects) do
		local the_id = k
		if(v["type"] == "vehicle" and the_id ~= g_savedata["boatID"]) then
			server.despawnVehicle(the_id, false)
		else
			server.despawnObject(the_id, false)
		end
	end

	server.removeMapID(-1, g_savedata["UIID"])
	server.removeMapID(-1, g_savedata["UIID2"])
	server.removeMapID(-1, g_savedata["UIID3"])

	server.notify(-1, "Missions", "When new missions appear they will pop up here, check your map with M and hover over the marked location for details!", 4)

end

function onCustomCommand(full_message, user_peer_id, is_admin, is_auth, command, arg1, arg2, arg3, arg4)
	if command == "?tutorial" and is_admin == true then
		if(server.getTutorial() == true) then
			server.announce("is tutorial", "true")
		else
			server.announce("is tutorial", "false")
		end
	end
	if command == "?nso" then 
		server.notify(user_peer_id, "NSO S&R Tutorial", "Active", 7)
	end
end
