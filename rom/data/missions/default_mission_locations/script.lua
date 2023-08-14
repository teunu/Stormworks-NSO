--[[
	location tags:
	small - 5x5 or 7x7 meters max
	medium - 20x20 meters max (small vehicles can spawn there too)
	large - 50x50 meters max (small and medium vehicles can spawn there too)
	underwater - spawn under the water (for ROVs, submarines, sunken vessels and air crashes)
	sea - spawn on the water in the sea (for any vessels or air crashes)
	river - spawn on the water on the river (for river themed boats only)
	shore - spawn on the shoreline (for vessels crashed into the land)
	offshore - spawn in the ocean tile (for vehicles to spawn away from any land tile)
	land - spawn on the land (for land vehicles or air crashes)
	road - spawn on the road (for land vehicles: cars, vans, buses, trucks)
	offroad - spawn off the road (for rolled over land vehicles)
	rocks - spawn at shallow rocks if have sea tag and mountains if have land tag
	forest - spawn somewhere in the deep of the woods (air crash or lost survivor for example)
	camp - spawn for camping themed vehicles (vans, RVs, tents)
	port - spawn for cargo vehicles (forklifts, loaders, trucks, semitrailers, fallen cranes)
	quarry - spawn for industry vehicles (bulldozers, excavators, dump trucks)
	alba - geo tag for main biome
	sawyer - geo tag for mainlaind biome
	arctic - geo tag for arctic biome (for Arctic themed vehicles only for example)

	capabilities:
	tow - for vehicles that can be towed to a destination
	repair - for vehicle sthat can be repaired
	transpoder
	flare
	scuttle
	refuel
	oil
--]]

g_savedata =
{
	spawn_counter = 60 * 30,
	id_counter = 0,
	missions = {},
	mission_frequency = property.slider("Mission Frequency (Mins)", 5, 120, 1, 60) * 60 * 60,
	mission_life_base = property.slider("Mission Base Time (Mins)", 30, 120, 1, 60) * 60 * 60,
	disasters = {},
	enable_disasters = property.checkbox("Natural Disaster Missions", true),
	display_timers = property.checkbox("Display Timers", false),
	display_rewards = property.checkbox("Display Reward", false),
	damage_tracker = {},
	oil_spills = {},
	enable_oil_spills = property.checkbox("Oil Spill Missions", true),
}
local g_zones = {}
local g_zones_hospital = {}
local g_output_log = {}
local g_objective_update_counter = 0
local map_update_cooldown = 0
local hospital_zones_update_cooldown = 0
local g_oil_spill_rate = 0.2

local oil_debug = false

g_objective_types =
{
	locate_zone =
	{
		update = function(self, mission, objective, delta_worldtime)
			local players = server.getPlayers()
			for player_index, player_object in pairs(players) do
				local distance_to_zone = matrix.distance(server.getPlayerPos(player_object.id), objective.transform)

				if distance_to_zone < 150 then
					g_mission_types[mission.type]:on_locate(mission, objective.transform)
					return true, true
				end
			end

			return false, false
		end,
	},
	locate_vehicle =
	{
		update = function(self, mission, objective, delta_worldtime)
			local players = server.getPlayers()
			for player_index, player_object in pairs(players) do
				local playerPos = server.getPlayerPos(player_object.id)
				local vehiclePos = server.getVehiclePos(objective.vehicle_id)
				local distance_to_zone = matrix.distance(playerPos, vehiclePos)

				if distance_to_zone < 200 then
					g_mission_types[mission.type]:on_locate(mission, vehiclePos)
					return true, true
				end
			end

			return false, false
		end,
	},
	rescue_casualty =
	{
		update = function(self, mission, objective, delta_worldtime)

			-- update hospital zones so we can track moving zones
			if hospital_zones_update_cooldown > 60 then
				hospital_zones_update_cooldown = 0
				g_zones_hospital = server.getZones("hospital")
			else
				hospital_zones_update_cooldown = hospital_zones_update_cooldown + 1
			end

			-- there is only one survivor per objective but iterate table to follow objective pattern
			for k, obj in pairs(objective.objects) do
				local c = server.getCharacterData(obj.id)
				if c then
					if c.dead then
						server.notify(-1, "Casualty Died", "A casualty is believed to have died.", 3)
						mission.data.survivor_dead_count = mission.data.survivor_dead_count + 1
						return true, true
					else
						local is_in_zone = isPosInZones(server.getObjectPos(obj.id), g_zones_hospital)

						if obj.is_bleed and c.hp > 0 then
							obj.bleed_counter = obj.bleed_counter + 60

							if obj.bleed_counter > 600 then
								if server.getGameSettings().npc_damage then
									obj.bleed_counter = 0
									c.hp = c.hp - 1
									server.setCharacterData(obj.id, c.hp, true, false)
								end
							end
						end

						if is_in_zone then
							if g_savedata.rescued_characters[obj.id] == nil then
								g_savedata.rescued_characters[obj.id] = 1
							end

							local reward = math.floor(objective.reward_value * (0.5 + (c.hp/200)))
							server.notify(-1, "Casualty Rescued", "A casualty has been successfully rescued to the hospital. Rewarded $"..math.floor(reward)..".", 4)
							server.setCurrency(server.getCurrency() + reward, server.getResearchPoints() + 1)
							return true, true
						end
					end
				end
			end

			return false, false
		end,
	},
	extinguish_fire =
	{
		update = function(self, mission, objective, delta_worldtime)
			local is_complete = true

			for k, fire in pairs(objective.objects) do
				local is_fire_on = server.getFireData(fire.id)

				if is_fire_on then
					is_complete = false
				end
			end

			if mission.data.vehicles ~= nil then
				for _, vehicle_object in pairs(mission.data.vehicles) do
					if server.getVehicleFireCount(vehicle_object.id) > 0 then
						is_complete = false
					end
				end
			end

			if is_complete then
				server.notify(-1, "Fire Extinguished", "Fire has been extinguished. Rewarded $"..math.floor(objective.reward_value)..".", 4)
				server.setCurrency(server.getCurrency() + objective.reward_value, server.getResearchPoints() + 1)
			end

			return is_complete, is_complete
		end,
	},
	repair_vehicle =
	{
		update = function(self, mission, objective, delta_worldtime)
			local is_complete = false

			if g_savedata.damage_tracker[objective.vehicle_id] ~= nil then
				if g_savedata.damage_tracker[objective.vehicle_id] < 1 then
					is_complete = true
				end
			elseif objective.damaged == false and server.getVehicleSimulating(objective.vehicle_id) then
				objective.damaged = true

				local data, success = server.getVehicleData(objective.vehicle_id)
				local found_signs = {}

				for i, sign in pairs(data.components.signs) do

					if string.find(sign.name, "faulty=") ~= nil then
						local t={}
						for str in string.gmatch(sign.name, "([^,]+)") do
								table.insert(t, str)
						end

						sign.damage = 10
						sign.radius = 1
						sign.flavor = "Repair some damage"

						for _, tag in pairs(t) do
							if string.find(tag, "faulty=") then sign.flavor = string.sub(tag, 8)
							elseif string.find(tag, "magnitude=") then sign.damage = tonumber(string.sub(tag, 11))
							elseif string.find(tag, "radius=") then sign.radius = tonumber(string.sub(tag, 8))
							end
						end

						table.insert(found_signs, sign)
					end
				end

				if #found_signs > 0 then
					if g_savedata.damage_tracker[objective.vehicle_id] == nil then
						local sign = found_signs[math.random(#found_signs)]
						g_savedata.damage_tracker[objective.vehicle_id] = 0
						mission.desc = mission.desc.."\n"..sign.flavor
						server.notify(-1, "Repair Objective", sign.flavor, 0)
						server.addDamage(objective.vehicle_id, sign.damage, sign.pos.x, sign.pos.y, sign.pos.z, sign.radius)
					end
				end

				if success == false or g_savedata.damage_tracker[objective.vehicle_id] == nil then server.announce("error", "no valid sign found, please screenshot the vehicle and report to the devs via the button in the pause menu") return true, true end

				return false, true
			end

			if is_complete then
				g_savedata.damage_tracker[objective.vehicle_id] = nil
				server.notify(-1, "Repair complete", "Full repair has been completed. Rewarded $"..math.floor(objective.reward_value)..".", 4)
				server.setCurrency(server.getCurrency() + objective.reward_value, server.getResearchPoints() + 1)
			elseif objective.damaged then
				local data, success = server.getVehicleData(objective.vehicle_id)
				if success == false then
					mission.data.package_destroyed = true
					return true, true
				end
			end

			return is_complete, false
		end,
	},
	transport_character =
	{
		update = function(self, mission, objective, delta_worldtime)
			-- there is only one survivor per objective but iterate table to follow objective pattern
			for k, obj in pairs(objective.objects) do
				local c = server.getCharacterData(obj.id)
				local is_in_zone = server.isInTransformArea(server.getObjectPos(obj.id), objective.destination.transform, objective.destination.size.x, objective.destination.size.y, objective.destination.size.z)

				if c then
					if c.dead then
						mission.data.survivor_dead_count = mission.data.survivor_dead_count + 1
					end

					if is_in_zone and (c.incapacitated == false) and (c.dead == false) then
						if g_savedata.rescued_characters[obj.id] == nil then
							g_savedata.rescued_characters[obj.id] = 1
						end

						local reward = math.floor(objective.reward_value * (0.2 + (c.hp/125)))
						server.notify(-1, "Delivery Complete", "The passenger has reached their destination. Rewarded $"..math.floor(reward)..".", 4)
						server.setCurrency(server.getCurrency() + reward, server.getResearchPoints() + 1)
						return true, true
					end
				end
			end
			return false, false
		end,
	},
	transport_vehicle =
	{
		update = function(self, mission, objective, delta_worldtime)
			local object_count = 0
			local object_delivered_count = 0
			local is_mission_ui_modified = false

			for k, obj in pairs(objective.objects) do
				object_count = object_count + 1

				if objective.destination.parent_vehicle_id ~= nil and objective.destination.parent_vehicle_id > 0 then
					objective.destination.transform = matrix.multiply(server.getVehiclePos(objective.destination.parent_vehicle_id), objective.destination.parent_relative_transform)
					mission.data.dest_transform = objective.destination.transform

					is_mission_ui_modified = true
				end

				local pos, success = server.getVehiclePos(obj.id)

				if success == false then
					mission.data.package_destroyed = true
					return true, true
				end

				local is_in_zone = server.isInTransformArea(pos, objective.destination.transform, objective.destination.size.x, objective.destination.size.y, objective.destination.size.z)

				if is_in_zone then
					object_delivered_count = object_delivered_count + 1
				end
			end

			if object_delivered_count == object_count then
				if objective.reward_value == nil then objective.reward_value = 2000 end
				server.notify(-1, "Delivery Complete", "The consignment has been delivered. Rewarded $"..math.floor(objective.reward_value)..".", 4)
				server.setCurrency(server.getCurrency() + objective.reward_value, server.getResearchPoints() + 1)
				return true, true
			else
				return false, is_mission_ui_modified
			end
		end,
	},
	transport_object =
	{
		update = function(self, mission, objective, delta_worldtime)
			local object_count = 0
			local object_delivered_count = 0

			for k, obj in pairs(objective.objects) do
				object_count = object_count + 1
				local is_in_zone = server.isInTransformArea(server.getObjectPos(obj.id), objective.destination.transform, objective.destination.size.x, objective.destination.size.y, objective.destination.size.z)

				if is_in_zone then
					object_delivered_count = object_delivered_count + 1
				end
			end

			if object_delivered_count == object_count then
				if objective.reward_value == nil then objective.reward_value = 2000 end
				server.notify(-1, "Delivery Complete", "The consignment has been delivered. Rewarded $"..math.floor(objective.reward_value)..".", 4)
				server.setCurrency(server.getCurrency() + objective.reward_value, server.getResearchPoints() + 1)
				return true, true
			else
				return false, false
			end
		end,
	},
	move_to_zones =
	{
		update = function(self, mission, objective, delta_worldtime)
			-- there is only one survivor per objective but iterate table to follow objective pattern
			for k, obj in pairs(objective.objects) do
				local c = server.getCharacterData(obj.id)
				if c then
					if c.dead then
						server.notify(-1, "Casualty Died", "A casualty is believed to have died.", 3)
						mission.data.survivor_dead_count = mission.data.survivor_dead_count + 1
						return true, true
					else
						local is_in_zone = isPosInZones(server.getObjectPos(obj.id), mission.data.safe_zones)

						if is_in_zone then
							if g_savedata.rescued_characters[obj.id] == nil then
								g_savedata.rescued_characters[obj.id] = 1
							end

							local reward = math.floor(objective.reward_value * (0.5 + (c.hp/200)))
							server.notify(-1, "Casualty Rescued", "A casualty has been successfully rescued to an safe zone. Rewarded $"..math.floor(reward)..".", 4)
							server.setCurrency(server.getCurrency() + reward, server.getResearchPoints() + 1)
							return true, true
						end
					end
				end
			end

			return false, false
		end,
	}
}

g_mission_types =
{
	crashed_vehicle =
	{
		valid_locations = {},

		build_valid_locations = function(self, playlist_index, location_index, parameters, mission_objects, location_data)
			local is_mission = parameters.type == "mission"

			if is_mission then
				if mission_objects.main_vehicle_component ~= nil and #mission_objects.survivors > 0 then
					debugLog("  found location")
					table.insert(self.valid_locations, { playlist_index = playlist_index, location_index = location_index, data = location_data, objects = mission_objects, parameters = parameters } )
				end
			end
		end,

		spawn = function(self, mission, location, difficulty_factor, override_transform, min_range, max_range)
			-- find zone
			local is_ocean_zone = false

			-- only spawn smaller vessels in early game
			if difficulty_factor < 0.5 and location.parameters.size == "size=large" then
				return false
			end
			if difficulty_factor < 0.15 and location.parameters.size == "size=medium" then
				return false
			end

            if location.parameters.vehicle_type == "vehicle_type=boat_ocean" then
                is_ocean_zone = true
            end
            if location.parameters.vehicle_state == "vehicle_state=crash_ocean" then
                is_ocean_zone = true
            end

			local zones = findSuitableZones(location.parameters, min_range, max_range, is_ocean_zone, override_transform)

			if #zones > 0 then
				-- select random suitable zone

				local zone_index = math.random(1, #zones)
				local zone = zones[zone_index]

				difficulty_factor = math.max(difficulty_factor, 0)

				local is_transponder = hasTag(location.parameters.capabilities, "transponder") and (math.random(1, 3) == 1)
				local is_flare = hasTag(location.parameters.capabilities, "flare") and (math.random(1, 2) == 1)
				local is_scuttle = hasTag(location.parameters.capabilities, "scuttle") and (math.random(1, 2) == 1)
				local search_radius = 4000 * (math.random(25, math.floor(50 + (difficulty_factor*50))) / 100)
				local is_locate = math.random(1, 2) == 1 or is_transponder
				local is_predator = server.dlcArid() and math.random(1, 2) == 1
				local is_oil_spill = g_savedata.enable_oil_spills and hasTag(location.parameters.capabilities, "oil")

				-- spawn objects from selected location using zone's world transform
				local spawn_transform = matrix.multiply(zone.transform, matrix.translation(0, -zone.size.y * 0.5, 0))
				if is_spawn_location_clear(spawn_transform, zone.size) == false then return false end

				local all_mission_objects = {}
				local spawned_objects = {
					vehicles = spawnObjects(spawn_transform, location, location.objects.vehicles, all_mission_objects, 1, 0, 10),
					survivors = spawnObjects(spawn_transform, location, location.objects.survivors, all_mission_objects, 3, 1, 4+(difficulty_factor*30)),
					fires = spawnObjects(spawn_transform, location, location.objects.fires, all_mission_objects, 2, 0, 2+(difficulty_factor*8)),
					objects = spawnObjects(spawn_transform, location, location.objects.objects, all_mission_objects, 3, 0, 10)
				}
				local main_vehicle = nil
				for _, vehicle in pairs(spawned_objects.vehicles) do
					if vehicle.component_id == location.objects.main_vehicle_component.id then
						main_vehicle = vehicle
					end
				end

				if main_vehicle == nil or tableLength(spawned_objects.survivors) == 0 then
					debugLog("ERROR no vehicles or characters spawned")
					despawnObjects(all_mission_objects, true)
					return false
				end

				local is_repair = hasTag(location.parameters.capabilities, "repair") and #spawned_objects.fires == 0 and (math.random(1, 2) == 1)

				mission.spawned_objects = all_mission_objects
				mission.data = spawned_objects
				mission.data.vehicle_main = main_vehicle

				for survivor_index, survivor_object in pairs(mission.data.survivors) do
					local is_survivor_injured = server.getGameSettings().npc_damage and math.random(1, 3) == 1

					if is_survivor_injured then
						local survivor_health = math.random(60, 90)
						server.setCharacterData(survivor_object.id, survivor_health, true, false)
					end

					survivor_object.bleed_counter = 0
					survivor_object.is_bleed = is_survivor_injured

					if is_ocean_zone and (difficulty_factor < 0.5 or math.random(1, 3) == 1) then
						server.setCharacterItem(survivor_object.id, 2, 23, true, 1, 0)
					end
				end

				local incoming_disaster = getIncomingDisaster(spawn_transform)

				mission.desc = is_locate and "Search the area and locate the emergency." or ""

				if is_repair then
					table.insert(mission.objectives, createObjectiveRepairVehicle(main_vehicle.id))
				end

				-- activate transponder
				if is_transponder then
					search_radius = 4000 * (math.random(35, math.floor(75+(difficulty_factor*325))) / 100)

					mission.desc = mission.desc.." The vehicle has activated its transponder. Use a transponder locator to hone-in on the signal. "

					server.setVehicleTransponder(mission.data.vehicle_main.id, true)
				end

				addMission(mission)
				debugLog("adding mission with id " .. mission.id .. "...")

				local is_static = server.getVehicleData(main_vehicle.id).static

				local titles = {
					" has an emergency",
					" in distress is requesting assistance",
					is_locate and (is_static and " is experiencing mechanical failure" or " has gone missing") or " radioed for help",
				}
				mission.title = location.objects.display_name..titles[math.random(1, #titles)]

				if location.parameters.theme == "theme=underwater" then
					mission.title = mission.title.." "..(math.floor(spawn_transform[14]/10)*-10).."m underwater"
				end

				mission.data.life = g_savedata.mission_life_base
				mission.data.zone = zone
				mission.data.zone_transform = spawn_transform
				mission.data.zone_radius = search_radius
				mission.data.survivor_dead_count = 0
				local radius_offset = mission.data.zone_radius * (math.random(20, 90) / 100)
				local angle = math.random(0,100) / 100 * 2 * math.pi
				local spawn_transform_x, spawn_transform_y, spawn_transform_z = matrix.position(spawn_transform)
				mission.data.zone_x = spawn_transform_x + radius_offset * math.cos(angle)
				mission.data.zone_z = spawn_transform_z + radius_offset * math.sin(angle)
				mission.data.is_fire = #spawned_objects.fires > 0
				mission.data.is_transponder = is_transponder
				mission.data.is_flare = is_flare
				mission.data.is_repair = is_repair
				mission.data.is_predator = is_predator
				mission.data.is_oil_spill = is_oil_spill
				mission.data.flare_timer = 60 * 30
				mission.data.is_scuttle = is_scuttle
				mission.data.incoming_disaster = incoming_disaster
				mission.data.reward = (tableLength(mission.data.survivors) * 2000) + ((#location.objects.fires > 0) and 3000 or 0)

				-- Natural disasters
				spawnDisaster(mission.data)

				-- Predators
				if is_predator then
					local x = zone.transform[13] - (zone.size.x) + (2 * zone.size.x * math.random())
					local y = zone.transform[14] + 2
					local z = zone.transform[15] - (zone.size.z) + (2 * zone.size.z * math.random())
					local transform = matrix.translation(x, y, z)
					local scale = 0.75 + (math.random() * 0.25)

					if location.parameters.theme == "theme=camp" or location.parameters.theme == "theme=forest" then
						if hasTag(zone.tags, "biome=arid") then
							server.spawnCreature(transform, 100, scale)
							mission.desc = mission.desc.." A mountain lion was spotted nearby, exercise extreme caution."
						else
							server.spawnCreature(transform, 1, scale)
							mission.desc = mission.desc.." A grizzly bear was spotted nearby, exercise extreme caution."
						end
					elseif hasTag(zone.tags, "biome=arctic") then
							server.spawnCreature(transform, 3, scale)
							mission.desc = mission.desc.." A polar bear was spotted nearby, exercise extreme caution."
					else
						mission.data.is_predator = false
					end
				end

				if is_oil_spill then
					mission.data.oil = 250.0
					if location.parameters.size == "size=large" then
						mission.data.oil = 1000.0
					elseif location.parameters.size == "size=medium" then
						mission.data.oil = 500.0
					end
					mission.desc = mission.desc.." Oil is leaking on site, a cleanup operation may be required."
				end

				if is_locate then
					mission.data.state = "locate zone"
					table.insert(mission.objectives, createObjectiveLocateVehicle(mission.data.vehicle_main.id))

					if is_transponder then
						server.notify(-1, "New Mission",  mission.title.." and have activated their transponder.", 0)
					else
						server.notify(-1, "New Mission",  mission.title.." without an exact known location.", 0)
					end
				else
					mission.data.state = "rescue"
					self:spawn_location_objectives(mission)
				end

				if tableLength(spawned_objects.survivors) > 0 then
					server.command("?ai_summon_hospital_ship "..mission.data.zone_x.." "..mission.data.zone_z)
				end

				return true
			end

			return false
		end,

		update = function(self, mission)
			local imporant_loaded_prev = mission.is_important_loaded
			mission.is_important_loaded = server.getVehicleSimulating(mission.data.vehicle_main.id)
			for survivor_id, survivor_object in pairs(mission.data.survivors) do
				if server.getObjectSimulating(survivor_object.id) then
					mission.is_important_loaded = true
				end
			end

			if mission.is_important_loaded == true and imporant_loaded_prev == false then
				server.setAudioMood(-1, 4)
			end

			if mission.data.is_oil_spill then
				if mission.data.oil > g_oil_spill_rate then
					mission.data.oil = mission.data.oil - g_oil_spill_rate
					current_oil = server.getOilSpill(mission.data.zone_transform)
					server.setOilSpill(mission.data.zone_transform, current_oil + g_oil_spill_rate)
				end
			end
		end,

		tick = function(self, mission, delta_worldtime)
			if mission.data.life > 0 then
				if mission.is_important_loaded == false then mission.data.life = mission.data.life - delta_worldtime end

				-- consider launching vehicle flare if flare is set, vehicle is loaded, and timer has timed down
				if mission.data.is_flare then
					if server.getVehicleSimulating(mission.data.vehicle_main.id) then
						if mission.data.flare_timer <= 0 then
							server.pressVehicleButton(mission.data.vehicle_main.id, "mission_flare")
							mission.data.is_flare = false
						else
							mission.data.flare_timer = mission.data.flare_timer - delta_worldtime
						end
					end
				end
			else
				-- remove objectives to force mission to end
				mission.objectives = {}
			end
		end,

		on_vehicle_load = function(self, mission, vehicle_id)
			if mission.data.is_transponder then
				if mission.data.vehicle_main.id == vehicle_id then
					server.pressVehicleButton(mission.data.vehicle_main.id, "mission_transponder_on")
				end
			end
		end,

		on_locate = function(self, mission, transform)
			mission.data.state = "rescue"

			if mission.data.is_transponder then
				server.setVehicleTransponder(mission.data.vehicle_main.id, false)
				server.pressVehicleButton(mission.data.vehicle_main.id, "mission_transponder_off")
			end

			self:spawn_location_objectives(mission)
		end,

		rebuild_ui = function(self, mission)
			if mission.data.state == "rescue" then
				local marker_x, marker_y, marker_z = matrix.position(mission.data.zone_transform)
				addMarker(mission, createMarker(marker_x, marker_z, mission.title..(g_savedata.display_rewards and ("\n+$"..math.floor(mission.data.reward)) or "")..(g_savedata.display_timers and ("\n"..math.floor(mission.data.life/3600).."min") or ""), mission.desc, 0, 1))
			else
				addMarker(mission, createMarker(mission.data.zone_x, mission.data.zone_z, mission.title..(g_savedata.display_rewards and ("\n+$"..math.floor(mission.data.reward)) or "")..(g_savedata.display_timers and ("\n"..math.floor(mission.data.life/3600).."min") or ""), mission.desc, mission.data.zone_radius, 8))
			end
		end,

		terminate = function(self, mission)
			if mission.data.life <= 0 then
				server.notify(-1, "Mission Expired",  "Another rescue service completed this mission.", 2)
			elseif mission.data.survivor_dead_count == 0 then
				server.notify(-1, "Mission Complete",  mission.desc, 4)
			else
				server.notify(-1, "Mission Ended",  "All unaccounted survivors are believed to have died.", 3)
			end
		end,

		spawn_location_objectives = function(self, mission)
			-- rescue survivors
			local survivor_count = 0
			local survivor_dead_count = 0
			for survivor_id, survivor_object in pairs(mission.data.survivors) do
				local c = server.getCharacterData(survivor_object.id)
				if c then
					if c.dead then
						survivor_dead_count = survivor_dead_count + 1
						mission.data.survivor_dead_count = mission.data.survivor_dead_count + 1
					else
						survivor_count = survivor_count + 1
						table.insert(mission.objectives, createObjectiveRescueCasualty(survivor_object))
					end
				end
			end

			-- extinguish fires
            local fire_count = 0
            if mission.data.is_fire then
                for fire_id, fire_object in pairs(mission.data.fires) do
                    fire_count = fire_count + 1
                end

                table.insert(mission.objectives, createObjectiveExtinguishFire(mission.data.fires))
            end

			if survivor_count > 0 and fire_count > 0 then
				mission.desc = "Extinguish all fires and rescue "..math.floor(survivor_count).." casualt"..(survivor_count > 1 and "ies " or "y ")..mission.data.zone.name.." to a hospital."
				server.notify(-1, "Casualties and Fire", mission.desc, 0)
			elseif survivor_count > 0 then
				mission.desc = "Rescue "..math.floor(survivor_count).." casualt"..(survivor_count > 1 and "ies " or "y ")..mission.data.zone.name.." to a hospital."
				server.notify(-1, "Casualties", mission.desc, 0)
			elseif fire_count > 0 then
				mission.desc = "Extinguish all fires "..mission.data.zone.name.."."
				server.notify(-1, "Fire", mission.desc, 0)
			end

			if mission.data.is_repair then
				mission.desc = mission.desc.." Repair critical damage to the vehicle to prevent the emergency from escalating. "
			end

			if mission.data.is_predator then
				if hasTag(mission.data.zone.tags, "biome=arctic") then
					mission.desc = mission.desc.." A polar bear was spotted nearby, exercise extreme caution."
				elseif hasTag(mission.data.zone.tags, "biome=arid") then
					mission.desc = mission.desc.." A mountain lion was spotted nearby, exercise extreme caution."
				else
					mission.desc = mission.desc.." A grizzly bear was spotted nearby, exercise extreme caution."
				end
			end

			server.setAudioMood(-1, 4)

			removeMissionMarkers(mission)
			self:rebuild_ui(mission)
		end,
	},

	transport =
	{
		valid_locations = {},

		build_valid_locations = function(self, playlist_index, location_index, parameters, mission_objects, location_data)
			local is_mission = parameters.type == "mission_transport"

			if is_mission then
				if #mission_objects.vehicles > 0 or #mission_objects.survivors > 0 or #mission_objects.objects > 0 then
					debugLog("  found location")
					table.insert(self.valid_locations, { playlist_index = playlist_index, location_index = location_index, data = location_data, objects = mission_objects, parameters = parameters } )
				end
			end
		end,

		spawn = function(self, mission, location, difficulty_factor, override_transform, min_range, max_range)
			-- find zone

			local is_ocean_zone = false
			if location.parameters.source_zone_type == "ocean" then
				is_ocean_zone = true
			end
			local source_parameters = {
				type = location.parameters.type,
				size = location.parameters.size,
				theme = location.parameters.theme,
				vehicle_type =  location.parameters.vehicle_type,
				source_zone_type = location.parameters.source_zone_type
			}

			local source_zones = findSuitableZones(source_parameters, min_range, max_range, is_ocean_zone, override_transform)

			local is_dest_ocean_zone = false
			if location.parameters.destination_zone_type == "ocean" then
				is_dest_ocean_zone = true
			end
			local dest_parameters = {
				destination_zone_type = location.parameters.destination_zone_type
			}
			local destination_zones = findSuitableZones(dest_parameters, min_range, max_range, is_dest_ocean_zone, override_transform)

			if #source_zones > 0 and #destination_zones > 0 then
				-- select random suitable zone

				local source_zone_index = math.random(1, #source_zones)
				local source_zone = source_zones[source_zone_index]

				local destination_zone_index = math.random(1, #destination_zones)
				local destination_zone = destination_zones[destination_zone_index]

				-- spawn objects from selected location using zone's world transform
				local spawn_transform = matrix.multiply(source_zone.transform, matrix.translation(0, -source_zone.size.y * 0.5, 0))
				if is_spawn_location_clear(spawn_transform, source_zone.size) == false then return false end

				local all_mission_objects = {}
				local spawned_objects = {
					vehicles = spawnObjects(spawn_transform, location, location.objects.vehicles, all_mission_objects, 3, 0, 10),
					survivors = spawnObjects(spawn_transform, location, location.objects.survivors, all_mission_objects, 3, 1, 4+(difficulty_factor*30)),
					objects = spawnObjects(spawn_transform, location, location.objects.objects, all_mission_objects, 3, 0, 10)
				}
				local main_vehicle = nil
				for _, vehicle in pairs(spawned_objects.vehicles) do
					if vehicle.component_id == location.objects.main_vehicle_component.id then
						main_vehicle = vehicle
					end
				end

				if #spawned_objects.vehicles == 0 and #spawned_objects.survivors == 0 and #spawned_objects.objects == 0 then
					debugLog("ERROR no vehicles or characters or objects spawned")
					despawnObjects(all_mission_objects, true)
					return false
				end

				mission.spawned_objects = all_mission_objects
				mission.data = spawned_objects
				mission.data.vehicle_main = main_vehicle
				mission.data.life = g_savedata.mission_life_base * 8
				mission.data.zone = source_zone
				mission.data.zone_transform = spawn_transform
				mission.data.dest_transform = destination_zone.transform
				mission.data.state = "transport"
				mission.data.survivor_dead_count = 0

				local transport_distance = matrix.distance(spawn_transform, destination_zone.transform)
				local reward = 1000 + (math.ceil(transport_distance * (math.random(1, 4)/20)/100)*100)
				mission.data.reward = 0

				local vehicle_count = 0
				for _, vehicle_object in pairs(mission.data.vehicles) do
					vehicle_count = vehicle_count + 1
					table.insert(mission.objectives, createObjectiveTransportVehicle(vehicle_object, destination_zone, reward))
					mission.data.reward = mission.data.reward + reward
				end

				local survivor_count = 0
				for _, survivor_object in pairs(mission.data.survivors) do
					survivor_count = survivor_count + 1
					table.insert(mission.objectives, createObjectiveTransportCharacter(survivor_object, destination_zone, 0.75 * reward))
					mission.data.reward = mission.data.reward + (0.75 * reward)
				end

				local object_count = 0
				for _, object_object in pairs(mission.data.objects) do
					object_count = object_count + 1
					table.insert(mission.objectives, createObjectiveTransportObject(object_object, destination_zone, 0.5 * reward))
					mission.data.reward = mission.data.reward + (0.5 * reward)
				end

				mission.title = (is_ocean_zone and "Recover " or "Transport ")..(survivor_count > 0 and survivor_count.." " or "")
				mission.title = mission.title..location.objects.display_name..(survivor_count > 1 and "s" or "")
				if location.parameters.theme == "theme=underwater" then
					mission.title = mission.title.." "..(math.floor(spawn_transform[14]/10)*-10).."m underwater"
				end

				mission.desc = mission.title
				if survivor_count > 0 then
					if vehicle_count > 0 then mission.desc = mission.desc.." and their vehicle" end
					if object_count > 0 then mission.desc = mission.desc.." and their cargo" end
				end
				mission.desc = mission.desc.." to "..destination_zone.name

				mission.data.icon = (survivor_count > 0) and 1 or 2

				addMission(mission)
				debugLog("adding mission with id " .. mission.id .. "...")

				server.notify(-1, "New Mission",  mission.title, 0)

				return true
			end

			debugLog("Could not find any zones s:" .. #source_zones .. " d:" .. #destination_zones)

			return false
		end,

		update = function(self, mission)
			local imporant_loaded_prev = mission.is_important_loaded
			mission.is_important_loaded = false
			if mission.data.vehicle_main ~= nil then
				if server.getVehicleSimulating(mission.data.vehicle_main.id) then
					mission.is_important_loaded = true
				end
			end
			for survivor_id, survivor_object in pairs(mission.data.survivors) do
				if server.getObjectSimulating(survivor_object.id) then
					mission.is_important_loaded = true
				end
			end
			for _, crate in pairs(mission.data.objects) do
				if server.getObjectSimulating(crate.id) then
					mission.is_important_loaded = true
				end
			end

			if mission.is_important_loaded == true and imporant_loaded_prev == false then
				server.setAudioMood(-1, 3)
			end
		end,

		tick = function(self, mission, delta_worldtime)
			if mission.data.survivor_dead_count > 0 then
				-- a survivor has died end the mission immediately
				mission.objectives = {}
			end

			if mission.data.life > 0 then
				if mission.is_important_loaded == false then mission.data.life = mission.data.life - delta_worldtime end
			else
				-- remove objectives to force mission to end
				mission.objectives = {}
			end
		end,

		on_vehicle_load = function(self, mission, vehicle_id)
		end,

		on_locate = function(self, mission, transform)
		end,

		rebuild_ui = function(self, mission)
			if mission.data.state == "transport" then
				local marker_x, marker_y, marker_z = matrix.position(mission.data.zone_transform)
				addMarker(mission, createMarker(marker_x, marker_z, mission.title..(g_savedata.display_rewards and ("\n+$"..math.floor(mission.data.reward)) or "")..(g_savedata.display_timers and ("\n"..math.floor(mission.data.life/3600).."min") or ""), mission.desc, 0, mission.data.icon), 255, 109, 40, 255)
				local marker_x, marker_y, marker_z = matrix.position(mission.data.dest_transform)
				addMarker(mission, createMarker(marker_x, marker_z, "Destination", "", 0, 0), 255, 109, 40, 255)

				addLineMarker(mission, createLineMarker(mission.data.zone_transform, mission.data.dest_transform, 0.6), 255, 109, 40, 255)
			end
		end,

		terminate = function(self, mission)
			if mission.data.life <= 0 then
				server.notify(-1, "Mission Expired",  "Another rescue service completed this mission.", 2)
			elseif mission.data.survivor_dead_count > 0 then
				server.notify(-1, "Mission Failed",  "A passenger has died during transport. This is unacceptable.", 3)
			elseif mission.data.package_destroyed then
				server.notify(-1, "Mission Failed", "The mission target was destroyed.", 3)
			else
				server.notify(-1, "Mission Complete",  mission.desc, 4)
			end
		end,
	},

	evacuate =
	{
		valid_locations = {},

		build_valid_locations = function(self, playlist_index, location_index, parameters, mission_objects, location_data)
			local is_mission = parameters.type == "mission_transport"

			if is_mission then
				if #mission_objects.survivors > 0 then
					debugLog("  found location")
					table.insert(self.valid_locations, { playlist_index = playlist_index, location_index = location_index, data = location_data, objects = mission_objects, parameters = parameters } )
				end
			end
		end,

		spawn = function(self, mission, location, difficulty_factor, override_transform, min_range, max_range)
			-- find zone

			if override_transform == nil then
				return false
			end

			local parameters = {
				is_evacuate = true
			}
			local zones = findSuitableZones(parameters, min_range, max_range, false, override_transform)

			local safe_zones = {}
			local danger_zones = {}

			for _, z in pairs(zones) do
				local dist = matrix.distance(z.transform, override_transform)
				if dist > 4000 then
					table.insert(safe_zones, z)
				else
					z.survivor_count = 0
					table.insert(danger_zones, z)
				end
			end

			if #safe_zones > 0 and #danger_zones > 0 then

				mission.data.safe_zones = safe_zones
				mission.data.danger_zones = danger_zones

				local all_mission_objects = {}
				local survivor_count = 0

				for _, z in pairs(danger_zones) do
					-- spawn objects from selected location using zone's world transform
					local spawn_transform = matrix.multiply(z.transform, matrix.translation(0, -z.size.y * 0.5, 0))

					local spawned_objects = {
						survivors = spawnObjects(spawn_transform, location, location.objects.survivors, all_mission_objects, 3, 0, 4+(difficulty_factor*30)),
					}

					for _, survivor_object in pairs(spawned_objects.survivors) do
						survivor_count = survivor_count + 1
						z.survivor_count = z.survivor_count + 1
						table.insert(mission.objectives, createObjectiveMoveToZones(survivor_object))
					end
				end

				if #all_mission_objects == 0 then
					debugLog("ERROR no characters spawned")
					despawnObjects(all_mission_objects, true)
					return false
				end

				-- add mission
				addMission(mission)

				-- initialise mission data
				debugLog("adding mission with id " .. mission.id .. "...")

				-- add objectives to the mission
				mission.data.life = g_savedata.mission_life_base
				mission.data.zone_transform = override_transform
				mission.data.survivor_dead_count = 0
				mission.spawned_objects = all_mission_objects
				mission.data.survivors = all_mission_objects

				-- set title and description
				mission.title = "Evacuate Civillians"
				mission.desc = survivor_count.." civillians need evacuating to a safe zone in anticipation of a natural disaster"

				server.notify(-1, "New Mission",  mission.title, 0)

				return true
			end

			return false
		end,

		update = function(self, mission)
			local imporant_loaded_prev = mission.is_important_loaded
			mission.is_important_loaded = false
			for survivor_id, survivor_object in pairs(mission.data.survivors) do
				if server.getObjectSimulating(survivor_object.id) then
					mission.is_important_loaded = true
				end
			end

			if mission.is_important_loaded == true and imporant_loaded_prev == false then
				server.setAudioMood(-1, 4)
			end
		end,

		tick = function(self, mission, delta_worldtime)
			if mission.data.life > 0 then
				if mission.is_important_loaded == false then mission.data.life = mission.data.life - delta_worldtime end
			else
				-- remove objectives to force mission to end
				mission.objectives = {}
			end
		end,

		on_vehicle_load = function(self, mission, vehicle_id)
		end,

		on_locate = function(self, mission, transform)
		end,

		rebuild_ui = function(self, mission)
			local remaining_survivors = #mission.data.survivors-mission.data.survivor_dead_count

			for _, z in pairs(mission.data.danger_zones) do
				if z.survivor_count > 0  then
					local marker_x, marker_y, marker_z = matrix.position(z.transform)
					addMarker(mission, createMarker(marker_x, marker_z, z.survivor_count.." civillians need evacuating to a safe zone in anticipation of a natural disaster", "", 0, 1), 255, 0, 0, 125)
				end
			end

			for _, z in pairs(mission.data.safe_zones) do
				local marker_x, marker_y, marker_z = matrix.position(z.transform)
				addMarker(mission, createMarker(marker_x, marker_z, "Safe Zone", "", 0, 11), 0, 255, 0, 125)
			end
		end,

		terminate = function(self, mission)
			if mission.data.life <= 0 then
				server.notify(-1, "Mission Expired",  "Another rescue service managed to get the civillians to safety.", 2)
			else
				server.notify(-1, "Mission Complete",  mission.desc, 4)
			end
		end,
	},

	tow_vehicle =
	{
		valid_locations = {},

		build_valid_locations = function(self, playlist_index, location_index, parameters, mission_objects, location_data)
			local is_mission = false
			for _, capability in pairs(parameters.capabilities) do
				if capability == "tow" or capability == "repair" or capability == "refuel" then is_mission = true end
			end

			if is_mission then
				if mission_objects.main_vehicle_component ~= nil then
					debugLog("  found location")
					table.insert(self.valid_locations, { playlist_index = playlist_index, location_index = location_index, data = location_data, objects = mission_objects, parameters = parameters } )
				end
			end
		end,

		spawn = function(self, mission, location, difficulty_factor, override_transform, min_range, max_range)

			-- only spawn smaller vessels in early game
			if difficulty_factor < 0.5 and location.parameters.size == "size=large" then
				return false
			end
			if difficulty_factor < 0.15 and location.parameters.size == "size=medium" then
				return false
			end

			local is_tow, is_repair, is_refuel, is_oil_spill = false, false, false, false
			for _, capability in pairs(location.parameters.capabilities) do
				if capability == "tow" and math.random(1, 2) == 1 then is_tow = true end
				if capability == "repair" and math.random(1, 2) == 1 then is_repair = true end
				if capability == "refuel" and math.random(1, 2) == 1 then is_refuel = true end
				if capability == "oil" and g_savedata.enable_oil_spills then is_oil_spill = true end
			end

			if is_tow == false and is_repair == false and is_refuel == false then
				if hasTag(location.parameters.capabilities, "tow") then
					is_tow = true
				else
					return false
				end
			end

            local is_ocean_zone = false
            if location.parameters.vehicle_type == "vehicle_type=boat_ocean"
			or location.parameters.vehicle_type == "vehicle_type=machine_ocean" then
                is_ocean_zone = true
            end

			local source_zones = findSuitableZones(location.parameters, min_range, max_range, is_ocean_zone, override_transform)

			local target_destination_zone_type = "destination_parking"
			if location.parameters.vehicle_type == "vehicle_type=boat_ocean"
			or location.parameters.vehicle_type == "vehicle_type=boat_river" then
				target_destination_zone_type = "destination_dock"
			end
			local dest_parameters = {
				destination_zone_type = target_destination_zone_type
			}
			local destination_zones = findSuitableZones(dest_parameters, min_range, max_range, false, override_transform)

			if #source_zones > 0 and (is_tow == false or #destination_zones > 0) then

				local source_zone_index = math.random(1, #source_zones)
				local source_zone = source_zones[source_zone_index]

				local destination_zone = nil
				if is_tow then
					local destination_zone_index = math.random(1, #destination_zones)
					destination_zone = destination_zones[destination_zone_index]
				end

				local spawn_transform = matrix.multiply(source_zone.transform, matrix.translation(0, -source_zone.size.y * 0.5, 0))
				if is_spawn_location_clear(spawn_transform, source_zone.size) == false then return false end

				local all_mission_objects = {}
				local spawned_objects = {
					vehicles = spawnObjects(spawn_transform, location, location.objects.vehicles, all_mission_objects, 1, 0, 10)
				}

				local main_vehicle = nil
				for _, vehicle in pairs(spawned_objects.vehicles) do
					if vehicle.component_id == location.objects.main_vehicle_component.id then
						main_vehicle = vehicle
					end
				end

				if #spawned_objects.vehicles < 1 then
					debugLog("ERROR no vehicle spawned")
					despawnObjects(all_mission_objects, true)
					return false
				end

				local incoming_disaster = getIncomingDisaster(spawn_transform)

				if location.parameters.theme == "theme=underwater" then
					source_zone.name = (math.floor(spawn_transform[14]/10)*-10).."m underwater "..source_zone.name
				end

				mission.spawned_objects = all_mission_objects
				mission.data = spawned_objects
				mission.data.vehicle_main = main_vehicle
				mission.title = location.objects.display_name.." requires servicing "..source_zone.name
				mission.desc = ""
				mission.data.life = g_savedata.mission_life_base * 8
				mission.data.source_zone = source_zone
				mission.data.zone_transform = spawn_transform
				mission.data.incoming_disaster = incoming_disaster
				mission.data.icon = 2
				mission.data.is_oil_spill = is_oil_spill

				if location.parameters.vehicle_type == "vehicle_type=boat_ocean" or location.parameters.vehicle_type == "vehicle_type=boat_river" then mission.data.icon = 16
				elseif location.parameters.vehicle_type == "vehicle_type=helicopter" then mission.data.icon = 15
				elseif location.parameters.vehicle_type == "vehicle_type=plane" or location.parameters.vehicle_type == "vehicle_type=plane_ocean"  then mission.data.icon = 13
				elseif location.parameters.vehicle_type == "vehicle_type=car" then mission.data.icon = 12
				elseif location.parameters.vehicle_type == "vehicle_type=tent" then mission.data.icon = 11
				elseif location.parameters.vehicle_type == "vehicle_type=machine_ocean" then mission.data.icon = 2
				end

				addMission(mission)
				debugLog("adding mission with id " .. mission.id .. "...")

				if is_tow then
					if is_repair then mission.desc = mission.desc .. "Repair and " end
					mission.desc = mission.desc .. "Transport "..location.objects.display_name.." "..source_zone.name.." to "..destination_zone.name

					mission.data.dest_transform = destination_zone.transform
					local transport_distance = matrix.distance(spawn_transform, destination_zone.transform)
					local reward = 1000 + (math.ceil(transport_distance * (math.random(3, 5)/20)/100)*100)
					mission.data.reward = reward

					table.insert(mission.objectives, createObjectiveTransportVehicle(main_vehicle, destination_zone, reward))
				elseif is_repair then
					mission.desc = "Conduct repairs on "..location.objects.display_name.." "..source_zone.name
					mission.data.reward = 2000
					table.insert(mission.objectives, createObjectiveRepairVehicle(main_vehicle.id))
				end

				if is_oil_spill then
					mission.data.oil = 400.0
					if location.parameters.size == "size=large" then
						mission.data.oil = 1000.0
					elseif location.parameters.size == "size=medium" then
						mission.data.oil = 700.0
					end
					mission.desc = mission.desc .. " The report indicates an oil leak at the site that could become an environmental disaster."
				end

				spawnDisaster(mission.data)

				server.notify(-1, "New Mission",  mission.title, 0)

				return true
			end

			return false
		end,

		update = function(self, mission)
			local imporant_loaded_prev = mission.is_important_loaded
			if mission.data.vehicle_main ~= nil then
				mission.is_important_loaded = server.getVehicleSimulating(mission.data.vehicle_main.id)
			else
				mission.is_important_loaded = false
			end

			if mission.is_important_loaded == true and imporant_loaded_prev == false then
				server.setAudioMood(-1, 3)
			end

			if mission.data.is_oil_spill then
				if mission.data.oil > g_oil_spill_rate then
					mission.data.oil = mission.data.oil - g_oil_spill_rate
					current_oil = server.getOilSpill(mission.data.zone_transform)
					server.setOilSpill(mission.data.zone_transform, current_oil + g_oil_spill_rate)
				end
			end
		end,

		tick = function(self, mission, delta_worldtime)
			if mission.data.life > 0 then
				if mission.is_important_loaded == false then mission.data.life = mission.data.life - delta_worldtime end
			else
				-- remove objectives to force mission to end
				mission.objectives = {}
			end
		end,

		on_vehicle_load = function(self, mission, vehicle_id)
		end,

		on_locate = function(self, mission, transform)
		end,

		rebuild_ui = function(self, mission)
			local vehicle_pos = server.getVehiclePos(mission.data.vehicle_main.id)
			local vehicle_x, vehicle_y, vehicle_z = matrix.position(vehicle_pos)
			addMarker(mission, createMarker(vehicle_x, vehicle_z, mission.title..(g_savedata.display_rewards and ("\n+$"..math.floor(mission.data.reward)) or "")..(g_savedata.display_timers and ("\n"..math.floor(mission.data.life/3600).."min") or ""), mission.desc, 0, mission.data.icon), 255, 109, 40, 255)

			if mission.data.dest_transform ~= nil then
				local marker_x, marker_y, marker_z = matrix.position(mission.data.dest_transform)
				addMarker(mission, createMarker(marker_x, marker_z, "Destination", "", 0, 0), 255, 109, 40, 255)

				addLineMarker(mission, createLineMarker(vehicle_pos, mission.data.dest_transform, 0.6), 255, 109, 40, 255)
			end
		end,

		terminate = function(self, mission)
			if mission.data.life <= 0 then
				server.notify(-1, "Mission Expired",  "Another rescue service completed this mission.", 2)
			elseif mission.data.package_destroyed then
				server.notify(-1, "Mission Failed", "The mission target was destroyed.", 3)
			else
				server.notify(-1, "Mission Complete",  mission.desc, 4)
			end
		end,
	},

	building =
	{
		valid_locations = {},

		build_valid_locations = function(self, playlist_index, location_index, parameters, mission_objects, location_data)
			local is_mission = parameters.type == "mission_building"

			if is_mission then
				if #mission_objects.fires > 0 and #mission_objects.survivors > 0 then
					debugLog("  found location building")
					table.insert(self.valid_locations, { playlist_index = playlist_index, location_index = location_index, data = location_data, objects = mission_objects, parameters = parameters } )
				end
			end
		end,

		spawn = function(self, mission, location, difficulty_factor, override_transform, min_range, max_range)

			local spawn_transform = nil

			-- filter range
			local is_in_range = false

			local players = server.getPlayers()

			for player_index, player_object in pairs(players) do
				local tile_transform, success = server.getTileTransform((server.getPlayerPos(player_object.id)), location.data.tile)
				local distance_to_zone = matrix.distance(tile_transform, (server.getPlayerPos(player_object.id)))

				if success and distance_to_zone > min_range and distance_to_zone < max_range then
					is_in_range = true
					spawn_transform = tile_transform
				end
			end

			if is_in_range then

				local all_mission_objects = {}
				local spawned_objects = {
					survivors = spawnObjects(spawn_transform, location, location.objects.survivors, all_mission_objects, 2, 0, 4+(difficulty_factor*30)),
					fires = spawnObjects(spawn_transform, location, location.objects.fires, all_mission_objects, 1, 0, 10),
					objects = spawnObjects(spawn_transform, location, location.objects.objects, all_mission_objects, 3, 0, 10)
				}

				mission.spawned_objects = all_mission_objects
				mission.data = spawned_objects
				mission.data.vehicle_main = nil

				local survivor_count = 0
				for survivor_index, survivor_object in pairs(mission.data.survivors) do
					local is_survivor_injured = server.getGameSettings().npc_damage and math.random(1, 3) == 1

					local c = server.getCharacterData(survivor_object.id)

					if is_survivor_injured and c.interactable then
						local survivor_health = math.random(60, 90)
						server.setCharacterData(survivor_object.id, survivor_health, true, false)
					end

					if c.interactable then
						survivor_count = survivor_count + 1
					end

					survivor_object.bleed_counter = 0
					survivor_object.is_bleed = is_survivor_injured
				end

				local fire_transform = nil
				if #location.objects.fires > 0 then
					fire_transform = matrix.multiply(spawn_transform, location.objects.fires[1].transform)
				end
				if fire_transform == nil then
					fire_transform = spawn_transform
				end

				local incoming_disaster = getIncomingDisaster(spawn_transform)

				-- set title and description
				if location.parameters.title ~= "" then
					mission.title = location.parameters.title
				else
					mission.title = "A building-fire has been reported"
				end

				if location.parameters.description ~= "" then
					mission.desc = location.parameters.description
				else
					mission.desc = "Arrive at the location of the fire to deduce the severity."
				end

				-- add mission

				addMission(mission)

				-- initialise mission data

				debugLog("adding mission with id " .. mission.id .. "...")

				-- add objectives to the mission
				mission.data.life = g_savedata.mission_life_base
				mission.data.zone_radius = 0
				mission.data.survivor_dead_count = 0
				local spawn_transform_x, spawn_transform_y, spawn_transform_z = matrix.position(fire_transform)
				mission.data.zone_x = spawn_transform_x
				mission.data.zone_z = spawn_transform_z
				mission.data.incoming_disaster = incoming_disaster
				mission.data.zone_transform = spawn_transform
				mission.data.reward = (survivor_count * 2000) + ((#location.objects.fires > 0) and 3000 or 0)

				mission.data.state = "locate zone"
				table.insert(mission.objectives, createObjectiveLocateZone(fire_transform))

				-- Natural disasters
				spawnDisaster(mission.data)

				server.notify(-1, "New Mission",  mission.desc, 0)

				if tableLength(spawned_objects.survivors) > 0 then
					server.command("?ai_summon_hospital_ship "..mission.data.zone_x.." "..mission.data.zone_z)
				end

				return true
			end

			return false
		end,

		update = function(self, mission)
			local imporant_loaded_prev = mission.is_important_loaded
			mission.is_important_loaded = false
			for survivor_id, survivor_object in pairs(mission.data.survivors) do
				if server.getObjectSimulating(survivor_object.id) then
					mission.is_important_loaded = true
				end
			end

			if mission.is_important_loaded == true and imporant_loaded_prev == false then
				server.setAudioMood(-1, 4)
			end
		end,

		tick = function(self, mission, delta_worldtime)
			if mission.data.life > 0 then
				if mission.is_important_loaded == false then mission.data.life = mission.data.life - delta_worldtime end
			else
				-- remove objectives to force mission to end
				mission.objectives = {}
			end
		end,

		on_vehicle_load = function(self, mission, vehicle_id)
		end,

		on_locate = function(self, mission, transform)
			mission.data.state = "rescue"
			self:spawn_location_objectives(mission)
		end,

		rebuild_ui = function(self, mission)
			addMarker(mission, createMarker(mission.data.zone_x, mission.data.zone_z, mission.title..(g_savedata.display_rewards and ("\n+$"..math.floor(mission.data.reward)) or "")..(g_savedata.display_timers and ("\n"..math.floor(mission.data.life/3600).."min") or ""), mission.desc, mission.data.zone_radius, 5))
		end,

		terminate = function(self, mission)
			if mission.data.life <= 0 then
				server.notify(-1, "Mission Expired",  "Another rescue service completed this mission.", 2)
			else
				server.notify(-1, "Mission Complete",  mission.desc, 4)
			end
		end,

		spawn_location_objectives = function(self, mission)
			-- rescue survivors
			local survivor_count = 0
			local survivor_dead_count = 0
			for survivor_id, survivor_object in pairs(mission.data.survivors) do
				local c = server.getCharacterData(survivor_object.id)
				if c then
					if c.interactable then
						if c.dead then
							survivor_dead_count = survivor_dead_count + 1
							mission.data.survivor_dead_count = mission.data.survivor_dead_count + 1
						else
							survivor_count = survivor_count + 1
							table.insert(mission.objectives, createObjectiveRescueCasualty(survivor_object))
						end
					end
				end
			end

			-- extinguish fires
			local fire_count = 0
			for fire_id, fire_object in pairs(mission.data.fires) do
				fire_count = fire_count + 1
			end

			table.insert(mission.objectives, createObjectiveExtinguishFire(mission.data.fires))

			if survivor_count > 0 and fire_count > 0 then
				mission.desc = "Extinguish all fires and rescue "..math.floor(survivor_count).." casualt"..(survivor_count > 1 and "ies" or "y").." to a hospital."
				server.notify(-1, "Casualties and Fire", mission.desc, 0)
			elseif survivor_count > 0 then
				mission.desc = "Rescue "..math.floor(survivor_count).." casualt"..(survivor_count > 1 and "ies" or "y").." to a hospital."
				server.notify(-1, "Casualties", mission.desc, 0)
			elseif fire_count > 0 then
				mission.desc = "Extinguish all fires."
				server.notify(-1, "Fire", mission.desc, 0)
			end

			server.setAudioMood(-1, 4)

			removeMissionMarkers(mission)
			self:rebuild_ui(mission)
		end,
	},
}

-------------------------------------------------------------------
--
--	Callbacks
--
-------------------------------------------------------------------

function onCreate(is_world_create)

	-- backwards compatability savedata checking
	if g_savedata.rescued_characters == nil then g_savedata.rescued_characters = {} end
	if g_savedata.mission_frequency == nil then g_savedata.mission_frequency = 60*60*60 end
	if g_savedata.mission_life_base == nil then g_savedata.mission_life_base = 60*60*60 end
	if g_savedata.disasters == nil then g_savedata.disasters = {} end
	if g_savedata.damage_tracker == nil then g_savedata.damage_tracker = {} end
	if g_savedata.oil_spills == nil then g_savedata.oil_spills = {} end

	for mission_type_name, mission_type_data in pairs(g_mission_types) do
		mission_type_data.valid_locations = {}
	end

	for i in iterPlaylists() do
		for j in iterLocations(i) do
			local parameters, mission_objects = loadLocation(i, j)
			local location_data = server.getLocationData(i, j)
			for mission_type_name, mission_type_data in pairs(g_mission_types) do
				mission_type_data:build_valid_locations(i, j, parameters, mission_objects, location_data)
			end
		end
	end

	g_zones = server.getZones()
	g_zones_hospital = server.getZones("hospital")

	-- filter zones to only include mission zones
	for zone_index, zone_object in pairs(g_zones) do
		local is_mission_zone = false
		for zone_tag_index, zone_tag_object in pairs(zone_object.tags) do
			if zone_tag_object == "type=mission_zone" then
				is_mission_zone = true
			end
		end
		if is_mission_zone == false then
			g_zones[zone_index] = nil
		end
	end
end

function onVehicleDamaged(vehicle_id, amount, x, y, z)
	if g_savedata.damage_tracker[vehicle_id] ~= nil then
		g_savedata.damage_tracker[vehicle_id] = g_savedata.damage_tracker[vehicle_id] + amount
	end

end

function onPlayerJoin(steamid, name, peerid, admin, auth)
	if g_savedata.missions ~= nil then
		for k, mission_data in pairs(g_savedata.missions) do
			for k, marker in pairs(mission_data.map_markers) do
				if marker.archetype == "default" then
					server.addMapObject(peerid, marker.id, 0, marker.type, marker.x, marker.z, 0, 0, 0, 0, marker.display_label, marker.radius, marker.hover_label)
				elseif marker.archetype == "line" then
					server.addMapLine(-1, marker.id, marker.start_matrix, marker.dest_matrix, marker.width)
				end
			end
		end
	end

	if g_savedata.oil_spills ~= nil then
		for _, spill_x in pairs(g_savedata.oil_spills) do
			for k, spill_z in pairs(spill_x) do
				server.addMapObject(peerid, spill_z.id, 0, 8, spill_z.x, spill_z.z, 0, 0, 0, 0, spill_z.display_label, spill_z.radius, spill_z.hover_label, 20, 20, 20, 150)
			end
		end
	end
end

function onToggleMap(peer_id, is_open)
	map_update_cooldown = math.max(map_update_cooldown - 1, 0)
	if map_update_cooldown > 0 then return end
	map_update_cooldown = 600

	for _, mission in pairs(g_savedata.missions) do
		removeMissionMarkers(mission)
		g_mission_types[mission.type]:rebuild_ui(mission)
	end

	rebuildDisasters()
end

function onTick(delta_worldtime)
	math.randomseed(server.getTimeMillisec())

	tickDisasters()

	for char_id, timer in pairs(g_savedata.rescued_characters) do
		if timer <= 180 then
			g_savedata.rescued_characters[char_id] = timer + 1
		end
		if timer == 180 then
			server.setCharacterData(char_id, 100, true, false)
			server.setCharacterTooltip(char_id, "Rescued Survivor")
			g_savedata.rescued_characters[char_id] = nil
		end
	end

	local difficulty_factor = getDifficulty()
	local min_range = 2000 + (3000 * difficulty_factor)
	local max_range = 2500 + (30000 * difficulty_factor)

	if server.getTutorial() == false then
		if g_savedata.spawn_counter <= 0 then
			local attempts = 0
			local is_mission_spawn = false
			repeat
				attempts = attempts + 1
				is_mission_spawn = startMission(nil, min_range, max_range, difficulty_factor)
			until is_mission_spawn or attempts > 15

			if is_mission_spawn then
				g_savedata.spawn_counter = g_savedata.mission_frequency
			else
				g_savedata.spawn_counter = 60 * 60 * 3
			end
		else
			g_savedata.spawn_counter = g_savedata.spawn_counter - delta_worldtime
		end
	end

	for _, mission in pairs(g_savedata.missions) do
		local mission_type = g_mission_types[mission.type]
		mission_type:tick(mission, delta_worldtime)

		local objective_count = 0
		local is_mission_ui_modified = false
		local is_success = false

		g_objective_update_counter = g_objective_update_counter + 1

		for k, objective in pairs(mission.objectives) do
			local objective_type = g_objective_types[objective.type]

			if g_objective_update_counter > 60 then
				is_success, is_mission_ui_modified = objective_type:update(mission, objective, delta_worldtime)
				if is_success then
					mission.objectives[k] = nil
				end
			end

			objective_count = objective_count + 1
		end

		if g_objective_update_counter > 60 then
			mission_type:update(mission, delta_worldtime)
			g_objective_update_counter = 0
		end

		if objective_count == 0 then
			mission_type:terminate(mission)
			endMission(mission, false)
		elseif is_mission_ui_modified then
			removeMissionMarkers(mission)
			g_mission_types[mission.type]:rebuild_ui(mission)
		end
	end
end

function onCustomCommand(message, user_id, admin, auth, command, one, two, three)
	math.randomseed(server.getTimeMillisec())

	local name = server.getPlayerName(user_id)

	if server.getGameSettings().settings_menu == false then
		return
	end

	if command == "?mstart" and admin == true then
		if one ~= nil and one ~= "" then

			local difficulty_factor = 1.0
			if two ~= nil and two ~= "" then
				difficulty_factor = tonumber(two)
			end

			local min_range = 0
			local max_range = 2500 + (30000 * difficulty_factor)

			if g_mission_types[one] == nil then server.announce("[Server]", "Usage: ?mstart {building, tow_vehicle, crashed_vehicle, transport} [difficulty:0-1]") return end
			if #g_mission_types[one].valid_locations < 1 then server.announce("[Server]", "No valid locations found for that mission type!") return end

			local attempts = 0
			repeat
				attempts = attempts + 1

				local random_location_value = math.random(1, #g_mission_types[one].valid_locations)
				local mission = createMission(one)
				local is_mission_spawn = g_mission_types[one]:spawn(mission, g_mission_types[one].valid_locations[random_location_value], difficulty_factor, nil, min_range, max_range)

				if is_mission_spawn then
					server.announce("[Server]", name .. " spawned a mission")
					g_mission_types[one]:rebuild_ui(mission)
				elseif attempts > 15 then
					server.announce("[Server]", "No valid locations nearby in 15 attempts.")
				end
			until is_mission_spawn or attempts > 15
		else
			local difficulty_factor = getDifficulty()
			local min_range = 2000 + (3000 * difficulty_factor)
			local max_range = 2500 + (30000 * difficulty_factor)

			local attempts = 0
			repeat
				attempts = attempts + 1

				local is_mission_spawn = startMission(nil, min_range, max_range, difficulty_factor)

				if is_mission_spawn then
					server.announce("[Server]", name .. " spawned a mission")
				elseif attempts > 15 then
					server.announce("[Server]", "No valid locations nearby in 15 attempts.")
				end
			until is_mission_spawn or attempts > 15
		end
	end

	if (command == "?mclean" or command == "?mclear") and admin == true then
		for _, mission in pairs(g_savedata.missions) do
			server.announce("[Server]", "Despawned mission: " .. mission.title)
			endMission(mission, true)
		end
	end

	if server.isDev() then

		if command == "?mtest" and admin == true then
			if one ~= nil and one ~= "" then

				local difficulty_factor = 1.0
				if two ~= nil and two ~= "" then
					difficulty_factor = tonumber(two)
				end

				local min_range = 0
				local max_range = 2500 + (30000 * difficulty_factor)

				if g_mission_types[one] == nil then server.announce("[Server]", "Usage: ?mtest {building, tow_vehicle, crashed_vehicle, transport} {difficulty:0-1} {location_name}") return end
				if #g_mission_types[one].valid_locations < 1 then server.announce("[Server]", "No valid locations found for that mission type!") return end

				local attempts = 0
				repeat
					attempts = attempts + 1

					server.announce("try spawn: ", attempts)

					local location_value = nil

					for i, loc in pairs(g_mission_types[one].valid_locations) do
						if loc.data.name == three then
							location_value = i
						end
					end

					local is_mission_spawn = false

					if location_value ~= nil then
						local mission = createMission(one)
						is_mission_spawn = g_mission_types[one]:spawn(mission, g_mission_types[one].valid_locations[location_value], difficulty_factor, nil, min_range, max_range)

						if is_mission_spawn then
							server.announce("[Server]", name .. " spawned a mission")
							g_mission_types[one]:rebuild_ui(mission)
						elseif attempts > 25 then
							server.announce("[Server]", "No valid locations nearby in 25 attempts.")
						end
					end
				until is_mission_spawn or attempts > 25
			else
				server.announce("[Server]", "Usage: ?mtest {building, tow_vehicle, crashed_vehicle, transport} {difficulty:0-1} {location_name}")
			end
		end

		if command == "?mtestdisaster" and admin == true then
			local data = {
				incoming_disaster = one,
				zone_transform = server.getPlayerPos(0)
			}
			spawnDisaster(data)
		end

		if command == "?moil" and admin == true then
			oil_debug = (oil_debug == false)
			server.announce("oil debug", oil_debug and "True" or "False")
		end

		if command == "?log" and admin == true then
			printLog()
		end

		if command == "?printdata" and admin == true then
			server.announce("[Debug]", "---------------")
			printTable(g_savedata, "missions")
			server.announce("", "---------------")
		end

		if command == "?printtables" and admin == true then
			server.announce("[Debug]", "---------------")
			printTable(g_objective_types, "objective types")
			printTable(g_mission_types, "mission types")
			server.announce("", "---------------")
		end

		if command == "?printplaylists" and admin == true then
			for i, data in iterPlaylists() do
				printTable(data, "playlist_" .. i)
			end
		end

		if command == "?printlocations" and admin == true then
			for i, data in iterLocations(tonumber(one) or 0) do
				printTable(data, "location_" .. i)
			end
		end

		if command == "?printobjects" and admin == true then
			for i, data in iterObjects(tonumber(one) or 0, tonumber(two) or 0) do
				printTable(data, "object_" .. i)
			end
		end

		if command == "?printtags" and admin == true then
			local location_tags = {}

			server.announce("", "Begin location tags")

			for i in iterPlaylists() do
				for j in iterLocations(i) do
					for _, object_data in iterObjects(i, j) do
						local is_mission_object = false
						for tag_index, tag_object in pairs(object_data.tags) do
							if tag_object == "type=mission" then
								is_mission_object = true
							end
						end

						if is_mission_object then
							for tag_index, tag_object in pairs(object_data.tags) do
								if location_tags[tag_object] == nil then
									location_tags[tag_object] = 1
								else
									location_tags[tag_object] = location_tags[tag_object] + 1
								end
							end
						end
					end
				end
			end

			local location_tag_keys = {}
			-- populate the table that holds the keys
			for tag_index, tag_object in pairs(location_tags) do table.insert(location_tag_keys, tag_index) end
			-- sort the keys
			table.sort(location_tag_keys)
			-- use the keys to retrieve the values in the sorted order
			for _, key in ipairs(location_tag_keys) do
				server.announce(key, location_tags[key])
			end

			server.announce("", "End location tags")

			server.announce("", "Begin zone tags")

			local zone_tags = {}

			for zone_index, zone_object in pairs(g_zones) do
				for zone_tag_index, zone_tag_object in pairs(zone_object.tags) do
					if zone_tags[zone_tag_object] == nil then
						zone_tags[zone_tag_object] = 1
					else
						zone_tags[zone_tag_object] = zone_tags[zone_tag_object] + 1
					end
				end
			end

			local zone_tag_keys = {}
			-- populate the table that holds the keys
			for tag_index, tag_object in pairs(zone_tags) do table.insert(zone_tag_keys, tag_index) end
			-- sort the keys
			table.sort(zone_tag_keys)
			-- use the keys to retrieve the values in the sorted order
			for _, key in ipairs(zone_tag_keys) do
				server.announce(key, zone_tags[key])
			end

			server.announce("", "End zone tags")
		end
	end
end

function onVehicleLoad(vehicle_id)
	for _, mission in pairs(g_savedata.missions) do
		local mission_type = g_mission_types[mission.type]
		mission_type:on_vehicle_load(mission, vehicle_id)
	end
end

-------------------------------------------------------------------
--
--	Mission Logic
--
-------------------------------------------------------------------

function is_spawn_location_clear(transform, zone_size)

	-- check existing missions
	for k, mission_data in pairs(g_savedata.missions) do
		if matrix.distance(mission_data.data.zone_transform, transform) < 50 then
			debugLog("mission spawn failed: too close to an existing mission")
			return false
		end
	end

	-- check for any vehicles in the way
	local is_clear = server.isLocationClear(transform, 5, 5, 5)

	if is_clear == false then
		local x, y, z = matrix.position(transform)
		debugLog("location "..x.." "..y.." "..z.." was not clear")
	end

	return is_clear
end

function onOilSpill(x, z, delta, amount, v_id)

	if g_savedata.enable_oil_spills == false then return nil end

	if amount > 100.0 or oil_debug then
		if g_savedata.oil_spills[x] == nil then g_savedata.oil_spills[x] = {} end
		if g_savedata.oil_spills[x][z] == nil then
			-- new spill data
			g_savedata.oil_spills[x][z] = { oil = 0.0 }
			g_savedata.oil_spills[x][z].id = server.getMapID()
			g_savedata.oil_spills[x][z].title = "Oil Spill"
			g_savedata.oil_spills[x][z].desc = "Clean up the oil spill!"
			g_savedata.oil_spills[x][z].zone_radius = 500
			local radius_offset = g_savedata.oil_spills[x][z].zone_radius * (math.random(20, 90) / 100)
			local angle = math.random(0,100) / 100 * 2 * math.pi

			if oil_debug == false then
				g_savedata.oil_spills[x][z].x = (x * 1000) + radius_offset * math.cos(angle)
				g_savedata.oil_spills[x][z].z = (z * 1000) + radius_offset * math.sin(angle)

				local adjacent_oil = false
				for i = -1, 1, 1 do
					for j = -1, 1, 1 do
						if i ~= 0 or j ~= 0 then
							if g_savedata.oil_spills[x+i] ~= nil then
								if g_savedata.oil_spills[x+i][z+j] ~= nil then
									if g_savedata.oil_spills[x+i][z+j].oil > 100.0 then
										adjacent_oil = true
									end
								end
							end
						end
					end
				end

				if adjacent_oil == false then
					server.notify(-1, "New Oil Spill", "The location has been marked on your map.", 0)
				end
			else
				g_savedata.oil_spills[x][z].x = x * 1000
				g_savedata.oil_spills[x][z].z = z * 1000
			end
		end

		g_savedata.oil_spills[x][z].oil = amount

		local g = 20
		if oil_debug and amount > 100.0 then g = 200 end

		local debug_oil_str = ""
		if oil_debug then
			debug_oil_str = "\nOil Amount: "..g_savedata.oil_spills[x][z].oil
		end

		server.removeMapObject(-1, g_savedata.oil_spills[x][z].id)
		server.addMapObject(-1, g_savedata.oil_spills[x][z].id, 0, 8, g_savedata.oil_spills[x][z].x, g_savedata.oil_spills[x][z].z, 0, 0, 0, 0, g_savedata.oil_spills[x][z].title, g_savedata.oil_spills[x][z].zone_radius, g_savedata.oil_spills[x][z].desc..debug_oil_str, 20, g, 20, 150)
	elseif amount < 50.0 and oil_debug == false then
		if g_savedata.oil_spills[x] ~= nil then
			if g_savedata.oil_spills[x][z] ~= nil then
				server.removeMapObject(-1,  g_savedata.oil_spills[x][z].id)
				g_savedata.oil_spills[x][z] = nil

				if v_id ~= -1 then
					local reward = 2000
					server.notify(-1, "Oil Spill Cleaned", "The oil spill has been cleared. Rewarded $"..math.floor(reward)..".", 4)
					server.setCurrency(server.getCurrency() + reward, server.getResearchPoints())
				end
			end
		end
	else
		if g_savedata.oil_spills[x] ~= nil then
			if g_savedata.oil_spills[x][z] ~= nil then
				g_savedata.oil_spills[x][z].oil = amount

				local g = 20
				if oil_debug and amount > 100.0 then g = 200 end

				local debug_oil_str = ""
				if oil_debug then
					debug_oil_str = "\nOil Amount: "..g_savedata.oil_spills[x][z].oil
				end

				server.removeMapObject(-1, g_savedata.oil_spills[x][z].id)
				server.addMapObject(-1, g_savedata.oil_spills[x][z].id, 0, 8, g_savedata.oil_spills[x][z].x, g_savedata.oil_spills[x][z].z, 0, 0, 0, 0, g_savedata.oil_spills[x][z].title, g_savedata.oil_spills[x][z].zone_radius, g_savedata.oil_spills[x][z].desc..debug_oil_str, 20, g, 20, 150)
			end
		end
	end
end

function getClosestVolcano(transform)
	local volcanos = server.getVolcanos()
	local closest_dist = 999999999
	local closest_volcano = nil

	for tile, v in pairs(volcanos) do
		local dist = matrix.distance(transform, matrix.translation(v.x, 0, v.z))
		if dist < closest_dist then
			closest_dist = dist
			closest_volcano = v
		end
	end

	return closest_volcano, closest_dist
end

function getIncomingDisaster(transform)

	if g_savedata.enable_disasters == false then return nil end

	if #g_savedata.disasters > 0 then
		return nil --Limit disaster missions to 1 at a time to prevent overlap of evacuation objectives
	end

	local difficulty_factor = getDifficulty()
	local w = server.getWeather(transform)
	local t = server.getTile(transform)
	local is_ocean_zone = t.name == ""

	local closest_volcano, dist = getClosestVolcano(transform)
	if closest_volcano and dist < 2000 and math.random() <= (difficulty_factor * 0.7) + 0.1 then
		return "volcano"
	end

	if math.random() <= (difficulty_factor * 0.3) + 0.1 then
		return "meteor"
	elseif is_ocean_zone and math.random() <= (difficulty_factor * 0.3) + 0.1 then
		return "whirlpool"
	elseif math.random() <= (difficulty_factor * 0.3) + 0.1 then
		return "tsunami"
	elseif w.wind > 70 and math.random() <= (difficulty_factor * 0.9) + 0.1 then
		return "tornado"
	end
	return nil
end

function getDisasterFlavor(incoming_disaster)
	if incoming_disaster == "tornado" then
		return "Extreme wind has been detected on location."
	elseif incoming_disaster == "whirlpool" then
		return "Tectonic disruptions to the seabed are causing unpredictable water currents."
	elseif incoming_disaster ==  "tsunami" then
		return "Seismic activity has caused large scale ocean displacement, a tsunami warning has been issued."
	elseif incoming_disaster == "meteor" then
		return "Nearby weather stations have detected an incoming impact event."
	elseif incoming_disaster ==  "volcano" then
		return "Seismic activity in the area has triggered a volcanic response."
	end
	return ""
end

function spawnDisaster(data)
	if data.incoming_disaster ~= nil then
		local radius_offset = 2000 * (math.random(20, 90) / 100)
		local angle = math.random(0,100) / 100 * 2 * math.pi
		local spawn_transform_x, spawn_transform_y, spawn_transform_z = matrix.position(data.zone_transform)

		local disaster = {
			countdown = 60 * 60 * math.random(30, 60),
			transform = data.zone_transform,
			ui_x = spawn_transform_x + radius_offset * math.cos(angle),
			ui_z = spawn_transform_z + radius_offset * math.sin(angle),
			type = data.incoming_disaster,
			map_markers = {},
		}
		table.insert(g_savedata.disasters, disaster)

		addMarker(disaster, createMarker(disaster.ui_x, disaster.ui_z, "WARNING: EXTREME WEATHER", getDisasterFlavor(disaster.type), 4000, 8), 20, 20, 230, 200)

		-- spawn evac mission
		local difficulty_factor = 1.0
		local min_range = 0
		local max_range = 2500 + (30000 * difficulty_factor)

		if #g_mission_types["evacuate"].valid_locations < 1 then server.announce("[Server]", "No valid locations found for that mission type!") return end

		local random_location_value = math.random(1, #g_mission_types["evacuate"].valid_locations)
		local mission = createMission("evacuate")
		local is_mission_spawn = g_mission_types["evacuate"]:spawn(mission, g_mission_types["evacuate"].valid_locations[random_location_value], difficulty_factor, data.zone_transform, min_range, max_range)
		if is_mission_spawn then
			g_mission_types["evacuate"]:rebuild_ui(mission)
		end
	end
end

function rebuildDisasters()
	if g_savedata.disasters == nil then return end
	for i, disaster in pairs(g_savedata.disasters) do
		removeMissionMarkers(disaster)
		addMarker(disaster, createMarker(disaster.ui_x, disaster.ui_z, "WARNING: EXTREME WEATHER", getDisasterFlavor(disaster.type), 4000, 8), 20, 20, 230, 200)
	end
end

function getDisasterDuration(disaster)
	if disaster.type == "tornado" then
		return 4
	elseif disaster.type == "whirlpool" then
		return 6
	elseif disaster.type == "tsunami" then
		return 6
	elseif disaster.type == "meteor" then
		return 1
	elseif disaster.type == "volcano" then
		return 2
	end
end

function tickDisasters()
	if g_savedata.disasters == nil then return end

	for i, disaster in pairs(g_savedata.disasters) do
		disaster.countdown = disaster.countdown - 1

		if disaster.countdown == 0 then
			local radius_offset = 1500 + (1000 * math.random())
			local angle = math.random(0,100) / 100 * 2 * math.pi
			local spawn_transform_x, spawn_transform_y, spawn_transform_z = matrix.position(disaster.transform)
			local offset_spawn = matrix.translation(spawn_transform_x + radius_offset * math.cos(angle), 0, spawn_transform_z + radius_offset * math.sin(angle))

			if disaster.type == "tornado" then
				server.spawnTornado(offset_spawn)
			elseif disaster.type == "whirlpool" then
				ocean, is_success = server.getOceanTransform(disaster.transform, 1000, 5000)
				if is_success then
					server.spawnWhirlpool(ocean, 1)
				end
			elseif disaster.type == "tsunami" then
				ocean, is_success = server.getOceanTransform(disaster.transform, 4000, 8000)
				if is_success then
					server.spawnTsunami(disaster.transform, 1)
				end
			elseif disaster.type == "meteor" then
				server.spawnMeteorShower(offset_spawn, 1, true)
			elseif disaster.type == "volcano" then
				local closest_volcano, _ = getClosestVolcano(disaster.transform)
				if closest_volcano then
					server.spawnVolcano(matrix.translation(closest_volcano.x, 0, closest_volcano.z))
				end
			end
		elseif disaster.countdown == -60*60*getDisasterDuration(disaster) then
			removeMissionMarkers(disaster)
			startMission(disaster.transform, 2000, 4000, getDifficulty())
			startMission(disaster.transform, 2000, 4000, getDifficulty())
			g_savedata.disasters[i] = nil
		end
	end
end

function getDifficulty()
	local mission_difficulty_factor = 1
	if server.getGameSettings().no_clip == false then
		mission_difficulty_factor = math.min(1, server.getDateValue() / 60)
	end
	return mission_difficulty_factor
end

function startMission(override_transform, min_range, max_range, mission_difficulty_factor)
	g_output_log = {}

	local mission_type_location_count = 0;
	local mission_type_location_probability_count = 0;

	for mission_type_name, mission_type_data in pairs(g_mission_types) do
		for location_index, location_data in pairs(mission_type_data.valid_locations) do
			mission_type_location_count = mission_type_location_count + 1
			mission_type_location_probability_count = mission_type_location_probability_count + location_data.parameters.probability
		end
	end

	if mission_type_location_count > 0 then
		local random_location_value = math.random(0, math.floor(mission_type_location_probability_count * 100)) / 100

		local selected_mission_type_name = nil
		local selected_mission_type_data = nil
		local selected_mission_location_index = nil

		for mission_type_name, mission_type_data in pairs(g_mission_types) do
			for location_index, location_data in pairs(mission_type_data.valid_locations) do
				if random_location_value > location_data.parameters.probability then
					random_location_value = random_location_value - location_data.parameters.probability
				else
					if selected_mission_type_name == nil then
						selected_mission_type_name = mission_type_name
						selected_mission_type_data = mission_type_data
						selected_mission_location_index = location_index
					end
				end
			end
		end

		if selected_mission_type_data ~= nil then
			local mission = createMission(selected_mission_type_name)

			local is_mission_spawn = selected_mission_type_data:spawn(mission, selected_mission_type_data.valid_locations[selected_mission_location_index], mission_difficulty_factor, override_transform, min_range, max_range)

			if is_mission_spawn then
				selected_mission_type_data:rebuild_ui(mission)
			end

			return is_mission_spawn
		end
	end

	return false
end

-- removes a mission from the global mission container and cleans up its spawned objects and UI
function endMission(mission, force_despawn)
	if mission ~= nil then
		removeMissionMarkers(mission)

		despawnObjects(mission.spawned_objects, force_despawn)

		for k, mission_data in pairs(g_savedata.missions) do
			if mission_data.id == mission.id then
				g_savedata.missions[k] = nil
			end
		end
	end
end

-------------------------------------------------------------------
--
--	Mission Creation
--
-------------------------------------------------------------------

function findSuitableZones(parameters, min_range, max_range, is_ocean_zone, override_transform)

	local zones = {}

	if is_ocean_zone and math.random(1, 2) == 1 then
		-- get random player to search for ocean zone near

		local players = server.getPlayers()
		local random_player = players[math.random(1, #players)]
		local spawn_pos = server.getPlayerPos(random_player.id)

		if override_transform ~= nil then
			spawn_pos = override_transform
		end

		local ocean_transform, is_ocean_found = server.getOceanTransform(spawn_pos, min_range, max_range)
		local offset_transform = matrix.multiply(ocean_transform, matrix.translation(math.random(-750, 750), 7.5, math.random(-750, 750)))

		if parameters.theme == "theme=underwater" then
			local ocean_floor_height = server.getOceanFloor(offset_transform)
			offset_transform[14] = offset_transform[14] + ocean_floor_height
		end

		if is_ocean_found then
			-- generate a zone in the ocean

			local zone_object = {
				name = "in the ocean",
				transform = offset_transform,
				size = {
					x = 15,
					y = 15,
					z = 15,
				},
				radius = 1,
				type = 0,
				tags = {
					"size=large",
					"location_type=ocean",
					"theme=oil",
					"theme=fishing",
				},
			}

			table.insert(zones, zone_object)
		end
	else
		-- find a suitable zone from the list of existing zones

		for zone_index, zone_object in pairs(g_zones) do
			-- filter range
			local is_in_range = false

			if override_transform ~= nil then
				local distance_to_zone = matrix.distance(override_transform, zone_object.transform)
				if distance_to_zone > min_range and distance_to_zone < max_range then
					is_in_range = true
				end
			else
				local players = server.getPlayers()
				for player_index, player_object in pairs(players) do
					local distance_to_zone = matrix.distance(server.getPlayerPos(player_object.id), zone_object.transform)

					if distance_to_zone > min_range and distance_to_zone < max_range then
						is_in_range = true
					end
				end
			end

			if is_in_range then
				local is_filter = false

				if parameters.is_evacuate and (hasTag(zone_object.tags, "evacuation") == false) then
					is_filter = true
				end

				-- filter size
				if parameters.size == "size=medium" then
					if hasTag(zone_object.tags, "size=medium") == false and hasTag(zone_object.tags, "size=large") == false then
						is_filter = true
					end
				elseif parameters.size == "size=large" then
					if hasTag(zone_object.tags, "size=large") == false then
						is_filter = true
					end
				end

				if parameters.theme == "theme=underwater" then
					if parameters.vehicle_type == "vehicle_type=cave" then
						if
							hasTag(zone_object.tags, "location_type=underwater_cave") == false
						then
							is_filter = true
						end
					else
						if
							hasTag(zone_object.tags, "location_type=underwater_shore") == false
						then
							is_filter = true
						end
					end
				end

				if is_ocean_zone then
					if parameters.theme ~= "theme=underwater" then
						if
							hasTag(zone_object.tags, "location_type=ocean") == false and
							hasTag(zone_object.tags, "location_type=ocean_bridge") == false and
							hasTag(zone_object.tags, "location_type=ocean_iceberg") == false and
							hasTag(zone_object.tags, "location_type=ocean_rocks") == false and
							hasTag(zone_object.tags, "location_type=ocean_shore") == false
						then
							is_filter = true
						end
					end
				else

					-- filter theme
					if parameters.theme ~= nil and parameters.theme ~= "" then
						if hasTag(zone_object.tags, parameters.theme) == false then
							if parameters.theme ~= "theme=civilian" then
								is_filter = true
							end
						end
					end

					-- filter by vehicle type
					if parameters.vehicle_type == "vehicle_type=car" then
						if parameters.theme == "theme=camp" then
							if
								hasTag(zone_object.tags, "location_type=land_road") == false and
								hasTag(zone_object.tags, "location_type=land_forest") == false and
								hasTag(zone_object.tags, "location_type=land_shore") == false and
								hasTag(zone_object.tags, "location_type=land") == false and
								hasTag(zone_object.tags, "location_type=land_offroad") == false
							then
								is_filter = true
							end
						else
							if
								hasTag(zone_object.tags, "location_type=land_road") == false
							then
								is_filter = true
							end
						end
					elseif parameters.vehicle_type == "vehicle_type=helicopter" then
						if
							hasTag(zone_object.tags, "location_type=land_forest") == false and
							hasTag(zone_object.tags, "location_type=land_shore") == false and
							hasTag(zone_object.tags, "location_type=land_road") == false and
							hasTag(zone_object.tags, "location_type=land_helipad") == false
						then
							is_filter = true
						end
					elseif parameters.vehicle_type == "vehicle_type=plane" then
						if
							hasTag(zone_object.tags, "location_type=land_forest") == false and
							hasTag(zone_object.tags, "location_type=land_shore") == false and
							hasTag(zone_object.tags, "location_type=land_road") == false and
							hasTag(zone_object.tags, "location_type=land_runway") == false
						then
							is_filter = true
						end
					elseif parameters.vehicle_type == "vehicle_type=underwater_cable" then
						if
							hasTag(zone_object.tags, "location_type=underwater_cable") == false
						then
							is_filter = true
						end
					elseif parameters.vehicle_type == "vehicle_type=boat_river" then
						if
							hasTag(zone_object.tags, "location_type=ocean_river") == false
						then
							is_filter = true
						end
					elseif parameters.vehicle_type == "vehicle_type=boat_ocean" then
						-- handled in is_ocean_zone case
					elseif parameters.vehicle_type == "vehicle_type=plane_ocean" then
						-- handled in is_ocean_zone case
					end

					if parameters.source_zone_type ~= nil and parameters.source_zone_type ~= "" then
						if hasTag(zone_object.tags, "zone_type="..parameters.source_zone_type) == false then
							is_filter = true
						end
					end

					if parameters.destination_zone_type ~= nil and parameters.destination_zone_type ~= "" then
						if hasTag(zone_object.tags, "zone_type="..parameters.destination_zone_type) == false then
							is_filter = true
						end
					end
				end

				if is_filter == false then
					table.insert(zones, zone_object)
				end
			end
		end
	end

	return zones
end

function loadLocation(playlist_index, location_index)

	local mission_objects =
	{
		main_vehicle_component = nil,
		vehicles = {},
		survivors = {},
		fires = {},
		objects = {},
		display_name = "",
	}

	local parameters = {
		type = "",
		size = "",
		theme = "",
		vehicle_type = "",
		vehicle_state = "",
		source_zone_type = "",
		destination_zone_type = "",
		probability = 1,
		capabilities = {},
		title = "",
		description = "",
	}

	for _, object_data in iterObjects(playlist_index, location_index) do
		-- investigate tags
		local is_tag_object = false
		for tag_index, tag_object in pairs(object_data.tags) do
			if tag_object == "type=mission" then
				is_tag_object = true
				parameters.type = "mission"
			end
			if tag_object == "type=mission_transport" then
				is_tag_object = true
				parameters.type = "mission_transport"
			end
			if tag_object == "type=mission_building" then
				is_tag_object = true
				parameters.type = "mission_building"
			end
		end

		if is_tag_object then
			for tag_index, tag_object in pairs(object_data.tags) do
				if string.find(tag_object, "size=") ~= nil then
					parameters.size = tag_object
				elseif string.find(tag_object, "theme=") ~= nil then
					parameters.theme = tag_object
				elseif string.find(tag_object, "vehicle_type=") ~= nil then
					parameters.vehicle_type = tag_object
				elseif string.find(tag_object, "vehicle_state=") ~= nil then
					parameters.vehicle_state = tag_object
				elseif string.find(tag_object, "probability=") ~= nil then
					parameters.probability = tonumber(string.sub(tag_object, 13))
				elseif string.find(tag_object, "source_zone_type=") ~= nil then
					parameters.source_zone_type = string.sub(tag_object, 18)
				elseif string.find(tag_object, "destination_zone_type=") ~= nil then
					parameters.destination_zone_type = string.sub(tag_object, 23)
				elseif string.find(tag_object, "capability=") ~= nil then
					table.insert(parameters.capabilities, string.sub(tag_object, 12))
				elseif string.find(tag_object, "title=") ~= nil then
					parameters.title = string.sub(tag_object, 7)
				elseif string.find(tag_object, "description=") ~= nil then
					parameters.description = string.sub(tag_object, 13)
				end
			end

			mission_objects.display_name = object_data.display_name
		end

		if object_data.type == "vehicle" then
			table.insert(mission_objects.vehicles, object_data)
			if mission_objects.main_vehicle_component == nil and is_tag_object then
				mission_objects.main_vehicle_component = object_data
			end
		elseif object_data.type == "character" then
			table.insert(mission_objects.survivors, object_data)
		elseif object_data.type == "fire" then
			table.insert(mission_objects.fires, object_data)
		elseif object_data.type == "object" then
			table.insert(mission_objects.objects, object_data)
		elseif object_data.type == "animal" then
			table.insert(mission_objects.objects, object_data)
		end
	end

	return parameters, mission_objects
end

-- creates an empty mission and assigns it a unique id
function createMission(mission_type_name)
	g_savedata.id_counter = g_savedata.id_counter + 1

	return {
		id = g_savedata.id_counter,
		type = mission_type_name,
		spawned_objects = {},
		data = {},
		map_markers = {},
		objectives = {},
		title = "",
		desc = "",
		is_important_loaded = false
	}
end

-- adds a mission to the global mission container and notifies players that it is available
function addMission(mission)
	g_savedata.missions[mission.id] = mission

	g_savedata.spawn_counter = 60 * 60 * math.random(30, 120)
end

-------------------------------------------------------------------
--
--	Mission Objective Behaviour
--
-------------------------------------------------------------------

function createObjective()
	return {
		type = "",
		objects = {},
		transform = {},
	}
end

function createObjectiveLocateZone(zone_transform)
	local objective = createObjective()

	objective.type = "locate_zone"
	objective.transform = zone_transform

	return objective
end

function createObjectiveLocateVehicle(vehicle_id)
	local objective = createObjective()

	objective.type = "locate_vehicle"
	objective.vehicle_id = vehicle_id

	return objective
end

function createObjectiveRescueCasualty(survivor)
	local objective = createObjective()

	objective.type = "rescue_casualty"
	table.insert(objective.objects, survivor)
	objective.reward_value = 2000

	return objective
end

function createObjectiveExtinguishFire(fires)
	local objective = createObjective()

	objective.type = "extinguish_fire"
	objective.objects = fires
	objective.reward_value = 3000

	return objective
end

function createObjectiveRepairVehicle(vehicle_id)
	local objective = createObjective()

	objective.type = "repair_vehicle"
	objective.vehicle_id = vehicle_id
	objective.reward_value = 2000
	objective.damaged = false

	return objective
end

function createObjectiveTransportCharacter(object, destination, reward)
	local objective = createObjective()

	objective.type = "transport_character"
	table.insert(objective.objects, object)
	objective.destination = destination
	objective.reward_value = reward

	return objective
end

function createObjectiveTransportVehicle(object, destination, reward)
	local objective = createObjective()

	objective.type = "transport_vehicle"
	table.insert(objective.objects, object)
	objective.destination = destination
	objective.reward_value = reward

	return objective
end

function createObjectiveTransportObject(object, destination, reward)
	local objective = createObjective()

	objective.type = "transport_object"
	table.insert(objective.objects, object)
	objective.destination = destination
	objective.reward_value = reward

	return objective
end

function createObjectiveMoveToZones(survivor)
	local objective = createObjective()

	objective.type = "move_to_zones"
	table.insert(objective.objects, survivor)
	objective.reward_value = 2000

	return objective
end

-------------------------------------------------------------------
--
--	Mission UI
--
-------------------------------------------------------------------

-- adds a marker to a mission
function addMarker(mission_data, marker_data, r, g, b, a)
	marker_data.archetype = "default"
	table.insert(mission_data.map_markers, marker_data)
	server.addMapObject(-1, marker_data.id, 0, marker_data.type, marker_data.x, marker_data.z, 0, 0, 0, 0, marker_data.display_label, marker_data.radius, marker_data.hover_label, r, g, b, a)
end

function addLineMarker(mission_data, marker_data, r, g, b, a)
	marker_data.archetype = "line"
	table.insert(mission_data.map_markers, marker_data)
	server.addMapLine(-1, marker_data.id, marker_data.start_matrix, marker_data.dest_matrix, marker_data.width, r, g, b, a)
end

function createMarker(x, z, display_label, hover_label, radius, icon)
	local map_id = server.getMapID()

	return {
		id = map_id,
		type = icon,
		x = x,
		z = z,
		radius = radius,
		display_label = display_label,
		hover_label = hover_label
	}
end

function createLineMarker(start_matrix, dest_matrix, width)
	local map_id = server.getMapID()

	return {
		id = map_id,
		start_matrix = start_matrix,
		dest_matrix = dest_matrix,
		width = width
	}
end

-------------------------------------------------------------------
--
--	Utility Functions
--
-------------------------------------------------------------------

-- spawn a list of object descriptors from a playlist location.
-- playlist_index is required to spawn vehicles from the correct playlist.
-- a table of spawned object data is returned, as well as the data being appended to an option out_spawned_objects table
function spawnObjects(spawn_transform, location, object_descriptors, out_spawned_objects, spawn_rarity, min_amount, max_amount)
	local spawned_objects = {}

	for _, object in pairs(object_descriptors) do
		if ((#spawned_objects < min_amount) or (math.random(1, spawn_rarity) == 1)) and #spawned_objects < max_amount then
			-- find parent vehicle id if set
			local parent_vehicle_id = 0
			if object.vehicle_parent_component_id > 0 then
				for spawned_object_id, spawned_object in pairs(out_spawned_objects) do
					if spawned_object.type == "vehicle" and spawned_object.component_id == object.vehicle_parent_component_id then
						parent_vehicle_id = spawned_object.id
					end
				end
			end
			spawnObject(spawn_transform, location, object, parent_vehicle_id, spawned_objects, out_spawned_objects)
		end
	end

	debugLog("spawned " .. #spawned_objects .. "/" .. #object_descriptors .. " objects")

	return spawned_objects
end

function spawnObject(spawn_transform, location, object, parent_vehicle_id, spawned_objects, out_spawned_objects)
	-- spawn object

	local spawned_object_id = spawnObjectType(spawn_transform, location, object, parent_vehicle_id)

	-- add object to spawned object tables

	if spawned_object_id ~= nil and spawned_object_id ~= 0 then
		local object_data = { type = object.type, id = spawned_object_id, component_id = object.id }

		if spawned_objects ~= nil then
			table.insert(spawned_objects, object_data)
		end

		if out_spawned_objects ~= nil then
			table.insert(out_spawned_objects, object_data)
		end

		return object_data
	end

	return nil
end

-- spawn an individual object descriptor from a playlist location
function spawnObjectType(spawn_transform, location, object_descriptor, parent_vehicle_id)
	local component = server.spawnAddonComponent(matrix.multiply(spawn_transform, object_descriptor.transform), location.playlist_index, location.location_index, object_descriptor.index, parent_vehicle_id)
	return component.id
end

-- despawn all objects in the list
function despawnObjects(objects, is_force_despawn)
	if objects ~= nil then
		for _, object in pairs(objects) do
			despawnObject(object.type, object.id, is_force_despawn)
		end
	end
end

-- despawn a specific object by type and id.
-- if is_force_despawn is true, the object will be instantly removed, otherwise it will be removed when it despawns naturally
function despawnObject(type, id, is_force_despawn)
	if type == "vehicle" then
		server.despawnVehicle(id, is_force_despawn)
	elseif type == "character" then
		server.despawnObject(id, is_force_despawn)
	elseif type == "fire" then
		server.despawnObject(id, is_force_despawn)
	elseif type == "object" then
		server.despawnObject(id, is_force_despawn)
	elseif type == "animal" then
		server.despawnObject(id, is_force_despawn)
	end
end

-- returns a table of all spawned object data in objects that is matched by the callback function
function filterSpawnedObjects(objects, callback_filter)
	local filtered_objects = {}

	for k, obj in pairs(objects) do
		if callback_filter(obj) then
			table.insert(filtered_objects, obj)
		end
	end

	return filtered_objects
end

-- gets all mission zones for which the callback_filter function returns true.
-- callback_filter must be a function that takes a single parameter which is a table containing a list of zone tags to test against
function getMissionZones(callback_filter)
	debugLog("getting zones...")

	local zones = server.getZones(callback_filter)

	if zones == nil or tableLength(zones) == 0 then
		debugLog("ERROR failed to find matching zones")
		return nil
	end

	debugLog("found " .. tableLength(zones) .. " zones")
	return zones
end

-- checks if a position is contained with any zone in a list of zones returned by server.getZones
function isPosInZones(transform, zones)
	for k, v in pairs(zones) do
		if server.isInTransformArea(transform, v.transform, v.size.x, v.size.y, v.size.z) then
			return true
		end
	end

	return false
end

-- checks if a specific tag string appears in a table of tag strings
function hasTag(tags, tag)
	for k, v in pairs(tags) do
		if v == tag then
			return true
		end
	end

	return false
end

-- calculates the size of non-contiguous tables and tables that use non-integer keys
function tableLength(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end

-- recursively outputs the contents of a table to the chat window for debugging purposes.
-- name is the name that should be displayed for the root of the table being passed in.
-- m is an optional parameter used when the function recurses to specify a margin string that will be prepended before printing for readability
function printTable(table, name, m)
	local margin = m or ""

	if tableLength(table) == 0 then
		server.announce("", margin .. name .. " = {}")
	else
		server.announce("", margin .. name .. " = {")

		for k, v in pairs(table) do
			local vtype = type(v)

			if vtype == "table" then
				printTable(v, k, margin .. "    ")
			elseif vtype == "string" then
				server.announce("", margin .. "    " .. k .. " = \"" .. tostring(v) .. "\",")
			elseif vtype == "number" or vtype == "function" or vtype == "boolean" then
				server.announce("", margin .. "    " .. k .. " = " .. tostring(v) .. ",")
			else
				server.announce("", margin .. "    " .. k .. " = " .. tostring(v) .. " (" .. type(v) .. "),")
			end
		end

		server.announce("", margin .. "},")
	end
end

-- pushes a string into the global output log table.
-- the log is cleared when a new mission is spawned.
-- the log for the previously spawned mission can be displayed using the command ?log
function debugLog(message)
	table.insert(g_output_log, message)
end

-- outputs everything in the debug log to the chat window
function printLog()
	for i = 1, #g_output_log do
		server.announce("[Debug Log] " .. i, g_output_log[i])
	end
end

-- iterator function for iterating over all playlists, skipping any that return nil data
function iterPlaylists()
	local playlist_count = server.getAddonCount()
	local playlist_index = 0

	return function()
		local playlist_data = nil
		local index = playlist_count

		while playlist_data == nil and playlist_index < playlist_count do
			playlist_data = server.getAddonData(playlist_index)
			index = playlist_index
			playlist_index = playlist_index + 1
		end

		if playlist_data ~= nil then
			return index, playlist_data
		else
			return nil
		end
	end
end

-- iterator function for iterating over all locations in a playlist, skipping any that return nil data
function iterLocations(playlist_index)
	local playlist_data = server.getAddonData(playlist_index)
	local location_count = 0
	if playlist_data ~= nil then location_count = playlist_data.location_count end
	local location_index = 0

	return function()
		local location_data = nil
		local index = location_count

		while location_data == nil and location_index < location_count do
			location_data = server.getLocationData(playlist_index, location_index)
			index = location_index
			location_index = location_index + 1
		end

		if location_data ~= nil then
			return index, location_data
		else
			return nil
		end
	end
end

-- iterator function for iterating over all objects in a location, skipping any that return nil data
function iterObjects(playlist_index, location_index)
	local location_data = server.getLocationData(playlist_index, location_index)
	local object_count = 0
	if location_data ~= nil then object_count = location_data.component_count end
	local object_index = 0

	return function()
		local object_data = nil
		local index = object_count

		while object_data == nil and object_index < object_count do
			object_data = server.getLocationComponentData(playlist_index, location_index, object_index)
			object_data.index = object_index
			index = object_index
			object_index = object_index + 1
		end

		if object_data ~= nil then
			return index, object_data
		else
			return nil
		end
	end
end

function removeMissionMarkers(mission)
	for k, obj in pairs(mission.map_markers) do
		server.removeMapID(-1, obj.id)
	end
	mission.map_markers = {}
end