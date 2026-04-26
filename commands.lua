-- Register the custom privilege
minetest.register_privilege("tpx", {
    description = "Allows usage of the custom /tp command",
    give_to_singleplayer = true,
})

-- 1. Morning Toggle (CPU Efficient)
minetest.register_chatcommand("morning", {
    params = "[on/off]",
    description = "Freeze time at morning (6000)",
    privs = {settime = true},
    func = function(name, param)
        if param == "on" then
            minetest.set_timeofday(6000 / 24000)
            minetest.settings:set("time_speed", "0")
            minetest.chat_send_all("*** Morning Mode Enabled: Time is frozen at 6:00 AM ***")
            return true
        elseif param == "off" then
            minetest.settings:set("time_speed", "72") -- Default Minetest speed
            minetest.chat_send_all("*** Morning Mode Disabled: Time resumed ***")
            return true
        else
            return false, "Use /morning on or /morning off"
        end
    end,
})

-- 2. Teleport Command (Restricted to 'tpx' privs)
minetest.register_chatcommand("tp", {
    params = "<name> | <x> <y> <z>",
    description = "Teleport to a player or coordinates",
    privs = {tpx = true}, 
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Error: You are not online?" end

        -- Option A: TP to Player
        local target_player = minetest.get_player_by_name(param)
        if target_player then
            local ppos = target_player:get_pos()
            player:set_pos(ppos)
            return true, "Teleported to player: " .. param
        end

        -- Option B: TP to Coords (x y z)
        local x, y, z = param:match("^(%-?%d+%.?%d*)%s+(%-?%d+%.?%d*)%s+(%-?%d+%.?%d*)$")
        if x and y and z then
            local pos = {x = tonumber(x), y = tonumber(y), z = tonumber(z)}
            player:set_pos(pos)
            return true, "Teleported to " .. x .. ", " .. y .. ", " .. z
        end

        return false, "Invalid format. Use /tp <name> or /tp <x> <y> <z>"
    end,
})
-- techblox_custom/commands.lua
local S = minetest.get_translator(minetest.get_current_modname())

-})

-- Monitor player count for the pending refresh
minetest.register_globalstep(function(dtime)
    if refresh_active then
        local count = #minetest.get_connected_players()
        if count == 0 then
            minetest.request_shutdown("Scheduled Refresh", true)
        end
    end
end)

-- techblox_custom/commands.lua
local S = minetest.get_translator(minetest.get_current_modname())

-----------------------------------------------------------
-- 1. COMMAND: /refresh
-----------------------------------------------------------
local refresh_active = false

minetest.register_chatcommand("refresh", {
    privs = {server = true},
    description = S("Reboots the server safely once all players have disconnected."),
    func = function(name)
        if refresh_active then
            return false, S("Refresh protocol is already in progress.")
        end

        refresh_active = true
        
        -- Sending a clean notice to all players
        minetest.chat_send_all("*** SERVER NOTICE: A system refresh has been scheduled by an admin.")
        minetest.chat_send_all("*** The server will restart automatically once it is empty.")
        
        -- Check immediately in case the admin is the only one online
        local players = minetest.get_connected_players()
        if #players <= 1 then
            minetest.log("action", "[Techblox] Admin " .. name .. " triggered immediate refresh (Server empty).")
            minetest.request_shutdown("Server Refresh", true)
        end
        
        return true, S("Refresh scheduled. The server will shut down once all players leave.")
    end,
})

-- Globalstep to monitor player count and trigger the shutdown
minetest.register_globalstep(function(dtime)
    if refresh_active then
        local count = #minetest.get_connected_players()
        if count == 0 then
            minetest.log("action", "[Techblox] Executing scheduled refresh.")
            minetest.request_shutdown("Scheduled Refresh", true)
        end
    end
end)
