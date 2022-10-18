function onCreate(is_world_create)
	if is_world_create then
		spawnAll()
	end
end

function spawnAll()
	local addonIndex = server.getAddonIndex()
	local arecibo_dish = {}
	local arecibo_tile = nil
	local is_tile_found = false

	for locationIndex = 0, server.getAddonData(addonIndex).location_count - 1 do
		local locationData = server.getLocationData(addonIndex, locationIndex)
		if not locationData.is_env_mod then
			for componentIndex = 0, locationData.component_count - 1 do
				local componentData = server.getLocationComponentData(addonIndex, locationIndex, componentIndex)
				for _, tag in pairs(componentData.tags) do
					if (tag == "anchor") then
						arecibo_dish[componentData.display_name] = componentData
						arecibo_tile, is_tile_found = server.getTileTransform(matrix.identity(), locationData.tile)
					end
				end
			end
		end
	end

	if is_tile_found then
		for _, c in pairs(arecibo_dish) do
			local v_id = server.spawnAddonVehicle(matrix.multiply(c.transform, arecibo_tile), addonIndex, c.id)
			c.v_id = v_id
			server.announce("arecibo", v_id)
		end

		local len_1 = 150
		local len_2 = len_1

		server.spawnVehicleRope(arecibo_dish["11"].v_id, 0, 1, 0, arecibo_dish["0"].v_id, -97, 0, -98, len_1, 3)
		server.spawnVehicleRope(arecibo_dish["12"].v_id, 0, 1, 0, arecibo_dish["0"].v_id, -97, 45, -98, len_2, 3)
		server.spawnVehicleRope(arecibo_dish["13"].v_id, 0, 1, 0, arecibo_dish["0"].v_id, -98, 45, -97, len_2, 3)
		server.spawnVehicleRope(arecibo_dish["14"].v_id, 0, 1, 0, arecibo_dish["0"].v_id, -98, 0, -97, len_1, 3)

		server.spawnVehicleRope(arecibo_dish["21"].v_id, 0, 1, 0, arecibo_dish["0"].v_id, -98, 0, 97, len_1, 3)
		server.spawnVehicleRope(arecibo_dish["22"].v_id, 0, 1, 0, arecibo_dish["0"].v_id, -98, 45, 97, len_2, 3)
		server.spawnVehicleRope(arecibo_dish["23"].v_id, 0, 1, 0, arecibo_dish["0"].v_id, -97, 45, 98, len_2, 3)
		server.spawnVehicleRope(arecibo_dish["24"].v_id, 0, 1, 0, arecibo_dish["0"].v_id, -97, 0, 98, len_1, 3)

		server.spawnVehicleRope(arecibo_dish["31"].v_id, 0, 1, 0, arecibo_dish["0"].v_id, 97, 0, 98, len_1, 3)
		server.spawnVehicleRope(arecibo_dish["32"].v_id, 0, 1, 0, arecibo_dish["0"].v_id, 97, 45, 98, len_2, 3)
		server.spawnVehicleRope(arecibo_dish["33"].v_id, 0, 1, 0, arecibo_dish["0"].v_id, 98, 45, 97, len_2, 3)
		server.spawnVehicleRope(arecibo_dish["34"].v_id, 0, 1, 0, arecibo_dish["0"].v_id, 98, 0, 97, len_1, 3)

		server.spawnVehicleRope(arecibo_dish["41"].v_id, 0, 1, 0, arecibo_dish["0"].v_id, 98, 0, -97, len_1, 3)
		server.spawnVehicleRope(arecibo_dish["42"].v_id, 0, 1, 0, arecibo_dish["0"].v_id, 98, 45, -97, len_2, 3)
		server.spawnVehicleRope(arecibo_dish["43"].v_id, 0, 1, 0, arecibo_dish["0"].v_id, 97, 45, -98, len_2, 3)
		server.spawnVehicleRope(arecibo_dish["44"].v_id, 0, 1, 0, arecibo_dish["0"].v_id, 97, 0, -98, len_1, 3)
	end
end

function onCustomCommand(full_message, user_peer_id, is_admin, is_auth, command, arg1, arg2, arg3, arg4)
	if command == "?gvd" and is_admin == true then
		local data, good = server.getVehicleData(arg1)
		if(good) then
			printTable(data, "v")
		else
			server.annonuce("failed", "v")
		end
	end
end

function tableLength(T)

	if(type(T) ~= 'table') then return 0 end

	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end

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