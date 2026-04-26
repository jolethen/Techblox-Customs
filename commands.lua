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

-----------------------------------------------------------
-- 1. RANKS CONFIGURATION
-----------------------------------------------------------
-- Customize this table to add new ranks. 
-- The rank name automatically becomes a privilege (e.g., rank_vip).
local ranks_config = {
    admin = {
        prefix = "[ADMIN]",
        color = "#ff4500",
        privs = {server = true, kick = true, ban = true, teleport = true, fly = true, privs = true, interact = true}
    },
    mod = {
        prefix = "[MOD]",
        color = "#55ff55",
        privs = {kick = true, ban = true, teleport = true, fly = true, interact = true}
    },
    vip = {
        prefix = "[VIP]",
        color = "#55ffff",
        privs = {fly = true, fast = true, interact = true}
    },
    player = {
        prefix = "[Player]",
        color = "#ffffff",
        privs = {interact = true, shout = true}
    }
}

-- Automatically register the rank names as privileges
for rank_name, _ in pairs(ranks_config) do
    minetest.register_privilege("rank_" .. rank_name, {
        description = "Techblox Rank: " .. rank_name,
        give_to_singleplayer = false,
    })
end

-----------------------------------------------------------
-- 2. COMMAND: /refresh
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
        minetest.chat_send_all("*** SERVER NOTICE: Admin " .. name .. " has scheduled a system refresh.")
        minetest.chat_send_all("*** The server will restart automatically once it is empty.")
        
        -- Check immediately in case admin is alone
        local players = minetest.get_connected_players()
        if #players <= 1 then
            minetest.log("action", "[Techblox] Admin " .. name .. " triggered immediate refresh.")
            minetest.request_shutdown("Server Refresh", true)
        end
        return true, S("Refresh scheduled. Waiting for players to leave...")
    end,
})

-- Monitor player count for the pending refresh
minetest.register_globalstep(function(dtime)
    if refresh_active then
        local count = #minetest.get_connected_players()
        if count == 0 then
            minetest.request_shutdown("Scheduled Refresh", true)
        end
    end
end)

-----------------------------------------------------------
-- 3. COMMAND: /rank
-----------------------------------------------------------
minetest.register_chatcommand("rank", {
    params = "<rank_name> <player_name>",
    description = S("Assign a rank and its associated privileges to a player."),
    privs = {privs = true},
    func = function(name, param)
        local rank_name, target_name = param:match("^(%S+)%s+(%S+)$")
        
        if not rank_name or not target_name then
            return false, S("Usage: /rank <rank_name> <player_name>")
        end

        local config = ranks_config[rank_name]
        if not config then
            return false, S("Error: Rank '" .. rank_name .. "' is not defined in commands.lua")
        end

        -- Handle both online and offline players
        local auth = minetest.get_auth_handler().get_auth(target_name)
        if not auth then
            return false, S("Error: Player '" .. target_name .. "' has never joined the server.")
        end

        -- Create new privs table (Clears old techblox rank privs first)
        local new_privs = auth.privileges
        
        -- Remove any existing 'rank_' privileges to prevent rank stacking
        for p, _ in pairs(new_privs) do
            if p:sub(1, 5) == "rank_" then
                new_privs[p] = nil
            end
        end

        -- Add new rank marker and its privileges
        new_privs["rank_" .. rank_name] = true
        for priv, val in pairs(config.privs) do
            new_privs[priv] = val
        end

        minetest.set_privileges(target_name, new_privs)
        
        -- Notify the admin
        minetest.log("action", "[Techblox] " .. name .. " set " .. target_name .. " rank to " .. rank_name)
        return true, S("Successfully promoted " .. target_name .. " to " .. rank_name:upper())
    end,
})

-----------------------------------------------------------
-- 4. CHAT PREFIX LOGIC
-----------------------------------------------------------
-- This makes the ranks actually visible in chat
minetest.register_on_chat_message(function(name, message)
    local player_privs = minetest.get_privileges(name)
    local final_prefix = ""
    
    -- Find which rank the player has
    for rank_name, data in pairs(ranks_config) do
        if player_privs["rank_" .. rank_name] then
            final_prefix = data.prefix .. " "
            break
        end
    end

    -- If player has no rank, use default
    if final_prefix == "" then final_prefix = ranks_config.player.prefix .. " " end

    minetest.chat_send_all(final_prefix .. "<" .. name .. "> " .. message)
    return true -- Block the default chat message to show our formatted one
end)
