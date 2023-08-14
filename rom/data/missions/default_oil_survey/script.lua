local g_data_cost_lower = 25000
local g_data_cost_upper = 80000

g_savedata = {
    deposits = {},
    vendors = {},
    cost = g_data_cost_lower
}

local tick_counter = 0

function onCreate(is_world_create)
    if is_world_create then
        spawnAll()

        local oil_deposits = server.getOilDeposits()

        for i, d in pairs(oil_deposits) do
            d.is_purchased = i <= 5
           table.insert(g_savedata.deposits, d)
        end
    end
end

function spawnAll()
	local addonIndex = server.getAddonIndex()
    local componentIDS = {}

	for locationIndex = 0, server.getAddonData(addonIndex).location_count - 1 do
		local locationData = server.getLocationData(addonIndex, locationIndex)
		if not locationData.is_env_mod then
			for componentIndex = 0, locationData.component_count - 1 do
				local componentData = server.getLocationComponentData(addonIndex, locationIndex, componentIndex)
				componentIDS[locationData.name] = {id = componentData.id, offset = componentData.transform}
			end
		end
	end

    for name, component in pairs(componentIDS) do
        local spawn_zones = server.getZones(name)
        for _, zone in pairs(spawn_zones) do
            local spawn_transform = matrix.multiply(zone.transform, component.offset)
            local vid, success = server.spawnAddonVehicle(spawn_transform, addonIndex, component.id)
            if success then
                if name == "oil_vendor" then
                    table.insert(g_savedata.vendors, vid)
                end
            end
        end
    end
end

function onTick()

    if tick_counter < 15 then
        tick_counter = tick_counter + 1
    else
        tick_counter = 0
        for _, id in pairs(g_savedata.vendors) do
            local d, success = server.getVehicleButton(id, "purchase")

            if success and d.on then
                server.pressVehicleButton(id, "reset")

                local inf_money = server.getGameSettings().infinite_money
                local c = server.getCurrency()
                if inf_money or c > g_savedata.cost then

                    local data_remaining = false
                    for _, d in pairs(g_savedata.deposits) do
                        if d.is_purchased == false then
                            data_remaining = true
                        end
                    end

                    if data_remaining == false then
                        server.notify(-1, "All Oil Data Purchased",  "", 0)
                        for _, vendor_id in pairs(g_savedata.vendors) do
                            server.setVehicleKeypad(vendor_id, "cost", 0)
                        end
                        return
                    end

                    if inf_money == false then
                        server.setCurrency(c - g_savedata.cost)
                    end
                    local new_deposit = purchase_data()
                    g_savedata.cost = math.random(g_data_cost_lower, g_data_cost_upper)

                    for _, vendor_id in pairs(g_savedata.vendors) do
                        server.setVehicleKeypad(vendor_id, "cost", g_savedata.cost)
                        server.setVehicleKeypad(vendor_id, "coords", new_deposit.x, new_deposit.z)
                    end
                else
                    server.notify(-1, "Insufficient Funds",  "Could not purchase oil data", 0)
                end

                return
            end
        end
    end
end

function onVehicleLoad(vid)
    for _, id in pairs(g_savedata.vendors) do
        if id == vid then
            server.setVehicleKeypad(vid, "cost", g_savedata.cost)
        end
    end
end

function purchase_data()
    for _, d in pairs(g_savedata.deposits) do
        if d.is_purchased == false then
            d.is_purchased = true
            server.notify(-1, "New Oil Data",  "X: "..math.floor(d.x).." Y: "..math.floor(d.z), 0)
            server.addMapLabel(-1, server.getMapID(), 6, "Oil Deposit", d.x, d.z)
            return d
        end
    end
    return nil
end

function onPlayerJoin(steamid, name, peerid, admin, auth)
    for _, d in pairs(g_savedata.deposits) do
        if d.is_purchased then
            server.addMapLabel(peerid, server.getMapID(), 6, "Oil Deposit", d.x, d.z)
        end
    end
    for _, v in pairs(g_savedata.vendors) do
        local pos = server.getVehiclePos(v)
        server.addMapLabel(peerid, server.getMapID(), 6, "Oil Data Vendor", pos[13], pos[15])
    end
end

function onCustomCommand(full_message, user_peer_id, is_admin, is_auth, command)
	if command == "?oil_deposit" and server.isDev() then
        purchase_data()
	end
end