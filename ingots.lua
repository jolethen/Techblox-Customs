local S = minetest.get_translator(minetest.get_current_modname())

minetest.register_craftitem("techblox:magma_ingot", {
    description = S("Magma Ingot\n" .. minetest.colorize("#ff4500", "Used to craft special Volcanic items and very useful as a fuel")),
    inventory_image = "techblox_magma_ingot.png",
    stack_max = 15,
    groups = {material = 1, fuel = 1},
})

-- If you want it to be usable as fuel (since it's literal lava)
minetest.register_craft_predict(function(itemstack, player, old_craft_grid, craft_inv)
    -- This makes it burn for a long time in a furnace
    minetest.register_craft({
        type = "fuel",
        recipe = "techblox:magma_ingot",
        burntime = 100, -- Burns much longer than coal
    })
end)
