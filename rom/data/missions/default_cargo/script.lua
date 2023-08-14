g_cargo_package_types = {}

g_cargo_terminals = {}

g_savedata = {}

g_loaded_vehicle_ids = {}

check_timer = 0

STATE_DEFAULT = 0
STATE_DELIVERED = 1
STATE_EXPIRED = 2

function onCreate(is_world_create)
	-- build data on cargo package types

	g_cargo_terminals = g_savedata

	-- find locations with tag "type=cargo_package"
	
	for playlist_index, playlist_object in iterPlaylists() do
		for location_index, location_object in iterLocations(playlist_index) do
			local is_cargo_package = false
			local cargo_type = ""
			local theme = "civilian"
			local probability = 0.5
			for _, object_data in iterObjects(playlist_index, location_index) do
				for tag_index, tag_object in pairs(object_data.tags) do
					if tag_object == "type=cargo_package" then
						is_cargo_package = true
					elseif string.find(tag_object, "cargo_type=") ~= nil then
						cargo_type = string.sub(tag_object, 12)
					elseif string.find(tag_object, "theme=") ~= nil then
						theme = string.sub(tag_object, 7)
					elseif string.find(tag_object, "probability=") ~= nil then
						probability = string.sub(tag_object, 13)
					end
				end
			end

			if is_cargo_package then
				-- create cargo package type

				local cargo_package_type_object = {
					playlist_index = playlist_index,
					location_index = location_index,
					cargo_type = cargo_type,
					theme = theme,
					probability = probability,
				}
				table.insert(g_cargo_package_types, cargo_package_type_object)
			end
		end
	end

	-- find zones with tag "type=cargo_terminal"
	if tableLength(g_cargo_terminals) == 0 then

		local zones = server.getZones()

		-- filter zones to only include mission zones

		for zone_index, zone_object in pairs(zones) do
			local is_cargo_terminal = false
			local produces = {}
			local consumes = {}
			for zone_tag_index, zone_tag_object in pairs(zone_object.tags) do
				if zone_tag_object == "type=cargo_terminal" then
					is_cargo_terminal = true
				elseif string.find(zone_tag_object, "produces=") ~= nil then
					table.insert(produces, string.sub(zone_tag_object, 10))
				elseif string.find(zone_tag_object, "consumes=") ~= nil then
					table.insert(consumes, string.sub(zone_tag_object, 10))
				end
			end

			if is_cargo_terminal then
				
				-- create cargo_terminal object
				local cargo_terminal_object = {
					transform = zone_object.transform,
					playlist_index = playlist_index,
					location_index = location_index,
					ui_id = server.getMapID(),
					name = zone_object.name,
					spawn_locations = {},
					delivery_zones = {},
					cargo_packages = {},
					produces = produces,
					consumes = consumes,
				}

				-- find nearby zones with tag "type=cargo_spawn_location"
				for other_zone_index, other_zone_object in pairs(zones) do
					local is_cargo_spawn_location = false
					for zone_tag_index, zone_tag_object in pairs(other_zone_object.tags) do
						if zone_tag_object == "type=cargo_spawn_location" then
							is_cargo_spawn_location = true
						end
					end

					if is_cargo_spawn_location then
						local terminal_to_spawn_distance = matrix.distance(zone_object.transform, other_zone_object.transform)

						if terminal_to_spawn_distance < 500 then
							local cargo_spawn_location = {
								transform = other_zone_object.transform,
								cargo_package_exists = false,
							}
							table.insert(cargo_terminal_object.spawn_locations, cargo_spawn_location)
						end
					end
				end

				-- find nearby zone with tag "type=cargo_delivery_zone"
				for other_zone_index, other_zone_object in pairs(zones) do
					local is_cargo_delivery_zone = false
					for zone_tag_index, zone_tag_object in pairs(other_zone_object.tags) do
						if zone_tag_object == "type=cargo_delivery_zone" then
							is_cargo_delivery_zone = true
						end
					end

					if is_cargo_delivery_zone then
						local terminal_to_spawn_distance = matrix.distance(zone_object.transform, other_zone_object.transform)

						if terminal_to_spawn_distance < 500 then
							local cargo_delivery_zone = {
								transform = other_zone_object.transform,
								size = other_zone_object.size,
							}
							table.insert(cargo_terminal_object.delivery_zones, cargo_delivery_zone)
						end
					end
				end

				-- create map ui
				buildMapUI(cargo_terminal_object, -1)

				table.insert(g_cargo_terminals, cargo_terminal_object)
			end
		end

		-- spawn initial cargo
		for cargo_terminal_index_new, cargo_terminal_object_new in pairs(g_cargo_terminals) do
			if #g_cargo_package_types > 0 then
				local cargo_to_spawn_count = math.random(math.ceil(#cargo_terminal_object_new.spawn_locations / 2), #cargo_terminal_object_new.spawn_locations)

				for i = 1, cargo_to_spawn_count do
					local cargo_package_object = spawnCargo(cargo_terminal_object_new)

					if cargo_package_object ~= nil then
						table.insert(cargo_terminal_object_new.cargo_packages, cargo_package_object)
					end
				end
			end
		end

	end
end

function onVehicleUnload(vehicle_id)
	g_loaded_vehicle_ids[vehicle_id] = nil
end

function onVehicleLoad(vehicle_id)
	g_loaded_vehicle_ids[vehicle_id] = true
end

function getCargoTerminalByName(terminal_name)
	for cargo_terminal_dest_index, cargo_terminal_dest_object in pairs(g_cargo_terminals) do
		if cargo_terminal_dest_object.name == terminal_name then
			return cargo_terminal_dest_object
		end
	end
	return nil
end

function onTick(delta_worldtime)

    check_timer = check_timer + 1
    if check_timer > 60 then
        check_timer = 0
    end

	for cargo_terminal_index, cargo_terminal_object in pairs(g_cargo_terminals) do
		for cargo_package_index, cargo_package_object in pairs(cargo_terminal_object.cargo_packages) do
			local is_expired = false

			if cargo_package_object.vehicle_id ~= nil then
				if g_loaded_vehicle_ids[cargo_package_object.vehicle_id] == true then
					local vehicle_tick_offset = math.fmod(cargo_package_object.vehicle_id, 60)
					if vehicle_tick_offset == check_timer then
						local cargo_vehicle_transform, success = server.getVehiclePos(cargo_package_object.vehicle_id)
						local cargo_terminal_dest = getCargoTerminalByName(cargo_package_object.destination)

						if cargo_terminal_dest ~= nil then
							for delivery_zone_index, delivery_zone_object in pairs(cargo_terminal_dest.delivery_zones) do
								if matrix.distance(cargo_vehicle_transform, delivery_zone_object.transform) < 200 then
									if server.isInTransformArea(cargo_vehicle_transform, delivery_zone_object.transform, delivery_zone_object.size.x, delivery_zone_object.size.y, delivery_zone_object.size.z) then
										server.notify(-1, "Cargo Delivered", "Cargo has been delivered for a reward of $"..cargo_package_object.reward..".", 4)
										server.setCurrency(server.getCurrency() + cargo_package_object.reward, server.getResearchPoints())
										cargo_package_object.state = STATE_DELIVERED
										is_expired = true
									end
								end
							end
						end

						if cargo_package_object.name == nil then cargo_package_object.name = "Misc" end
						local tooltip = "Cargo: "..cargo_package_object.name.."\nDestination: "..cargo_package_object.destination.."\nReward: $"..cargo_package_object.reward
						if cargo_package_object.state == STATE_EXPIRED then
							tooltip = tooltip.."\nPackage Expired"
						elseif cargo_package_object.state == STATE_DELIVERED then
							tooltip = tooltip.."\nPackage Delivered"
						else
							local time_remaining = cargo_package_object.life-cargo_package_object.timer

							if time_remaining < 60 then
								tooltip = tooltip.."\nTime Remaining: "..math.floor(time_remaining/60).."sec"
							else
								tooltip = tooltip.."\nTime Remaining: "..math.floor(time_remaining/3600).."min"
							end
						end
						server.setVehicleTooltip(cargo_package_object.vehicle_id, tooltip)
					end
				end

				if cargo_package_object.state == STATE_DEFAULT then
					cargo_package_object.timer = cargo_package_object.timer + delta_worldtime

					if cargo_package_object.timer > cargo_package_object.life then
						is_expired = true
						cargo_package_object.state = STATE_EXPIRED
						server.setVehicleTooltip(cargo_package_object.vehicle_id, "Package Expired")
					end
				end
			else
				is_expired = true
			end

			if is_expired then
				server.despawnVehicle(cargo_package_object.vehicle_id, false)

				local modified_location = nil
				for spawn_location_index_selected, spawn_location_object in pairs(cargo_terminal_object.spawn_locations) do
					if spawn_location_index_selected - cargo_package_object.spawn_location_index == 0 then
						modified_location = spawn_location_object
					end
				end

				modified_location.cargo_package_exists = false
				cargo_terminal_object.cargo_packages[cargo_package_index] = spawnCargo(cargo_terminal_object)
			end
		end
	end
end

function spawnCargo(cargo_terminal)
	local valid_spawn_locations = {}

	for spawn_location_index, spawn_location_object in pairs(cargo_terminal.spawn_locations) do
		if spawn_location_object.cargo_package_exists == false and server.isLocationClear(spawn_location_object.transform, 5, 7, 7) then -- check location is clear
			table.insert(valid_spawn_locations, spawn_location_object)
		end
	end

	if #valid_spawn_locations > 0 then

		local selected_spawn_location_index = 0
		local selected_spawn_location = valid_spawn_locations[math.random(1, #valid_spawn_locations)]

		for spawn_location_index, spawn_location_object in pairs(cargo_terminal.spawn_locations) do
			if spawn_location_object == selected_spawn_location then 
				selected_spawn_location_index = spawn_location_index
			end
		end

		local valid_cargo_package_types = {}

		for cargo_package_type_index, cargo_package_type_object in pairs(g_cargo_package_types) do
			local is_type_match = false
			for produce_type_index, produce_type_object in pairs(cargo_terminal.produces) do
				if produce_type_object == cargo_package_type_object.cargo_type then
					is_type_match = true -- cargo type must be a type produced by this terminal
				end
			end

			if is_type_match then
				table.insert(valid_cargo_package_types, cargo_package_type_object)
			end
		end

		if #valid_cargo_package_types > 0 then
			local prob_total = 0
			for _, package in pairs(valid_cargo_package_types) do
				prob_total = prob_total + package.probability
			end

			local selected_cargo_package = nil
			local random_cargo_package_prob = math.random() * prob_total

			local concurrent_prob = 0
			for _, package in pairs(valid_cargo_package_types) do
				concurrent_prob = concurrent_prob + package.probability

				if random_cargo_package_prob <= concurrent_prob then
					selected_cargo_package = package
					break
				end
			end

			local valid_destination_cargo_terminals = {}

			for cargo_terminal_index, cargo_terminal_object in pairs(g_cargo_terminals) do
				if cargo_terminal_object ~= cargo_terminal then
					local is_type_match = false
					for consume_type_index, consume_type_object in pairs(cargo_terminal_object.consumes) do
						if consume_type_object == selected_cargo_package.cargo_type then
							is_type_match = true -- destination must consume this cargo type
						end
					end

					if is_type_match then
						table.insert(valid_destination_cargo_terminals, cargo_terminal_object)
					end
				end
			end

			if #valid_destination_cargo_terminals > 0 then
				local selected_destination_cargo_terminal = valid_destination_cargo_terminals[math.random(1, #valid_destination_cargo_terminals)]

				-- calculate reward
				local transport_distance = matrix.distance(cargo_terminal.transform, selected_destination_cargo_terminal.transform)
				local reward_value = math.ceil((transport_distance / 10) * (math.random(10, 40) / 10) / 1000) * 1000 * math.ceil(selected_cargo_package.probability / 1.0)

				-- spawn cargo package
				local cargo_package_object = {
					type = selected_cargo_package,
					vehicle_id = nil,
					destination = selected_destination_cargo_terminal.name,
					reward = reward_value,
					timer = 0,
					life = (60 * 60 * math.random(60, 300)) + (transport_distance * 2),
					spawn_location_index = selected_spawn_location_index,
					state = STATE_DEFAULT,
					name = "Greetings Cards"
				}

				selected_spawn_location.cargo_package_exists = true

				-- create location vehicle
				for _, object_data in iterObjects(cargo_package_object.type.playlist_index, cargo_package_object.type.location_index) do
					if object_data.type == "vehicle" then
						if cargo_package_object.vehicle_id == nil then
							local spawn_transform = matrix.multiply(selected_spawn_location.transform, object_data.transform)

							local component = server.spawnAddonComponent(spawn_transform,  cargo_package_object.type.playlist_index, cargo_package_object.type.location_index, object_data.index, -1)
							cargo_package_object.vehicle_id = component.id
							cargo_package_object.name = component.display_name
						end
					end
				end

				if cargo_package_object.vehicle_id ~= nil then
					return cargo_package_object;
				end
			end
		end
	end
end

function buildMapUI(cargo_terminal, peer_id)
	server.removeMapID(-1, cargo_terminal.ui_id)
end

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