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
