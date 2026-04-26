local S = minetest.get_translator(minetest.get_current_modname())

minetest.register_craftitem("techblox:magma_ingot", {
    description = S("Magma Ingot\nUsed to craft special Volcanic items and very useful as a fuel"),
    inventory_image = "techblox_magma_ingot.png",
    stack_max = 15,
    groups = {material = 1, fuel = 1},
})

-- Fuel registration: One ingot now powers a furnace for 100 seconds
minetest.register_craft({
    type = "fuel",
    recipe = "techblox:magma_ingot",
    burntime = 100,
})
